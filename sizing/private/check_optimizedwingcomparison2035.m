function check_optimizedwingcomparison2035()
% Verify independent optimized geometries, mission integration and ratings.
m = AEGAlegacyinputs2035(); % fixed historical fixture, independent of live defaults
baseline = AEGAsize(m,32,struct());
assert(abs(baseline.MTOW-2349.7110165744)<.01);
p = struct('name',"One-speed equivalence",'route_speed_ktas',m.Vkt, ...
    'route_distance_nm',m.range,'reserve_speed_ktas',m.Vkt);
equivalent = AEGAsize(m,32,struct('mission_profile',p));
assert(abs(equivalent.MTOW-baseline.MTOW)<1e-7);
assert(abs(equivalent.Ebat-baseline.Ebat)<1e-8);
o = struct('WS_grid',[26 34],'fixed_AR_grid',[14 18], ...
    'taper_grid',[.35 .5],'retraction_grid',[.05 .2], ...
    'WS_bounds',[26 34],'fixed_AR_bounds',[14 18],'taper_bounds',[.35 .5], ...
    'retraction_bounds',[.05 .2],'refine',true,'refine_seeds',1, ...
    'refine_max_evals',35,'doplot',false, ...
    'retraction_policy','manual','coupled_flight_phases',false, ...
    'anchor_high_lift_diameter_ft',2.8,'enforce_landing',false, ...
    'size_options',struct('weight_tolerance',.005), ...
    'output_dir',fullfile(AEGAroot(),'trade_results', ...
        'optimized_wing_validation'));
s = AEGAoptimizewings2035(m,o);
assert(height(s.best)==4 && all(s.best.PassesScreen));
assert(all(s.best.AR_extended(s.best.Family=="Adaptive")==18));
assert(all(s.best.RetractFraction(s.best.Family=="Fixed")==0));
assert(all(s.best.Mechanism_lb(s.best.Family=="Fixed")==0));
assert(all(s.best.Mechanism_lb(s.best.Family=="Adaptive")>0));
assert(any(s.evaluated_designs.Stage=="refinement"));
for j = 1:height(s.best)
    b = s.best(j,:); out = s.best_details{j};
    candidates = s.evaluated_designs(s.evaluated_designs.Profile==b.Profile & ...
        s.evaluated_designs.Family==b.Family & s.evaluated_designs.PassesScreen,:);
    assert(abs(b.MTOW_lb-min(candidates.MTOW_lb))<1e-8);
    assert(abs(out.weight_residual_lb)<.005);
    assert(abs(out.span^2/out.SW-b.AR_extended)<1e-8);
    assert(abs(out.SW*b.WS_lb_ft2-out.MTOW)<1e-8);
    assert(abs(sum([out.cruise_phases.energy_kWh])-out.mission.E_range)<1e-8);
    assert(abs(out.W.empty+out.msn.payload-out.MTOW)<.005);
    phases = s.selected_phases(s.selected_phases.Profile==b.Profile & s.selected_phases.Family==b.Family,:);
    assert(all(phases.CleanLiftPass) && all(phases.CruiseMotorPowerPass));
    assert(all(phases.StallSpeedFactor>=s.options.cruise_stall_speed_factor-1e-8));
    assert(max(phases.CruiseHubY_ft)-min(phases.CruiseHubY_ft)<1e-10);
    if b.Family=="Fixed", assert(max(phases.Span_ft)-min(phases.Span_ft)<1e-10); end
    assert(abs(out.prop_layout.y_side(end)-(1-b.RetractFraction)*out.span/2)<1e-8);
    % Independent integration from force/distance/efficiency verifies segment
    % accounting, reserve and the project's unchanged energy-unit convention.
    energy = 0;
    for k = 1:numel(out.cruise_phases)
        a = out.cruise_phases(k);
        energy = energy+a.drag_lb*a.distance_nm*6076.12/a.eta_total*(1+m.ovh)/2.6552e6;
    end
    assert(abs(energy-b.ProjectUsable_kWh)<1e-8);
    assert(abs(b.RequiredUsable_kWh-max(energy,out.mission.E_ppl_xc))<1e-8);
end
for name = unique(s.best.Profile).'
    a = s.best(s.best.Profile==name,:);
    assert(numel(unique(a.Range_nm))==1 && numel(unique(a.Reserve_min))==1);
end
% A broad speed profile must choose different wing states on one geometry.
out = s.best_details{find(s.best.Family=="Adaptive",1)};
opts = out.options; opts.mission_profile = struct('name',"Broad speed check", ...
    'route_speed_ktas',[100 200],'route_distance_nm',[50 200],'reserve_speed_ktas',120);
phases = AEGAmultispeedmission(out.msn,out.MTOW,out.SW,out.span, ...
    out.base_drag_area_ft2,opts,out.cruise_Adisc);
assert(phases(1).deployment>phases(2).deployment+.05);
assert(phases(3).deployment==1);
csv = readtable(fullfile(o.output_dir,'02_best_designs.csv'));
assert(max(abs(csv.MTOW_lb-s.best.MTOW_lb))<1e-8);
loaded = load(fullfile(o.output_dir,'optimized_wing_comparison.mat'),'saved');
assert(isequaln(loaded.saved.best,s.best));
fprintf('PASS: original sizing unchanged; matched missions; independent bounded searches; AR18 adaptive; fixed geometry; segment energy, closure, motor ratings and exports.\n');
end
