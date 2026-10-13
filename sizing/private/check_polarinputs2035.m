function check_polarinputs2035()
% Independent source, drag calibration, geometry, and landing-credit checks.
m=AEGAinputs(); p=m.polar; t=p.table;
assert(height(t)==5 && p.AR_ref>13 && p.AR_ref<13.02);
assert(abs(p.CD0_fit-.0243429468)<1e-9 && abs(p.k_fit-.03208755)<1e-8);
assert(p.fit_R2>.998 && p.max_abs_CD_residual<.001);
assert(max(abs(t.CD_total_summary-t.CD0_summary-t.CDi_wake))<1e-12);
% Recreate the old geometry independently, not from a selected sized result.
ref=m; ref.AR=p.AR_ref; ref.TR=.35;
ref.CD0_override=[]; % source-calibration checks explicitly use the old buildup
ref.fuselage_wetted_ft2=[]; % frozen polar reference predates any VSP area override
S=p.Sref_ft2; b=p.Bref_ft;
root=2*S/(b*(1+ref.TR)); mac=2*root*(1+ref.TR+ref.TR^2)/(3*(1+ref.TR));
sht=ref.Vh*mac*S/ref.Lh; svt=ref.Vv*b*S/ref.Lv;
d=AEGAparasiticdrag(ref,S,sht,svt);
assert(abs(d.CD0-p.CD0_fit)<1e-12);
assert(abs(1/(pi*ref.AR*ref.e_osw)-p.k_fit)<1e-12);
old=ref; old.drag_buildup_scale=1; raw=AEGAparasiticdrag(old,S,sht,svt);
assert(abs(raw.total_ft2-p.reference_raw_drag_area_ft2)<1e-12);
changed=ref; changed.XL=ref.XL+2; dd=AEGAparasiticdrag(changed,S,sht,svt);
assert(dd.total_ft2>d.total_ft2,'Geometry must not recalibrate itself back to constant CD0.');
% A team CD0 override is an explicit alternative, with consistent components.
if isfield(m,'CD0_override') && ~isempty(m.CD0_override)
    fixed=ref; fixed.CD0_override=m.CD0_override;
    for area=[S .8*S]
        f=AEGAparasiticdrag(fixed,area,sht,svt);
        assert(abs(f.CD0-m.CD0_override)<1e-12);
        assert(abs(f.total_ft2-f.fuselage_ft2-f.wing_ft2-f.tail_ft2-f.misc_ft2)<1e-12);
    end
end
% Telescoping subtracts the same calibrated exposed-wing area as the buildup.
[a,o]=AEGAstudycase2035(m); o.retract_fraction=.2; o.cruise_deployment=0;
o.CD0_scale=1; o.joint_drag_area_ft2=0;
g=AEGAtelescopingcruise(a,2300,S,sqrt(a.AR*S),d.total_ft2,o);
expected=d.total_ft2-d.wing_per_planform*(S-g.area);
assert(abs(g.CD0*g.area-expected)<1e-12);
assert(m.enforce_land && m.reverse_TW==.06 && m.reverse_hardware_lb>0);
noReverse=AEGAreversecase2035(m,0);
base=AEGAconstraint(noReverse,d.CD0,false,24,2.8,3.1);
reverse=AEGAreversecase2035(m,.05); reverse.DG=2300;
reverse.reverse_active_area_ft2=2*pi*(4.5/2)^2; reverse.reverse_available_shaft_kW=15;
withReverse=AEGAconstraint(reverse,d.CD0,false,24,2.8,3.1);
assert(base.S_land_ft>withReverse.S_land_ft);
[a,o]=AEGAstudycase2035(m); r=AEGAsize(a,m.WS_design,o);
assert(r.feasible && r.con.landing_ok && abs(r.weight_residual_lb)<.01);
fprintf('PASS: teammate polar fit/calibration, geometric drag, retraction consistency, gated reverse versus no-reverse landing and reference sizing.\n');
end
