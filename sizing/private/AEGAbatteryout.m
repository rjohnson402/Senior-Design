function result = AEGAbatteryout(msn,ref,opt)
%AEGABATTERYOUT Four isolated battery banks, each feeding a mirrored pair.
% ref requires MTOW, SW, CD0. Motor order: [L1 L2 L3 L4 R1 R2 R3 R4].
% P/W is TOTAL installed shaft rating including failed motors. No crossfeed,
% overload, or remaining-energy guarantee. Instantaneous steady-state screen.
if nargin < 3, opt = struct(); end
d = struct('VS_kt',msn.VS0,'approach_factor',1.3, ...
    'approach_deg',msn.approach_angle,'rating_mode','disk-area', ...
    'profile_eff',msn.prof,'failed_disk_CD',0,'WS_margin',0.98, ...
    'power_margin',1.02,'max_hp_lb',0.60,'include_climb',true, ...
    'selected_climb_gradient',0.02,'climb_speed_kt',1.3*msn.VS0, ...
    'takeoff_dCD',0.03);
names = fieldnames(d);
for i = 1:numel(names)
    if ~isfield(opt,names{i}), opt.(names{i}) = d.(names{i}); end
end
assert(msn.NPROP == 8,'AEGAbatteryout:count','This study requires eight motors.');
validateattributes(ref.MTOW,{'numeric'},{'scalar','positive','finite'});
validateattributes(ref.SW,{'numeric'},{'scalar','positive','finite'});
validateattributes(ref.CD0,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(opt.VS_kt,{'numeric'},{'scalar','positive','finite'});
validateattributes(opt.climb_speed_kt,{'numeric'},{'scalar','positive','finite'});
validateattributes(opt.selected_climb_gradient,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(opt.failed_disk_CD,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(opt.takeoff_dCD,{'numeric'},{'scalar','nonnegative','finite'});
assert(opt.WS_margin > 0 && opt.WS_margin <= 1);
assert(opt.power_margin >= 1 && opt.max_hp_lb > 0);
assert(opt.approach_factor >= 1 && opt.approach_deg > 0 && opt.approach_deg < 90);
assert(opt.profile_eff > 0 && opt.profile_eff <= 1);
assert(any(strcmp(opt.rating_mode,{'disk-area','equal'})));

DG = ref.MTOW; S = ref.SW;
g = geometry(msn,S,opt);
pairs = AEGAbatterypairs2035(msn);
alive = true(5,8);
for i = 1:4, alive(i+1,pairs(i,:)) = false; end
% Columns are independently meaningful sizing bounds. All include the same
% installed-rating margin; approach lift is checked at actual approach throttle.
bounds = zeros(5,4);
appOK = false(5,1);
appThrustOK = false(5,1);
appCL = nan(5,1);
for k = 1:5
    a = alive(k,:);
    q = 0.5*msn.rho_SL*(opt.VS_kt*1.688)^2;
    CLreq = DG/(S*q*opt.WS_margin);
    bounds(k,1) = opt.power_margin*lower_root( ...
        @(p) lift_margin(p,a,g,msn,DG,opt,CLreq),opt.max_hp_lb);
    V = opt.approach_factor*opt.VS_kt*1.688;
    q = 0.5*msn.rho_SL*V^2;
    CLreq = DG*cosd(opt.approach_deg)/(q*S);
    D = q*S*(ref.CD0+g.dCDflap+CLreq^2/(pi*msn.AR*msn.e_osw)) ...
        + q*opt.failed_disk_CD*sum(g.A(~a));
    Treq = D-DG*sind(opt.approach_deg);
    if Treq >= 0
        papp = thrust_required_power(a,g,msn,DG,opt,V,Treq);
        bounds(k,2) = opt.power_margin*papp;
        appThrustOK(k) = isfinite(papp);
        if appThrustOK(k)
            state = flow(papp,a,g,msn,DG,opt,V);
            appCL(k) = state.CL;
            appOK(k) = state.CL >= CLreq/opt.WS_margin-1e-9;
        end
    else
        % This model has neither a drag-device schedule nor negative thrust.
        bounds(k,2) = Inf;
    end
    if opt.include_climb
        for cfg = 1:2
            bounds(k,2+cfg) = climb_required(a,g,msn,DG,ref.CD0, ...
                opt,opt.selected_climb_gradient,cfg);
        end
    end
end
[required,driver] = max(bounds,[],2);
required(~appOK) = Inf;
[worst,iw] = max(required(2:5));
labels = {'60 kt lift','approach thrust','takeoff climb','landing-flap go-around'};
result.options = opt;
result.pairs = pairs;
result.alive = alive;
result.bounds_hp_lb = bounds;
result.bound_names = labels;
result.required_hp_lb = required;
result.required_kW = required*DG*0.745699872;
result.all_operating_hp_lb = required(1);
result.worst_battery_hp_lb = worst;
result.worst_battery = iw;
result.worst_pair = pairs(iw,:);
result.worst_driver = labels{driver(iw+1)};
result.approach_lift_ok = appOK;
result.approach_thrust_solved = appThrustOK;
result.approach_CL_available = appCL;
result.retained_power_fraction = alive*g.share(:);
result.D_side = g.D(1:4);
result.y_side = g.y(5:8);
result.rating_share = g.share;
result.CLbase = g.CLbase;
result.dCDflap = g.dCDflap;
result.status = repmat({'ok'},5,1);
for k = 1:5
    if ~appThrustOK(k)
        result.status{k} = 'approach thrust unavailable within model/search ceiling';
    elseif ~appOK(k)
        result.status{k} = 'approach lift insufficient at descent throttle';
    elseif ~isfinite(required(k))
        result.status{k} = 'lift cap or power search ceiling exceeded';
    end
end
end

function g = geometry(msn,S,opt)
[~,~,~,b,layout] = AEGAtrade_prop(msn,S);
g.S = S; g.b = b; g.semi = b/2;
g.D = [layout.D_side layout.D_side];
g.y = [-layout.y_side layout.y_side];
g.A = pi*(g.D/2).^2;
g.cr = 2*S/(b*(1+msn.TR)); g.ct = msn.TR*g.cr;
g.yroot = msn.WFus/2;
frac = 0.8;
if isfield(msn,'flap_span_frac'), frac = msn.flap_span_frac; end
g.yflap = min(frac*g.semi,g.semi);
g.dcl = msn.dclmax_flap_L*msn.K_flap_sweep;
Af = area_integral(g.yroot,g.yflap,g);
g.CLbase = msn.CLmax_clean+g.dcl*2*Af/S;
g.dCDflap = msn.CD_flap_factor*msn.flap_chord_frac*2*Af/S*sind(msn.flap_def_L)^2;
if strcmp(opt.rating_mode,'disk-area')
    g.share = g.A/sum(g.A);
else
    g.share = ones(1,8)/8;
end
end

function s = flow(pw,alive,g,msn,DG,opt,V)
% Independent actuator disks at fixed shaft ratings; no transfer of failed
% motor power. Newton solves the same monotone actuator-disk cubic.
% Start above the positive root; convexity gives monotone convergence.
Pair = opt.profile_eff*(pw*DG*550)*g.share.*alive;
Q = Pair./(2*msn.rho_SL*g.A);
vi = min(Q/V^2,nthroot(Q,3));
for it = 1:32
    next = max(0,vi-(vi.*(V+vi).^2-Q)./((V+vi).*(V+3*vi)));
    done = max(abs(next-vi)) <= 1e-11*(1+max(next));
    vi = next;
    if done, break; end
end
T = 2*msn.rho_SL*g.A.*vi.*(V+vi);
ue = V+2*vi;
ratio = (ue/V).^2;
width = g.D.*sqrt((V+ue)./(2*ue));
y1 = max(abs(g.y)-width/2,g.yroot);
y2 = min(abs(g.y)+width/2,g.semi);
A = area_integral(y1,y2,g);
Af = area_integral(max(y1,g.yroot),min(y2,g.yflap),g);
increment = (msn.CLmax_clean*A+g.dcl*Af).*(ratio-1);
uncapped = g.CLbase+sum(increment)/g.S;
s.CL = min(uncapped,msn.CLmax_cap);
s.CL_uncapped = uncapped;
s.T = sum(T);
s.T_each = T;
% Integral of y*c(y) for available-lift asymmetry, not a trim solution.
J = moment_integral(y1,y2,g);
Jf = moment_integral(max(y1,g.yroot),min(y2,g.yflap),g);
q = 0.5*msn.rho_SL*V^2;
s.capacity_roll_ftlb = q*sum(sign(g.y).*(msn.CLmax_clean*J+g.dcl*Jf).*(ratio-1));
Dfailed = q*opt.failed_disk_CD*g.A.*(~alive);
s.yaw_ftlb = sum(g.y.*(T-Dfailed));
s.thrust_moment_norm = sum(abs(g.y).*T)/max(s.T*g.semi,eps);
end

function v = lift_margin(pw,a,g,msn,DG,opt,CLreq)
s = flow(pw,a,g,msn,DG,opt,opt.VS_kt*1.688);
v = s.CL-CLreq;
end

function v = thrust_margin(pw,a,g,msn,DG,opt,V,Treq)
s = flow(pw,a,g,msn,DG,opt,V);
v = s.T-Treq;
end

function p = lower_root(fun,ceiling)
if fun(0) >= 0, p = 0; return; end
if fun(ceiling) < 0, p = Inf; return; end
lo = 0; hi = ceiling;
for j = 1:36
    mid = (lo+hi)/2;
    if fun(mid) >= 0, hi = mid; else, lo = mid; end
end
p = hi;
end

function A = area_integral(a,b,g)
b = max(a,b);
slope = (g.ct-g.cr)/g.semi;
A = g.cr*(b-a)+0.5*slope*(b.^2-a.^2);
end

function J = moment_integral(a,b,g)
b = max(a,b);
slope = (g.ct-g.cr)/g.semi;
J = 0.5*g.cr*(b.^2-a.^2)+slope/3*(b.^3-a.^3);
end


function p = climb_required(alive,g,msn,DG,CD0,opt,gradient,cfg)
% Quasi-steady minimum-gradient screen; no assumed flap retraction.
% Use full available survivor rating for lift/thrust inequalities.
% Extra thrust from satisfying the lift bound is allowed (gradient >= target).
gc = g; mc = msn;
if cfg == 1
    % Match existing takeoff model: uniform unblown takeoff CLmax.
    mc.CLmax_clean = msn.CLmax_TO;
    gc.CLbase = msn.CLmax_TO;
    gc.dcl = 0;
    gc.dCDflap = opt.takeoff_dCD;
end
V = opt.climb_speed_kt*1.688;
q = 0.5*msn.rho_SL*V^2;
gamma = atan(gradient);
CLreq = DG*cos(gamma)/(q*g.S);
Dfailed = q*opt.failed_disk_CD*sum(g.A(~alive));
D = q*g.S*(CD0+gc.dCDflap+CLreq^2/(pi*msn.AR*msn.e_osw))+Dfailed;
Treq = D+DG*sin(gamma);
% Find the thrust requirement directly when ratings scale with disk area.
% Most 78 kt cases have enough unblown lift, so no lift search is needed.
pt = thrust_required_power(alive,gc,mc,DG,opt,V,Treq);
if ~isfinite(pt)
    p = Inf;
    return
end
CLneeded = CLreq/opt.WS_margin;
if min(gc.CLbase,msn.CLmax_cap) >= CLneeded
    p = opt.power_margin*pt;
    return
end
state = flow(pt,alive,gc,mc,DG,opt,V);
if state.CL >= CLneeded
    p = opt.power_margin*pt;
else
    fun = @(pw) climb_margin(pw,alive,gc,mc,DG,opt,V,Treq,CLreq);
    p = opt.power_margin*lower_root(fun,opt.max_hp_lb);
end
end

function v = climb_margin(pw,alive,g,msn,DG,opt,V,Treq,CLreq)
s = flow(pw,alive,g,msn,DG,opt,V);
v = min((s.T-Treq)/DG,(s.CL-CLreq/opt.WS_margin)/max(CLreq,eps));
end


function p = thrust_required_power(alive,g,msn,DG,opt,V,Treq)
if Treq <= 0, p = 0; return; end
if ~any(alive), p = Inf; return; end
if max(abs(g.share-g.A/sum(g.A))) < 1e-12
    % Equal shaft power per disk area => common induced velocity on survivors.
    % Solve thrust analytically, then recover TOTAL installed shaft rating.
    rhoA = msn.rho_SL*sum(g.A(alive));
    vi = Treq/(rhoA*(sqrt(V^2+2*Treq/rhoA)+V));
    p = 2*msn.rho_SL*sum(g.A)*vi*(V+vi)^2/(opt.profile_eff*DG*550);
    if p > opt.max_hp_lb, p = Inf; end
else
    % Unequal disk loading (e.g. equal motors with unequal props).
    fun = @(pw) thrust_margin(pw,alive,g,msn,DG,opt,V,Treq);
    p = lower_root(fun,opt.max_hp_lb);
end
end
