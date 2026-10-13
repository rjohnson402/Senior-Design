function check_wingtipprop2035()
% Force/energy conservation, physical trends, legacy fallback and mission use.
m=AEGAinputs(); m.prop_power.mode='disk-area'; powered=AEGAsize(m);
off=m; off.wingtip_prop.enabled=false; legacy=AEGAsize(off);
old=rmfield(m,'wingtip_prop'); previous=AEGAsize(old);
for name={'MTOW','drag','CDi','Pcruise_kW','Ebat','PTO_kW'}
    assert(abs(legacy.(name{1})-previous.(name{1}))<1e-10);
end
baselinePath=fullfile(AEGAroot(),'trade_results','wingtip_baseline_before.mat');
if isfile(baselinePath)
    a=load(baselinePath,'base');
    % Only compare this saved snapshot if all original inputs still match.
    snapshot=rmfield(a.base.msn,'wingtip_prop');
    target=rmfield(legacy.msn,'wingtip_prop');
    if isequaln(snapshot,target)
        assert(abs(legacy.MTOW-a.base.MTOW)<1e-8 && abs(legacy.Ebat-a.base.Ebat)<1e-8);
    end
end
z=powered.wingtip_prop;
assert(z.enabled && powered.feasible && powered.converged);
assert(abs(z.force_balance_residual_lb)<1e-6 && abs(z.lift_balance_residual_lb)<1e-6);
assert(abs(z.power_balance_residual_kW)<1e-10 && z.swirl_power_kW>0);
assert(abs(z.zero_thrust_drag_lb-z.baseline_drag_lb)<1e-10);
assert(abs(powered.CDi* .5*m.rho_cr*(m.Vkt*1.688)^2*powered.cruise_geometry.area-z.induced_drag_lb)<1e-8);
assert(z.swirl_drag_lb<0 && z.induced_reduction_fraction>0);
% Equal aircraft/geometry comparison: no resize can disguise the change.
g=powered.cruise_geometry; o=powered.options; a=powered.msn;
W=powered.MTOW; S=powered.SW; b=powered.span; dragArea=powered.base_drag_area_ft2;
reverse=a; reverse.wingtip_prop.rotation=-1;
bad=AEGAtelescopingcruise(reverse,W,S,b,dragArea,o);
assert(bad.wingtip_prop.swirl_drag_lb>0 && bad.drag>g.drag);
% Holding the physical propeller diameter fixed, slower RPM increases swirl
% energy and its power penalty; it is not a free aerodynamic correction.
slow=a; slow.wingtip_prop.rpm=z.rpm(1)*.8;
fast=a; fast.wingtip_prop.rpm=z.rpm(1)*1.2;
gs=AEGAtelescopingcruise(slow,W,S,b,dragArea,o);
gf=AEGAtelescopingcruise(fast,W,S,b,dragArea,o);
assert(gs.wingtip_prop.swirl_power_kW>gf.wingtip_prop.swirl_power_kW);
diameters=[3 4.5 6]; diameterDrag=zeros(size(diameters));
for j=1:numel(diameters)
    dm=a; dm.prop_D_side_ft(end)=diameters(j);
    dd=AEGAtelescopingcruise(dm,W,S,b,dragArea,o); diameterDrag(j)=dd.drag;
    assert(abs(dd.wingtip_prop.advance_ratio(1)-a.wingtip_prop.design_J)<1e-12);
end
assert(max(diameterDrag)-min(diameterDrag)>.01);
% Core motors do not follow the extending tips. Test a fixed manual stroke.
t=a; t.prop_y_fraction_side(end)=.8;
oo=o; oo.retract_fraction=.2; oo.retraction_policy='manual'; oo.cruise_deployment=1;
% This is a hub-motion fixture, not a sized 20%-retractable aircraft. Ensure
% its shortened core can house the unchanged prop disks even when lighter
% structural inputs shrink the baseline wing below that packing threshold.
minimumCore=t.prop_high_lift_y_side_ft(end) ...
    +(t.prop_D_side_ft(end-1)+t.prop_D_side_ft(end))/2+.15;
jointArea=max(S,(2*minimumCore/.8)^2/t.AR);
jointSpan=sqrt(t.AR*jointArea);
extended=AEGAtelescopingcruise(t,W,jointArea,jointSpan,dragArea,oo);
oo.cruise_deployment=0;
retracted=AEGAtelescopingcruise(t,W,jointArea,jointSpan,dragArea,oo);
assert(max(abs(extended.wingtip_prop.hub_semispan_fraction-.8))<1e-12);
assert(max(abs(retracted.wingtip_prop.hub_semispan_fraction-1))<1e-12);
assert(max(abs(extended.wingtip_prop.hub_y_ft-retracted.wingtip_prop.hub_y_ft))<1e-12);
% Independent Fourier resolution change; guard total power and drag stability.
fine=a; fine.wingtip_prop.panels=128;
refined=AEGAtelescopingcruise(fine,W,S,b,dragArea,o);
assert(abs(refined.drag-g.drag)/g.drag<.005,'Wingtip drag is not resolved to 0.5%%.');
assert(abs(refined.wingtip_prop.shaft_kW-z.shaft_kW)/z.shaft_kW<.005);
% RPM stays at the reference design condition across multiple flight speeds.
[route,opts]=AEGAstudycase2035(m);
opts.mission_profile.route_speed_ktas=[110 120]; opts.mission_profile.route_distance_nm=[100 150];
opts.mission_profile.reserve_speed_ktas=100;
multi=AEGAsize(route,m.WS_design,opts);
for j=1:numel(multi.cruise_phases)
    phase=multi.cruise_phases(j); pz=phase.wingtip_prop;
    assert(max(abs(pz.rpm-multi.wingtip_prop.rpm))<1e-10);
    assert(abs(pz.thrust_lb-phase.drag_lb)<1e-6);
    assert(abs(pz.shaft_kW-phase.shaft_kW)<1e-8);
end
t=multi.operating_phases; required=t.RequiredForSizing;
assert(all(t.LiftPass(required) & t.PowerPass(required) & t.ThrustBalancePass(required)));
assert(abs(sum(t.EnergyWithAllowance_kWh)-multi.mission.E_range)<1e-8);
report=table([legacy.MTOW;powered.MTOW],[legacy.drag;powered.drag], ...
    [legacy.Pcruise_kW;powered.Pcruise_kW],[legacy.Ebat;powered.Ebat], ...
    'RowNames',{'Legacy';'Wingtip model'}, ...
    'VariableNames',{'MTOW_lb','CruiseDrag_lb','CruiseBattery_kW','UsableMission_kWh'});
disp(report);
folder=fullfile(AEGAroot(),'trade_results','wingtip_model_check');
if ~isfolder(folder), mkdir(folder); end
writetable(report,fullfile(folder,'current_comparison.csv'),'WriteRowNames',true);
save(fullfile(folder,'validation.mat'),'powered','legacy','multi','diameters','diameterDrag','refined');
fprintf('PASS: wingtip lift/thrust/energy balances, rotation, diameter/RPM, core hubs, Fourier refinement, fixed-RPM mission and exact disabled fallback.\n');
end
