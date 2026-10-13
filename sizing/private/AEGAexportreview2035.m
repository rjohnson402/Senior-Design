function folder = AEGAexportreview2035(wing,wings,props,folder,publish)
% Curate the three newly executed studies, preserving earlier presentation assets.
root=AEGAroot();
if nargin<5, publish=true; end
if nargin<4 || isempty(folder)
    folder=fullfile(root,'midterm_review',['current_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
end
if ~isfolder(folder), mkdir(folder); end
wp=wing.AR_best(wing.AR_best.PassesScreen & strcmp(wing.AR_best.Selection,'Minimum MTOW'),:);
pp=props.best(props.best.BatteryOutEnforced & props.best.Selection=="Minimum sampled MTOW",:);
sp=wings.best;
writetable(wp,fullfile(folder,'01_wing_selections.csv'));
writetable(sp,fullfile(folder,'02_fixed_adaptive_selections.csv'));
writetable(pp,fullfile(folder,'03_cruise_prop_selections.csv'));
fig=AEGAplotwingreview2035(wing,folder); close(fig);
for ext={'.png','.fig'}
    copyfile(fullfile(wings.options.output_dir,['05_optimized_comparison' ext{1}]), ...
        fullfile(folder,['02_fixed_vs_telescoping' ext{1}]));
    copyfile(fullfile(props.options.output_dir,['04_cruise_prop_trade' ext{1}]), ...
        fullfile(folder,['03_cruise_prop_trade' ext{1}]));
end
inputs=wing.source_inputs;
fid=fopen(fullfile(folder,'README.md'),'w'); assert(fid>=0);
guard=onCleanup(@() fclose(fid));
fprintf(fid,'# Updated review of the three trade studies\n\n');
fprintf(fid,'Executed from current inputs; separate timestamped source packages retained.\n\n');
fprintf(fid,'| Study | Search | Main figure |\n|---|---|---|\n');
fprintf(fid,'| Wing loading / AR | W/S %g–%g lb/ft², AR %g–%g; local W/S step %g (zero disables refinement) | [Wing trade](01_wing_loading_and_AR.png) |\n', ...
    min(wing.options.WS),max(wing.options.WS),min(wing.options.AR_values),max(wing.options.AR_values),wing.options.AR_refine_step);
fprintf(fid,'| Fixed / telescoping | W/S %g–%g, fixed AR %g–%g, taper %.2f–%.2f, adaptive AR18 and %.0f–%.0f%% capability | [Wing comparison](02_fixed_vs_telescoping.png) |\n', ...
    wings.options.WS_bounds,wings.options.fixed_AR_bounds,wings.options.taper_bounds,100*wings.options.retraction_bounds);
fprintf(fid,'| Cruise / high-lift props | Cruise %g–%g ft, high-lift %g–%g ft, W/S %g–%g; local refinement setting %g ft and %g lb/ft² (enabled %d) | [Prop trade](03_cruise_prop_trade.png) |\n\n', ...
    min(props.options.cruise_diameter_ft),max(props.options.cruise_diameter_ft), ...
    min(props.options.high_lift_diameter_ft),max(props.options.high_lift_diameter_ft),min(props.options.WS),max(props.options.WS), ...
    props.options.refine_step_ft,props.options.refine_WS_step,props.options.refine);
if isfield(props.options,'search_mode')
    fprintf(fid,'Search mode: **%s**. Explicit grids may override this preset. Review mode uses the current mission and required battery-out prop sizing; thorough mode adds denser sampling, mixed-speed wing comparison and all-operating prop comparison.\n\n',props.options.search_mode);
end
fprintf(fid,'Current mission: %.0f nm at %.0f KTAS, %.0f minutes reserve, %.0f lb payload. Battery: %.0f Wh/kg pack, %.0f%% usable. Motor/inverter: %.1f/%.1f kW/kg, %.0f%%/%.0f%% efficiencies.\n\n', ...
    inputs.range,inputs.Vkt,inputs.reserve,inputs.payload,inputs.whkg,100*inputs.fusable, ...
    inputs.kWkg_m,inputs.kWkg_pe,100*inputs.eta_m,100*inputs.eta_pe);
fprintf(fid,'All three use actual-throttle flight phases, two active cruise props, six high-lift props and mirrored-bank failure sizing. Landing is explicitly enforced. Source inputs and resolved study settings are stored in every MAT package.\n\n');
if isfield(inputs,'CD0_override') && ~isempty(inputs.CD0_override)
    fprintf(fid,'Clean-aircraft CD0 is held at the team-supplied %.5f, overriding the older polar intercept. Full-wing geometry does not change clean CD0 in this run. Effective e = %.4f is retained from the older polar; powered interaction corrections remain active.\n\n',inputs.CD0_override,inputs.e_osw);
elseif isfield(inputs,'polar')
    fprintf(fid,'Aerodynamics use the teammate summary polar: reference CD = %.6f + %.6f CL² at AR %.4f; effective e = %.4f. Clean parasite drag scales with geometry through a fixed calibrated buildup. The whole-aircraft interpretation is provisional pending component/trim confirmation.\n\n', ...
        inputs.polar.CD0_fit,inputs.polar.k_fit,inputs.polar.AR_ref,inputs.e_osw);
end
fprintf(fid,'Reference geometry for the wing and prop sweeps uses current input AR %.2f and taper %.2f. The fixed/adaptive comparison independently optimizes taper, with AR18 at full adaptive extension. Whole-wing multiplier after FLOPS composite terms: %.2f.\n\n', ...
    inputs.AR,props.options.taper,props.options.technology.wing_mass_factor);
fuseFactor=1; if isfield(inputs,'fuselage_mass_factor'), fuseFactor=inputs.fuselage_mass_factor; end
fprintf(fid,'Structures: ultimate load factor %.2f, FLOPS composite utilization FCOMP %.2f, and fuselage material factor %.2f applied once to raw Eq.60. These are conceptual sizing assumptions.\n\n', ...
    inputs.ULF,inputs.FCOMP,fuseFactor);
fprintf(fid,'The common high-lift hubs are spaced for a %.1f-ft diameter envelope. Their physical positions are held across studies; this is wider spacing than the earlier 2.8-ft envelope. Absolute changes against old packages therefore include a layout change.\n\n',props.options.anchor_high_lift_diameter_ft);
fprintf(fid,'## Updated results\n\n');
[~,j]=min(wp.MTOW_lb); w=wp(j,:);
fprintf(fid,'Best sampled wing trade: %.1f lb, AR %.2f, W/S %.2f, span %.2f ft. It holds taper at %.2f; compare AR/wing-loading changes within this study.\n\n',w.MTOW_lb,w.AR,w.WS_lb_ft2,w.Span_ft,wing.inputs.TR);
fprintf(fid,'Wing plots show rejected converged results as dashed curves and crosses, alongside the landing-distance target. The weight curve may continue decreasing beyond the passing cutoff: that lighter result is not a feasible optimum.\n\n');
if isfield(wing,'AR_diagnostics') && ~isempty(wing.AR_diagnostics)
    writetable(wing.AR_diagnostics,fullfile(folder,'01_wing_feasibility_diagnostics.csv'));
    diagnostic=wing.AR_diagnostics(wing.AR_diagnostics.AR==18,:);
    if ~isempty(diagnostic)
        fprintf(fid,'At AR18 the calculated weight trough is W/S %.2f, %.1f lb, landing %.0f ft; passes enabled screens: %d. This is compared with the minimum passing W/S %.2f, %.1f lb.\n\n', ...
            diagnostic.MinimumCalculatedWS_lb_ft2,diagnostic.MinimumCalculatedMTOW_lb, ...
            diagnostic.CalculatedMinimumLanding_ft,diagnostic.CalculatedMinimumPassesScreen, ...
            diagnostic.MinimumPassingWS_lb_ft2,diagnostic.MinimumPassingMTOW_lb);
    end
end
fprintf(fid,'| Mission | Wing | MTOW, lb | W/S | AR | Taper | Retraction capability | Search boundary |\n|---|---|---:|---:|---:|---:|---:|---|\n');
for j=1:height(sp)
    fprintf(fid,'| %s | %s | %.1f | %.2f | %.2f | %.3f | %.1f%% | %s |\n', ...
        sp.Profile(j),sp.Family(j),sp.MTOW_lb(j),sp.WS_lb_ft2(j),sp.AR_extended(j),sp.Taper(j),100*sp.RetractFraction(j),sp.BoundaryVariables(j));
end
fprintf(fid,'\n| Cruise diameter, ft | High-lift diameter, ft | W/S | MTOW, lb | Shaft rating, kW | High-lift bound? |\n|---:|---:|---:|---:|---:|---|\n');
for j=1:height(pp)
    bound=pp.AtLowerDiameterBound(j)||pp.AtUpperDiameterBound(j);
    fprintf(fid,'| %.2f | %.2f | %.2f | %.1f | %.1f | %d |\n',pp.CruiseDiameter_ft(j),pp.HighLiftDiameter_ft(j),pp.WS_lb_ft2(j),pp.MTOW_lb(j),pp.InstalledShaft_kW(j),bound);
end
[~,j]=min(pp.MTOW_lb);
fprintf(fid,'\nBest sampled battery-out prop design: %.2f-ft cruise / %.2f-ft high-lift. Cruise-diameter boundary flag: %d; wing-loading boundary flag: %d. Governing power case: %s.\n\n', ...
    pp.CruiseDiameter_ft(j),pp.HighLiftDiameter_ft(j),pp.AtCruiseDiameterBound(j),pp.AtWSBound(j),pp.PowerDriver(j));
fprintf(fid,'Retraction is selected from cruise drag subject to lift, fixed-prop packing and nesting. A 45%% allowed upper bound does not mean a design can achieve 45%%, or benefits from retracting. Inspect actual deployment in the source flight-phase tables.\n\n');
fprintf(fid,'## Interpretation and limits\n\n');
fprintf(fid,'AR18 remains the requested ceiling. A selected AR18 point is a bounded result, not evidence of a global structural optimum. Likewise, a taper or diameter endpoint identifies work still limited by the search/model.\n\n');
fprintf(fid,'Landing reverse-thrust target is %.0f%% of weight, with %.1f lb installed hardware. Engagement requires speed below %.0f kt AND at least %.1f s since touchdown, followed by a %.1f-s ramp. Actual credit is power-limited; the static screen is not a validated reverse map. The separate clean-stall enforcement flag is %d. Motor ratings and wingtip interaction follow the saved input models. RPM/torque/ground-clearance, detailed aeroelasticity, post-failure energy access and the preliminary wingtip interaction estimates require validation. Very small mathematical prop passes can demand unrealistic installed ratings; use the minimum-MTOW selections.\n\n',100*inputs.reverse_TW,inputs.reverse_hardware_lb,inputs.reverse_engage_below_kt,inputs.reverse_delay_s,inputs.reverse_ramp_s,inputs.enforce_VS1);
fprintf(fid,'The [reverse-thrust comparison](../../REVERSE_THRUST_REVIEW.md) includes separately sized no-reverse, nominal, stronger, heavier and unavailable-reverse cases. Run `AEGAtrades(''reverse'')` separately. Higher-W/S candidates may rely on reverse to meet the field target; inspect LandingNoReverse_ft.\n\n');
fprintf(fid,'The diameter bounds are engineering search choices, not validated hardware limits. For scale, NASA described 5-ft cruise and 1.9-ft high-lift props for X-57; its twelve-high-lift-prop architecture differs from this six-prop concept. [NASA X-57 overview](https://www.nasa.gov/centers-and-facilities/armstrong/x-57-maxwell/).\n\n');
fprintf(fid,'## Provenance and rerun\n\n');
fprintf(fid,'Wing cases: %d unique. Fixed/adaptive cases: %d. Prop cases: %d. Passing selections were checked for phase force/power/lift, mass and energy closure, prop geometry and current-input consistency.\n\n',numel(wing.details),height(wings.evaluated_designs),props.case_count);
fprintf(fid,'Source folders:\n\n- `%s`\n- `%s`\n- `%s`\n\n',wing.options.output_dir,wings.options.output_dir,props.options.output_dir);
fprintf(fid,'Run `AEGAtrades` to refresh all three, or select `''wing''`, `''wings''` or `''props''`. Edit aircraft/mission/technology in `AEGAinputs.m`; sweep settings are in `private/AEGAstudysettings2035.m` and may be overridden through AEGAtrades options. All samples call AEGAsize and quiet AEGAconstraint.\n');
clear guard
if ~publish, return; end
copyfile(fullfile(folder,'README.md'),fullfile(root,'CURRENT_TRADE_REVIEW.md'));
% The root copy uses root-relative links to this exact immutable review folder.
doc=fileread(fullfile(root,'CURRENT_TRADE_REVIEW.md'));
[~,name]=fileparts(folder);
for stem={'01_wing_loading_and_AR','02_fixed_vs_telescoping','03_cruise_prop_trade'}
    doc=strrep(doc,['(' stem{1} '.png)'],['(midterm_review/' name '/' stem{1} '.png)']);
end
fid=fopen(fullfile(root,'CURRENT_TRADE_REVIEW.md'),'w'); assert(fid>=0);
doc=strrep(doc,'(../../REVERSE_THRUST_REVIEW.md)','(REVERSE_THRUST_REVIEW.md)');
guard=onCleanup(@() fclose(fid)); fprintf(fid,'%s',doc);
end
