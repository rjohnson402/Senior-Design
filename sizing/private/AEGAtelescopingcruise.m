function g = AEGAtelescopingcruise(msn,DG,S,b,base_drag_area,opt)
% Cruise geometry/drag for ONE fixed aircraft; only speed/deployment change.
r = opt.retract_fraction;
base_ratio = 1-(2*msn.TR*r+(1-msn.TR)*r^2)/(1+msn.TR);
area = @(f) S*(base_ratio+(2*msn.TR*r*f+(1-msn.TR)*r^2*f^2)/(1+msn.TR));
span = @(f) b*(1-r+r*f);
q = .5*msn.rho_cr*(msn.Vkt*1.688)^2;
wing_friction = opt.CD0_scale*msn.Cf_w*msn.FF_w*msn.WETR*msn.excr;
if isfield(msn,'drag_buildup_scale'), wing_friction=wing_friction*msn.drag_buildup_scale; end
if isfield(msn,'resolved_wing_drag_per_planform')
    wing_friction=opt.CD0_scale*msn.resolved_wing_drag_per_planform;
end
if isfield(opt,'joint_seal') && ~isempty(opt.joint_seal)
    joint = @(f) joint_area(msn,S,b,r,f,opt.joint_seal);
else
    joint = @(f) double(r>0)*opt.joint_drag_area_ft2;
end
parasite = @(f) base_drag_area-wing_friction*(S-area(f))+joint(f);
drag = @(f) q*parasite(f)+DG^2/(q*pi*msn.e_osw*span(f)^2);
enabled=isfield(msn,'wingtip_prop') && msn.wingtip_prop.enabled;
objective=drag;
if enabled
    [~,~,~,~,layout]=AEGAtrade_prop(msn,S);
    % During stroke-capability search the cruise hub moves with the candidate
    % core end; at every deployment it then stays on that physical core.
    if isfield(opt,'retraction_policy') && strcmp(opt.retraction_policy,'lift-drag')
        layout.y_side(end)=b*(1-r)/2;
    end
    drag=@powered_drag;
    objective=@powered_power;
end
CL_limit = msn.CLmax_clean;
if isfield(opt,'cruise_CL_limit'), CL_limit = opt.cruise_CL_limit; end
required_area = DG/(q*CL_limit);
if r==0
    deployed = 1;
    if isnumeric(opt.cruise_deployment), deployed = opt.cruise_deployment; end
elseif isnumeric(opt.cruise_deployment)
    deployed = opt.cruise_deployment;
else
    lower = 0;
    if required_area > area(0) && required_area < S
        lower = fzero(@(f) area(f)-required_area,[0 1]);
    elseif required_area >= S
        lower = 1;
    end
    if lower < 1
        f = fminbnd(objective,lower,1,optimset('TolX',1e-7,'Display','off'));
    else
        f = 1;
    end
    candidates = [lower f 1];
    [~,k] = min(arrayfun(objective,candidates));
    deployed = candidates(k);
end
g = struct('area',area(deployed),'span',span(deployed), ...
    'AR',span(deployed)^2/area(deployed),'deployment',deployed, ...
    'drag',drag(deployed),'retracted_area',area(0),'retracted_span',span(0), ...
    'retracted_AR',span(0)^2/area(0),'stroke_each_ft',r*b/2, ...
    'exposed_stroke_each_ft',deployed*r*b/2,'CD0',parasite(deployed)/area(deployed), ...
    'joint_drag_area_ft2',joint(deployed),'CL',DG/(q*area(deployed)), ...
    'minimum_lift_area_ft2',required_area,'parasite_drag_lb',q*parasite(deployed), ...
    'induced_drag_lb',DG^2/(q*pi*msn.e_osw*span(deployed)^2), ...
    'full_span_drag_lb',drag(1),'drag_change_percent',100*(drag(deployed)/drag(1)-1), ...
    'actual_retraction_fraction',r*(1-deployed));
assert(g.retracted_area > msn.SCOV,'AEGAsize:retractedArea', ...
    'Retracted wing area must exceed the buried wing area.');
g.wingtip_prop=struct('enabled',false,'model','legacy-axial-disk');
g.optimization_metric='drag';
if enabled
    z=AEGAwingtipprop2035(msn,DG,S,b,base_drag_area,opt,deployed,layout);
    g.wingtip_prop=z;
    g.induced_drag_lb=z.induced_drag_lb;
    g.parasite_drag_lb=z.parasite_drag_lb;
    g.optimization_metric='shaft power';
    % CD0 remains the unblown geometry drag area; scrub is reported separately.
end
    function D=powered_drag(fraction)
        z=AEGAwingtipprop2035(msn,DG,S,b,base_drag_area,opt,fraction,layout); D=z.drag_lb;
    end
    function P=powered_power(fraction)
        z=AEGAwingtipprop2035(msn,DG,S,b,base_drag_area,opt,fraction,layout); P=z.shaft_kW;
    end
end
function a = joint_area(msn,S,b,r,f,seal)
d = AEGAtelescopingjointdrag(msn,S,b,r,f,seal); a = d.total_ft2;
end
