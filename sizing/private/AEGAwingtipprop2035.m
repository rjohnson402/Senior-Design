function z = AEGAwingtipprop2035(m,W,S,b,base_drag_area,opt,f,layout)
% NASA PEGASUS-inspired rotating actuator disks + classical lifting line.
% This is a reduced-order implementation, NOT the full Delft BEM/VLM model.
% Imperial inputs: lbf, ft, slug/ft^3; shaft power outputs in kW.
% Preserve the supplied polar by ADDING the powered-minus-unpowered LL drag.
% Solve equal wing lift and total propeller thrust = total aircraft drag.
cfg=m.wingtip_prop;
validateattributes(cfg.design_J,{'numeric'},{'scalar','finite','positive'});
validateattributes(cfg.rotation,{'numeric'},{'scalar','finite'});
assert(abs(cfg.rotation)==1,'AEGAwingtipprop2035:rotation','Rotation must be +1 or -1.');
validateattributes(cfg.hub_radius_fraction,{'numeric'},{'scalar','>',0,'<',1});
validateattributes(cfg.x_over_D,{'numeric'},{'scalar','finite','nonnegative'});
validateattributes(cfg.lift_curve_slope,{'numeric'},{'scalar','finite','positive'});
validateattributes(cfg.panels,{'numeric'},{'scalar','integer','>=',16,'<=',256});
validateattributes(cfg.max_tip_mach,{'numeric'},{'scalar','finite','positive'});
idx=opt.cruise_disk_indices;
if isempty(idx), idx=1:m.NPROP; end
validateattributes(idx,{'numeric'},{'vector','integer','positive','<=',m.NPROP});
assert(numel(unique(idx))==numel(idx),'AEGAwingtipprop2035:indices','Repeated active motor.');
D=[layout.D_side layout.D_side]; hubs=[-layout.y_side layout.y_side];
D=D(idx); hubs=hubs(idx); A=pi*(D/2).^2; share=A/sum(A);
V=m.Vkt*1.688; rho=m.rho_cr; q=.5*rho*V^2;
semi=b/2; core=semi*(1-opt.retract_fraction);
visible=core+semi*opt.retract_fraction*f; span=2*visible;
cr=2*S/(b*(1+m.TR)); ct=cr*m.TR; slope=(ct-cr)/semi;
area=S*(1-(2*m.TR*opt.retract_fraction+(1-m.TR)*opt.retract_fraction^2)/(1+m.TR) ...
    +(2*m.TR*opt.retract_fraction*f+(1-m.TR)*opt.retract_fraction^2*f^2)/(1+m.TR));
friction=opt.CD0_scale*m.Cf_w*m.FF_w*m.WETR*m.excr;
if isfield(m,'drag_buildup_scale'), friction=friction*m.drag_buildup_scale; end
if isfield(m,'resolved_wing_drag_per_planform')
    friction=opt.CD0_scale*m.resolved_wing_drag_per_planform;
end
joint=opt.joint_drag_area_ft2*double(opt.retract_fraction>0);
if isfield(opt,'joint_seal') && ~isempty(opt.joint_seal)
    jd=AEGAtelescopingjointdrag(m,S,b,opt.retract_fraction,f,opt.joint_seal); joint=jd.total_ft2;
end
parasite_area=base_drag_area-friction*(S-area)+joint;
baseline_induced=W^2/(q*pi*m.e_osw*span^2); baseline_drag=q*parasite_area+baseline_induced;
reference=m.Vkt;
if ~isempty(cfg.reference_speed_ktas), reference=cfg.reference_speed_ktas; end
if isempty(cfg.rpm)
    rpm=60*reference*1.688./(cfg.design_J*D);
elseif isscalar(cfg.rpm), rpm=repmat(cfg.rpm,size(D));
else
    assert(numel(cfg.rpm)==m.NPROP,'AEGAwingtipprop2035:rpm','RPM must be scalar or one per motor.');
    rpm=cfg.rpm(idx);
end
rpm=rpm(:).'; validateattributes(rpm,{'numeric'},{'finite','positive'});
omega=2*pi*rpm/60;
sound=sqrt(1.4*1716.59*max(389.97,518.67-.00356616*m.h_cr));
tip_mach=sqrt(V^2+(omega.*D/2).^2)/sound;
assert(all(tip_mach<=cfg.max_tip_mach),'AEGAwingtipprop2035:tipMach', ...
    'Helical tip Mach exceeds the configured model limit.');
% Midpoint theta quadrature; all Fourier modes allow asymmetric active disks.
N=cfg.panels; theta=((1:N)'-.5)*pi/N; modes=1:N;
sn=sin(theta*modes); y=visible*cos(theta); dy=visible*sin(theta)*pi/N;
c=cr+slope*abs(y); outer=abs(y)>core;
c(outer)=ct-slope*(visible-abs(y(outer)));
gamma_matrix=2*span*V*sn;
downwash_matrix=V*(sn.*modes)./sin(theta);
clean=wing(V*ones(N,1),zeros(N,1));
% Tight root tolerance keeps force balance independent of weight convergence.
fun=@(T) residual(T);
upper=2*baseline_drag;
for k=1:12
    if fun(upper)>0, break; end
    upper=2*upper;
end
assert(fun(upper)>0,'AEGAwingtipprop2035:thrustBracket','Cannot bracket cruise thrust.');
[T,~,flag]=fzero(fun,[0 upper],optimset('Display','off','TolX',1e-8));
assert(flag>0,'AEGAwingtipprop2035:convergence','Cruise thrust balance did not converge.');
[~,z]=residual(T);
z.enabled=true; z.model='rotating-disk-lifting-line';
z.baseline_drag_lb=baseline_drag; z.baseline_induced_drag_lb=baseline_induced;
z.induced_drag_lb=baseline_induced+z.delta_vortex_drag_lb+z.swirl_drag_lb;
z.parasite_drag_lb=q*parasite_area+z.scrubbing_drag_lb;
z.induced_reduction_fraction=1-z.induced_drag_lb/baseline_induced;
z.CDi=z.induced_drag_lb/(q*area);
z.e_effective=NaN;
if z.CDi>0, z.e_effective=(W/(q*area))^2/(pi*(span^2/area)*z.CDi); end
z.force_balance_residual_lb=T-z.drag_lb;
[~,unpowered]=residual(0); z.zero_thrust_drag_lb=unpowered.drag_lb;
z.active_indices=idx; z.rpm=rpm; z.advance_ratio=V./((rpm/60).*D);
z.tip_mach=tip_mach; z.hub_y_ft=hubs; z.diameter_ft=D;
z.hub_semispan_fraction=abs(hubs)/visible;
z.eta_prop=T*V/(z.shaft_kW*737.56);
z.spanwise=struct('y_ft',y,'chord_ft',c,'lift_lb_ft',z.lift_lb_ft, ...
    'axial_fps',z.axial_fps,'upwash_fps',z.upwash_fps);
z=rmfield(z,{'lift_lb_ft','axial_fps','upwash_fps'});
assert(z.drag_lb>0 && z.eta_prop>0 && z.eta_prop<=m.prof*(1+1e-8), ...
    'AEGAwingtipprop2035:domain','Solution outside positive-thrust model domain.');
    function [res,out]=residual(totalT)
        thrust=totalT*share;
        vi=thrust./(rho*A.*(sqrt(V^2+2*thrust./(rho*A))+V));
        Uw=V+2*vi; Aw=A.*(V+vi)./Uw; Rw=sqrt(Aw/pi);
        inertia=pi/2*Rw.^4*(1-cfg.hub_radius_fraction^4);
        axial=thrust.*(V+vi);
        % P*prof = T*(V+vi) + Q^2/(2*rho*Uw*I), Q=P/omega.
        % Stable lower root: swirl consumes power before recovery at the wing.
        coefficient=1./(2*rho*Uw.*inertia.*omega.^2);
        discriminant=m.prof^2-4*coefficient.*axial;
        assert(all(discriminant>0),'AEGAwingtipprop2035:loading', ...
            'RPM/disk loading has no positive rotating-disk power solution.');
        power=2*axial./(m.prof+sqrt(discriminant));
        torque=power./omega; swirl_power=coefficient.*power.^2;
        ramp=.5*(1+cfg.x_over_D*D./sqrt((cfg.x_over_D*D).^2+(D/2).^2));
        Udisk=V+2*ramp.*vi; R=sqrt(A.*(V+vi)./(Udisk*pi));
        angular=torque./(rho*Uw.*inertia);
        U=V*ones(N,1); up=zeros(N,1);
        for j=1:numel(D)
            offset=y-hubs(j); inside=abs(offset)<R(j);
            annulus=inside & abs(offset)>=cfg.hub_radius_fraction*R(j);
            % Uniform axial disk, minimum-energy solid-body swirl closure.
            U(inside)=U(inside)+Udisk(j)-V;
            up(annulus)=up(annulus)-cfg.rotation*sign(hubs(j))* ...
                ramp(j)*angular(j)*(Rw(j)/R(j))^2*offset(annulus);
        end
        powered=wing(U,up);
        delta_vortex=powered.vortex-clean.vortex;
        scrub=.5*rho*friction*sum(dy.*c.*(U.^2-V^2));
        drag=baseline_drag+delta_vortex+powered.swirl+scrub;
        res=totalT-drag;
        out=struct('drag_lb',drag,'thrust_lb',totalT,'shaft_kW',sum(power)/737.56, ...
            'shaft_each_kW',power/737.56,'axial_shaft_each_kW',axial/(m.prof*737.56), ...
            'torque_lbft',torque,'swirl_power_kW',sum(swirl_power)/737.56, ...
            'axial_power_kW',sum(axial)/737.56, ...
            'power_balance_residual_kW',(m.prof*sum(power)-sum(axial)-sum(swirl_power))/737.56, ...
            'delta_vortex_drag_lb',delta_vortex,'swirl_drag_lb',powered.swirl, ...
            'scrubbing_drag_lb',scrub,'lift_balance_residual_lb',powered.lift-W, ...
            'lift_lb_ft',rho*U.*powered.gamma,'axial_fps',U,'upwash_fps',up);
    end
    function state=wing(U,up)
        matrix=gamma_matrix./(.5*cfg.lift_curve_slope*c.*U)+downwash_matrix./U;
        liftrow=sum((rho*U.*dy).*gamma_matrix,1);
        solved=[matrix -ones(N,1); liftrow/W 0]\[up./U; 1];
        gamma=gamma_matrix*solved(1:N); down=downwash_matrix*solved(1:N);
        state=struct('gamma',gamma,'lift',sum(rho*U.*gamma.*dy), ...
            'vortex',sum(rho*gamma.*down.*dy),'swirl',-sum(rho*gamma.*up.*dy));
    end
end
