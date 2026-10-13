function check_wingtrades2035()
%CHECK_WINGTRADES2035 Run the coupled trade model's physics/export checks.
% These are regression/physics checks; no figures are opened.
m = AEGAinputs();
% Preserve original sizing helpers; legacy trade behavior is explicitly selected.
% Current-configuration input propagation is checked in check_currenttrades2035.
[D0,A0,~,b0,g0] = AEGAprop(m,80);
[Dt,At,~,bt,gt] = AEGAtrade_prop(m,80);
assert(abs(D0-Dt)<1e-10 && abs(A0-At)<1e-10 && abs(b0-bt)<1e-10);
assert(max(abs(g0.D_side-gt.D_side))<1e-10);
assert(max(abs(g0.y_side-gt.y_side))<1e-10);
m.NPROP = 8; m.use_blown_wind = true;
m.enforce_VS1 = false; m.enforce_land = false;
m.prop_Dratio_side = [1 1 1 1.3]; m.prop_bank_frac = .90;
if isfield(m,'Adisc_target'), m = rmfield(m,'Adisc_target'); end
[~,A,~,b,g] = AEGAtrade_prop(m,80);
assert(g.D_side(4)>g.D_side(1));
assert(abs(A-2*sum(g.A_side))<1e-9);
assert(abs(g.bank_frac-.90)<1e-10);
assert(g.tip_clearance>0 && g.fits);
assert(abs(b^2/80-m.AR)<1e-10);
ref = struct('MTOW',2700,'SW',2700/36,'CD0',.028);
e = AEGAbatteryout(m,ref,struct());
assert(isequal(e.pairs,[1 5;2 6;3 7;4 8]));
assert(all(sum(~e.alive(2:5,:),2)==2));
assert(all(isfinite(e.required_hp_lb)));
assert(all(e.required_hp_lb(2:5)>=e.required_hp_lb(1)-1e-8));
assert(abs(e.retained_power_fraction(5)-(1-1.3^2/(3+1.3^2)))<1e-10);
eq = m; eq.prop_Dratio_side = ones(1,4);
ee = AEGAbatteryout(eq,ref,struct());
assert(max(abs(ee.retained_power_fraction(2:5)-.75))<1e-10);
steep = AEGAbatteryout(m,ref,struct('selected_climb_gradient',.03));
assert(all(steep.required_hp_lb>=e.required_hp_lb-1e-8));
limited = m; limited.CLmax_cap = 2;
bad = AEGAbatteryout(limited,ref,struct());
assert(all(isinf(bad.required_hp_lb)),'The 60 kt lift cap must reject this case.');

r = AEGAsize(m,34,struct());
assert(r.converged && r.feasible);
assert(abs(r.MTOW-r.SW*r.WSR)<1e-8);
assert(abs(r.span^2/r.SW-m.AR)<1e-10);
assert(abs(r.weight_residual_lb)<.05);
assert(r.PTO_kW/(r.MTOW*.745699872)>=max(r.eo.required_hp_lb)-1e-8);
assert(r.PTO_kW>=r.Pcruise_kW*m.eta_m*m.eta_pe-1e-7);
cleaner = AEGAsize(m,34,struct('CD0_scale',.9));
assert(cleaner.converged && cleaner.MTOW<r.MTOW);
assert(cleaner.pack_kWh<r.pack_kWh);

o = struct('current_configuration',false,'WS',[30 34],'do_AR',false,'do_drag',false,'do_climb',false, ...
    'do_battery',true,'pack_Whkg_values',[350 m.whkg], ...
    'do_mission',true,'range_nm_values',[200 m.range 300], ...
    'reserve_min_values',m.reserve,'doplot',false, ...
    'output_dir',tempname);
s = AEGAwingtrades(m,o);
assert(height(s.main)==4 && all(s.main.Converged));
assert(all(s.main.DetailIndex>=1) && ~isempty(s.best));
assert(height(s.battery)==2*numel(unique([350 m.whkg])));
assert(height(s.mission)==2*numel(unique([200 m.range 300])));
assert(all(s.battery.PassesScreen) && all(s.mission.PassesScreen));
base = s.main(s.main.BatteryOutEnforced & s.main.WS_lb_ft2==34,:);
batteryBase = s.battery(s.battery.WS_lb_ft2==34 & s.battery.PackWh_kg==m.whkg,:);
missionBase = s.mission(s.mission.WS_lb_ft2==34 & s.mission.Range_nm==m.range,:);
assert(base.DetailIndex==batteryBase.DetailIndex && base.DetailIndex==missionBase.DetailIndex);
if m.whkg > 350
    heavierPack = s.battery(s.battery.WS_lb_ft2==34 & s.battery.PackWh_kg==350,:);
    assert(heavierPack.MTOW_lb>base.MTOW_lb && heavierPack.Battery_lb>base.Battery_lb);
end
if m.range < 300
    longer = s.mission(s.mission.WS_lb_ft2==34 & s.mission.Range_nm==300,:);
    assert(longer.MTOW_lb>=base.MTOW_lb && longer.Pack_kWh>=base.Pack_kWh);
end
assert(exist(fullfile(o.output_dir,'wingtrade_results.mat'),'file')==2);
exported = readtable(fullfile(o.output_dir,'05_battery_energy_density.csv'));
assert(height(exported)==height(s.battery));
exported = readtable(fullfile(o.output_dir,'06_mission_requirements.csv'));
assert(height(exported)==height(s.mission));
saved = load(fullfile(o.output_dir,'wingtrade_results.mat'),'study');
assert(isequaln(saved.study.battery,s.battery));

% Refinement must retain coarse samples and valid geometry, with separately
% reported landing-constrained candidates. Check two ARs without graphics.
aropt = struct('current_configuration',false,'WS',[30 34 38],'AR_values',[m.AR 15], ...
    'AR_refine_step',.5,'AR_refine_half_width',2, ...
    'do_AR',true,'do_drag',false,'do_climb',false,'doplot',false, ...
    'output_dir',tempname);
ars = AEGAwingtrades(m,aropt);
assert(height(ars.AR)>6 && height(ars.AR_best)==8);
assert(numel(unique(ars.AR.AR))==2 && any(ars.AR.AR==15));
assert(all(ars.AR.WS_lb_ft2>=30 & ars.AR.WS_lb_ft2<=38));
assert(height(unique(ars.AR(:,{'AR','WS_lb_ft2'})))==height(ars.AR));
good = ars.AR.PassesScreen;
assert(all(abs(ars.AR.Span_ft(good).^2./ars.AR.Wing_ft2(good)-ars.AR.AR(good))<1e-9));
assert(all(ars.AR.PropDiameterMax_ft(good)>=ars.AR.PropDiameterMin_ft(good)));
assert(all(ars.AR.DiskArea_ft2(good)>0));
for ar = unique(ars.AR.AR).'
    a = ars.AR(ars.AR.AR==ar,:);
    assert(all(ismember(aropt.WS,a.WS_lb_ft2)));
    best = ars.AR_best(ars.AR_best.AR==ar & strcmp(ars.AR_best.Selection,'Minimum MTOW'),:);
    passing = a(a.PassesScreen,:);
    assert(best.PassesScreen && abs(best.MTOW_lb-min(passing.MTOW_lb))<1e-8);
end
landing = ars.AR_best(strcmp(ars.AR_best.Selection,'Minimum MTOW + landing check'),:);
assert(all(landing.LandingCheckPass(landing.PassesScreen)));
assert(exist(fullfile(aropt.output_dir,'07_AR_design_summary.csv'),'file')==2);
fprintf('PASS: geometry, failure bounds, MTOW closure, drag/battery/mission sweeps, cache and CSV/MAT export.\n');
end
