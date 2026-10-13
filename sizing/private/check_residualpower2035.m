function check_residualpower2035()
% Independent constraints, per-disk power balance and rating sensitivity.
m=AEGAinputs(); out=AEGAsize(m); groups=out.power_groups;
assert(out.feasible && strcmp(groups.mode,'cruise-residual'));
assert(abs(out.PTO_kW-groups.cruise_pair_kW-groups.high_lift_total_kW)<1e-9);
required=max([out.Pcruise_shaft_kW out.cruise_phases.shaft_kW]);
assert(abs(groups.cruise_pair_kW-required*m.prop_power.cruise_rating_margin)<1e-8);
ratings=out.msn.prop_rating_each_kW; high=[1:3 5:7]; tips=[4 8];
assert(max(abs(ratings(high)-groups.high_lift_total_kW/6))<1e-10);
assert(max(abs(ratings(tips)-groups.cruise_pair_kW/2))<1e-10);
assert(all(out.PTO_kW>=out.eo.required_kW-1e-7));
assert(max(abs(out.eo.retained_power_fraction-out.eo.alive*out.eo.rating_share(:)))<1e-10);
t=out.operating_phases; active=t.RequiredForSizing;
assert(all(t.PowerPass(active) & t.LiftPass(active) & t.ThrustBalancePass(active)));
assert(max(abs(t.ShaftPower_kW-t.HighLiftShaft_kW-t.CruiseShaft_kW))<1e-8);
assert(max(abs(t.Thrust_lb-t.HighLiftThrust_lb-t.CruiseThrust_lb))<1e-8);
% Clean climb requires no blown-lift augmentation at the declared margin:
% cruise first, high-lift thrust equals whatever the rated cruise pair lacks.
row=t(t.Phase=="Clean climb",:);
assert(abs(row.CruiseShaft_kW-groups.cruise_pair_kW)<1e-7);
assert(abs(row.HighLiftThrust_lb-(row.RequiredThrust_lb-row.CruiseThrust_lb))<1e-6);
% Actual thrust fractions need not equal rating or disk area fractions.
take=t(t.Phase=="Takeoff",:);
assert(abs(take.CruiseThrust_lb/take.Thrust_lb-out.cruise_rating_fraction)>1e-3);
% A physical fixed cruise pair must not silently scale with high-lift demand.
fixed=m; fixed.prop_power.cruise_pair_rating_kW=groups.cruise_pair_kW*1.2;
rated=AEGAsize(fixed);
assert(abs(rated.power_groups.cruise_pair_kW-fixed.prop_power.cruise_pair_rating_kW)<1e-8);
% An optional hardware cap rejects the result; it does not cap the solved
% requirement and turn an underpowered aircraft into a passing design.
limited=m; limited.prop_power.max_installed_shaft_kW=out.PTO_kW*.9;
bad=AEGAsize(limited);
assert(~bad.feasible && contains(bad.status,'power budget'));
assert(abs(bad.PTO_kW-out.PTO_kW)<1e-7);
% Losing the cruise bank leaves only installed high-lift ratings, with no
% crossfeed. Check the selected failure-climb demand independently.
V=out.eo.options.climb_speed_kt*1.688; q=.5*m.rho_SL*V^2;
gamma=atan(out.eo.options.selected_climb_gradient);
CLreq=out.MTOW*cos(gamma)/(q*out.SW);
zero=AEGAblownstate2035(out.msn,out.SW,out.span,out.prop_layout,V,m.rho_SL,zeros(1,8),'landing',0,1);
D=q*out.SW*(out.CD0+zero.dCD_flap+CLreq^2/(pi*m.AR*m.e_osw));
failed=ratings; failed(tips)=0;
[pe,state,control]=AEGAallocatepower2035(out.msn,out.SW,out.span,out.prop_layout, ...
    V,m.rho_SL,failed,'landing',0,1,D+out.MTOW*sin(gamma), ...
    CLreq/out.eo.options.WS_margin,false);
assert(all(pe(tips)==0) && all(pe<=failed+1e-9));
assert(control.lift_pass && control.thrust_pass && state.thrust_lb>D);
folder=fullfile(AEGAroot(),'trade_results','residual_power_check');
if ~isfolder(folder), mkdir(folder); end
writetable(groups.constraints,fullfile(folder,'constraint_ratings.csv'));
writetable(t,fullfile(folder,'current_phase_power.csv'));
save(fullfile(folder,'validation.mat'),'out','rated','bad');
fprintf('PASS: independent group sum, constraint-sized total, residual climb thrust, per-disk thrust split, fixed cruise rating, power cap rejection and cruise-bank loss.\n');
end
