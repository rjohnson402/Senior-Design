function study = AEGAengineout(msn,ref,opt)
%AEGAENGINEOUT Proposed 2035 engine-out lift/approach screening constraints.
% study = AEGAengineout(msn,out,opt), where out comes from AEGAsize.
% New standalone study: does not modify the existing sizing/weight solution.
% P/W means TOTAL INSTALLED shaft hp/lb, including failed motors.
% Prop numbering: [L1 L2 L3 L4 R1 R2 R3 R4], root to tip on each wing.
% 2-out: envelope of all 28 pairs. 4-out: L1,L2,R1,R2 (large inboard props).
% Surviving motors keep their individual ratings; no failed power transfer.
% Lift capacity is an untrimmed screening model, not a control/certification proof.
if nargin < 3, opt = struct(); end
opt = defaults(opt,msn,ref);
assert(msn.NPROP == 8,'This comparison requires eight propellers.');
validateattributes(opt.ratio,{'numeric'},{'scalar','finite','>=',1});
validateattributes(opt.VS_kt,{'numeric'},{'scalar','positive','finite'});
validateattributes(opt.approach_factor,{'numeric'},{'scalar','>=',1});
validateattributes(opt.WS,{'numeric'},{'vector','positive','finite'});
assert(opt.WS_margin > 0 && opt.WS_margin <= 1);
assert(opt.power_margin >= 1 && opt.max_hp_lb > 0);
assert(opt.failed_disk_CD >= 0 && opt.profile_eff > 0 && opt.profile_eff <= 1);
assert(opt.approach_deg > 0 && opt.approach_deg < 90);
assert(any(strcmp(opt.rating_mode,{'disk-area','equal'})));

validateattributes(opt.climb_gradients,{'numeric'},{'vector','real','finite','nonnegative'});
validateattributes(opt.selected_climb_gradient,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(opt.climb_speed_kt,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(opt.takeoff_dCD,{'numeric'},{'scalar','real','finite','nonnegative'});
opt.climb_gradients = unique([opt.climb_gradients(:).' opt.selected_climb_gradient]);
igselected = find(abs(opt.climb_gradients-opt.selected_climb_gradient)<1e-12,1);
ng = numel(opt.climb_gradients);
DG = ref.MTOW;
WS = unique([opt.WS(:).' ref.WSR]);
idxref = find(abs(WS-ref.WSR) < 1e-9,1);
pairs = nchoosek(1:8,2);
alive = true(30,8);
for k = 1:28, alive(k+1,pairs(k,:)) = false; end
alive(30,[1 2 5 6]) = false;
families = {'Equal','Two-size','Graded'};
r = opt.ratio;
ratios = [ones(1,4); r r 1 1; linspace(r,1,4)];

study.options = opt;
study.reference = ref;
study.WS = WS;
study.pairs = pairs;
study.alive = alive;
study.numbering = {'L1','L2','L3','L4','R1','R2','R3','R4'};
study.family = struct([]);
for f = 1:3
    fam = struct();
    fam.name = families{f};
    fam.ratios = ratios(f,:);
    fam.required_hp_lb = nan(3,numel(WS));
    fam.lift_hp_lb = nan(3,numel(WS));
    fam.approach_hp_lb = nan(3,numel(WS));
    fam.worst_pair = nan(numel(WS),2);
    fam.approach_lift_ok = false(3,numel(WS));
    fam.approach_only_required_hp_lb = nan(3,numel(WS));
    % Dimensions: failure group, W/S, gradient, configuration.
    % Configurations: 1 takeoff; 2 go-around with landing flaps retained.
    fam.climb_hp_lb = nan(3,numel(WS),ng,2);
    if opt.print
        fprintf('Engine-out study: %s (%d/3), %d wing loadings...\n',families{f},f,numel(WS));
        drawnow;
    end
    for iw = 1:numel(WS)
        if opt.print && (mod(iw,10)==0 || iw==numel(WS))
            fprintf('  %s: wing loading %d/%d\n',families{f},iw,numel(WS));
            drawnow;
        end
        S = DG/WS(iw);
        g = geometry(msn,S,ratios(f,:),opt);
        required = inf(30,1);
        plift = inf(30,1);
        papp = inf(30,1);
        app_ok = false(30,1);
        pclimb = inf(30,ng,2);
        for k = 1:30
            a = alive(k,:);
            % Lift-only 60 kt screening bound at maximum surviving rating.
            q = 0.5*msn.rho_SL*(opt.VS_kt*1.688)^2;
            CLreq = WS(iw)/(q*opt.WS_margin);
            lift_residual = @(pw) lift_margin(pw,a,g,msn,DG,opt,CLreq);
            plift(k) = lower_root(lift_residual,opt.max_hp_lb);

            % Controlled approach: solve exact descent thrust at Vapp.
            Va = opt.approach_factor*opt.VS_kt*1.688;
            qa = 0.5*msn.rho_SL*Va^2;
            CLa = DG*cosd(opt.approach_deg)/(qa*S);
            Dfailed = qa*opt.failed_disk_CD*sum(g.A(~a));
            Da = qa*S*(ref.CD0 + g.dCDflap + CLa^2/(pi*msn.AR*msn.e_osw)) + Dfailed;
            Treq = Da - DG*sind(opt.approach_deg);
            if Treq >= 0
                papp(k) = thrust_required_power(a,g,msn,DG,opt,Va,Treq);
                if isfinite(papp(k))
                    approach = flow(papp(k),a,g,msn,DG,opt,Va);
                    app_ok(k) = approach.CL >= CLa/opt.WS_margin - 1e-9;
                end
            end
            % Extra installed power cannot fix insufficient approach lift
            % at the throttle required for this exact glide path.
            if app_ok(k)
                required(k) = opt.power_margin*max(plift(k),papp(k));
            end
        end
        approach_only = required;
        if opt.include_climb
            for cfg = 1:2
                for ig = 1:ng
                    for k = 1:30
                        pclimb(k,ig,cfg) = climb_required(alive(k,:),g,msn,DG, ...
                            ref.CD0,opt,opt.climb_gradients(ig),cfg);
                    end
                end
            end
            required = max(required,max(pclimb(:,igselected,:),[],3));
        end
        groups = {1,2:29,30};
        for j = 1:3
            ids = groups{j};
            fam.required_hp_lb(j,iw) = max(required(ids));
            fam.approach_only_required_hp_lb(j,iw) = max(approach_only(ids));
            for cfg = 1:2
                for ig = 1:ng
                    fam.climb_hp_lb(j,iw,ig,cfg) = max(pclimb(ids,ig,cfg));
                end
            end
            fam.lift_hp_lb(j,iw) = opt.power_margin*max(plift(ids));
            fam.approach_hp_lb(j,iw) = opt.power_margin*max(papp(ids));
            fam.approach_lift_ok(j,iw) = all(app_ok(ids));
        end
        [~,worst] = max(required(2:29));
        fam.worst_pair(iw,:) = pairs(worst,:);
        if iw == idxref
            fam.reference = diagnostics(g,alive,pairs,required,plift,papp,app_ok, ...
                msn,ref,opt);
            fam.reference.approach_only_required_hp_lb = approach_only;
            fam.reference.climb_hp_lb = pclimb;
            [~,ic] = max(max(pclimb(2:29,igselected,:),[],3));
            fam.reference.worst_climb_pair = pairs(ic,:);
        end
    end
    if f == 1
        study.family = fam;
    else
        study.family(f) = fam;
    end
end

% Original normal-operation curves are reference overlays, not re-optimized.
c = AEGAconstraint(msn,ref.CD0,false,ref.WSR,ref.CLmax,ref.CLmax_TO);
study.normal = c;
if opt.doplot
    draw_study(study);
    if opt.include_climb, draw_climb(study); end
end
if opt.print, print_study(study); end
end

function opt = defaults(opt,msn,ref)
d.WS = linspace(12,max(48,1.15*ref.WSR),37);
d.ratio = 1.30;
d.VS_kt = msn.VS0;
d.approach_factor = 1.30;
d.approach_deg = msn.approach_angle;
d.rating_mode = 'disk-area';
d.profile_eff = msn.prof;
d.failed_disk_CD = 0; % optimistic feathered/folded increment; supply data
d.WS_margin = 0.98;
d.power_margin = 1.02;
d.max_hp_lb = 0.60; % numerical search ceiling, not a physical feasibility limit
d.include_climb = true;
d.climb_gradients = [0 0.01 0.02 0.03]; % gradient = height / horizontal distance
d.selected_climb_gradient = 0.02; % exploratory target, not a regulation
d.climb_speed_kt = 1.30*msn.VS0; % separate from clean-wing climb speed
d.takeoff_dCD = 0.03; % PRELIMINARY takeoff-flap drag increment; replace with data
d.doplot = true;
d.print = true;
names = fieldnames(d);
for j = 1:numel(names)
    if ~isfield(opt,names{j}), opt.(names{j}) = d.(names{j}); end
end
end

function g = geometry(msn,S,ratios,opt)
m = msn;
% All families get the SAME disk area at each W/S, equal to equal-prop
% packing at that wing size (or an explicit pre-existing Adisc_target).
m.prop_Dratio_side = ones(1,4);
[~,Atarget] = AEGAprop(m,S);
m.Adisc_target = Atarget;
m.prop_Dratio_side = ratios;
[~,~,~,b,layout] = AEGAprop(m,S);
g.S = S; g.b = b; g.semi = b/2;
g.D = [layout.D_side layout.D_side];
g.y = [-layout.y_side layout.y_side];
g.A = pi*(g.D/2).^2;
g.cr = 2*S/(b*(1+msn.TR));
g.ct = msn.TR*g.cr;
g.yroot = msn.WFus/2;
frac = 0.8;
if isfield(msn,'flap_span_frac') && ~isempty(msn.flap_span_frac)
    frac = msn.flap_span_frac;
end
g.yflap = min(frac*g.semi,g.semi);
g.dcl = msn.dclmax_flap_L*msn.K_flap_sweep;
Af = area_integral(g.yroot,g.yflap,g);
g.CLbase = msn.CLmax_clean + g.dcl*2*Af/S;
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

function d = diagnostics(g,alive,pairs,req,plift,papp,app_ok,msn,ref,opt)
pwref = ref.PTO_kW/(0.745699872*ref.MTOW);
q = 0.5*msn.rho_SL*(opt.VS_kt*1.688)^2;
for k = 1:30
    s = flow(pwref,alive(k,:),g,msn,ref.MTOW,opt,opt.VS_kt*1.688);
    CL(k,1) = s.CL; %#ok<AGROW>
    CLraw(k,1) = s.CL_uncapped; %#ok<AGROW>
    roll(k,1) = s.capacity_roll_ftlb; %#ok<AGROW>
    yaw(k,1) = s.yaw_ftlb; %#ok<AGROW>
    retained(k,1) = sum(g.share.*alive(k,:)); %#ok<AGROW>
    moment(k,1) = s.thrust_moment_norm; %#ok<AGROW>
end
d.D_side = g.D(1:4);
d.motor_kW_side = ref.PTO_kW*g.share(1:4);
d.Adisc = sum(g.A);
d.CL_at_reference_power = CL;
d.CL_uncapped_at_reference_power = CLraw;
d.WS_lift_limit_at_reference_power = opt.WS_margin*q*CL;
d.retained_power_fraction = retained;
d.required_hp_lb = req;
d.lift_hp_lb = plift;
d.approach_operating_equivalent_hp_lb = papp;
d.approach_lift_ok = app_ok;
d.capacity_roll_ftlb = roll;
d.yaw_ftlb = yaw;
d.thrust_moment_norm = moment;
[~,i] = max(plift(2:29)); d.worst_lift_pair = pairs(i,:);
[~,i] = max(abs(yaw(2:29))); d.worst_yaw_pair = pairs(i,:);
[~,i] = max(abs(roll(2:29))); d.worst_capacity_roll_pair = pairs(i,:);
d.reference_power_passes = all(req <= pwref*(1+1e-8));
end

function draw_study(s)
colors = [0.1 0.4 0.8;0.85 0.3 0.05;0.55 0.15 0.65];
labels = {'All operating','Worst 2 out','4 inboard out'};
figure('Color','w','Name','Proposed 2035 engine-out constraints');
tiledlayout(1,3);
ax = gobjects(1,3);
for f = 1:3
    ax(f) = nexttile; hold on; grid on; box on;
    set(gca,'Color','w','XColor','k','YColor','k');
    c = s.normal;
    plot(c.W_S,c.PW_cruise,'--','Color',[0.7 0.7 0.7],'DisplayName','Normal cruise');
    plot(c.W_S,c.PW_climb,':','Color',[0.4 0.4 0.4],'DisplayName','Normal climb');
    plot(c.W_S,c.PW_turn,'-.','Color',[0.6 0.6 0.6],'DisplayName','Normal turn');
    plot(c.W_S,c.PW_takeoff,'-','Color',[0.5 0.5 0.5],'DisplayName','Normal takeoff');
    for j = 1:3
        y = s.family(f).required_hp_lb(j,:); y(~isfinite(y)) = NaN;
        plot(s.WS,y,'LineWidth',2,'Color',colors(j,:),'DisplayName',labels{j});
    end
    plot(s.reference.WSR,s.reference.PTO_kW/(0.745699872*s.reference.MTOW), ...
        'kp','MarkerFaceColor',[1 .8 0],'MarkerSize',11,'DisplayName','Original sizing point');
    xlabel('Wing loading W/S, lb/ft^2'); ylabel('TOTAL INSTALLED shaft P/W, hp/lb');
    title(s.family(f).name,'Color','k');
    if numel(s.WS)>1, xlim([min(s.WS) max(s.WS)]); end
    legend('Location','northwest','TextColor','k','Color','w');
end
linkaxes(ax,'y');
if s.options.include_climb
    sgtitle(sprintf('Lift + approach + %.1f%% climb at %.0f kt; D ratio %.2f', ...
        100*s.options.selected_climb_gradient,s.options.climb_speed_kt,s.options.ratio),'Color','k');
else
    sgtitle(sprintf('Lift + approach only; D ratio %.2f',s.options.ratio),'Color','k');
end
end

function print_study(s)
fprintf('\n2035 ENGINE-OUT SCREENING: fixed MTOW %.1f lb, fixed CD0 %.5f\n', ...
    s.reference.MTOW,s.reference.CD0);
fprintf('Motor ratings: %s. No overload or failed-motor power transfer.\n',s.options.rating_mode);
if s.options.include_climb
    fprintf('Climb target %.1f%% at %.1f kt, sea level, out of ground effect.\n', ...
        100*s.options.selected_climb_gradient,s.options.climb_speed_kt);
    fprintf('Both takeoff and landing-flap go-around enforced; assumed takeoff DeltaCD = %.3f.\n',s.options.takeoff_dCD);
end
fprintf('4 out means L1,L2,R1,R2. 2 out checks all 28 pairs.\n');
fprintf('Values below use reference W/S %.3f and reference installed power %.1f kW.\n', ...
    s.reference.WSR,s.reference.PTO_kW);
for f = 1:3
    d = s.family(f).reference;
    fprintf('\n%s: diameters per wing [%.3f %.3f %.3f %.3f] ft\n',s.family(f).name,d.D_side);
    fprintf(' CL at full surviving rating: all %.3f, worst 2 %.3f, 4 inboard %.3f\n', ...
        d.CL_at_reference_power(1),min(d.CL_at_reference_power(2:29)),d.CL_at_reference_power(30));
    fprintf(' Required installed kW at this W/S: all %.1f, worst 2 %.1f, 4 inboard %.1f\n', ...
        d.required_hp_lb(1)*s.reference.MTOW*.745699872, ...
        max(d.required_hp_lb(2:29))*s.reference.MTOW*.745699872, ...
        d.required_hp_lb(30)*s.reference.MTOW*.745699872);
    if s.options.include_climb
        isel = find(abs(s.options.climb_gradients-s.options.selected_climb_gradient)<1e-12,1);
        for cfg = 1:2
            cfgname = {'Takeoff','Go-around'};
            v = d.climb_hp_lb(:,isel,cfg)*s.reference.MTOW*.745699872;
            fprintf(' %s climb installed kW: all %.1f, worst 2 %.1f, 4 inboard %.1f\n', ...
                cfgname{cfg},v(1),max(v(2:29)),v(30));
        end
    end
    fprintf(' Four-inboard retained power %.1f%%; all-op normalized thrust moment %.4f\n', ...
        100*d.retained_power_fraction(30),d.thrust_moment_norm(1));
    fprintf(' Worst 2-out lift pair [%d %d]; yaw pair [%d %d]; lift-capacity moment pair [%d %d]\n', ...
        d.worst_lift_pair,d.worst_yaw_pair,d.worst_capacity_roll_pair);
end
fprintf('\nInf/gaps mean no solution within the search ceiling or failed approach lift/trim screen.\n');
fprintf('Inspect approach_lift_ok; raise max_hp_lb to test the numerical ceiling.\n');
fprintf('These are fixed-weight overlays, not re-sized MTOW or demonstrated controllability.\n');
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

function draw_climb(s)
figure('Color','w','Name','Engine-out climb gradient sensitivity');
tiledlayout(2,3);
ax = gobjects(2,3);
labels = {'Worst 2 out','4 inboard out'};
groups = [2 3];
colors = lines(numel(s.options.climb_gradients));
for row = 1:2
    for f = 1:3
        ax(row,f) = nexttile; hold on; grid on; box on;
        set(gca,'Color','w','XColor','k','YColor','k');
        for ig = 1:numel(s.options.climb_gradients)
            v = max(s.family(f).climb_hp_lb(groups(row),:,ig,:),[],4);
            v = reshape(v,1,[]); v(~isfinite(v)) = NaN;
            plot(s.WS,v,'LineWidth',1.7,'Color',colors(ig,:), ...
                'DisplayName',sprintf('%.0f%% climb',100*s.options.climb_gradients(ig)));
        end
        base = s.family(f).approach_only_required_hp_lb(groups(row),:);
        base(~isfinite(base)) = NaN;
        plot(s.WS,base,'k--','DisplayName','Lift + approach');
        plot(s.reference.WSR,s.reference.PTO_kW/(.745699872*s.reference.MTOW), ...
            'kp','MarkerFaceColor',[1 .8 0],'MarkerSize',10,'DisplayName','Original sizing point');
        title(sprintf('%s: %s',s.family(f).name,labels{row}),'Color','k');
        xlabel('W/S, lb/ft^2'); ylabel('Installed shaft P/W, hp/lb');
        if numel(s.WS)>1, xlim([min(s.WS) max(s.WS)]); end
        legend('Location','best','TextColor','k','Color','w');
    end
end
linkaxes(ax(:),'y');
sgtitle(sprintf('Climb at %.0f kt: envelope of takeoff and landing-flap go-around; fixed weight', ...
    s.options.climb_speed_kt),'Color','k');
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
