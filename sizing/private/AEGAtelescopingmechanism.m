function h = AEGAtelescopingmechanism(msn,MTOW,S,b,r,p)
% Incremental TWO-WING hardware; the baseline full wing already includes tips.
% Preliminary lap-joint strength estimate plus explicit minimum-gauge targets.
% Stiffness, buckling, torsion, wear and jam loads require subsequent design.
ft2m = .3048; lb2N = 4.4482216153; kg2lb = 2.20462;
fields = {'Actuators_lb','Guides_lb','LocksBearings_lb','ControlsWiring_lb', ...
    'Seals_lb','OverlapCaps_lb','OverlapWebs_lb','OverlapSkin_lb', ...
    'LocalFittings_lb','TorsionBucklingReserve_lb'};
h = struct();
for j = 1:numel(fields), h.(fields{j}) = 0; end
h.total_lb = 0; h.stroke_each_m = r*b/2*ft2m;
h.overlap_each_m = 0; h.joint_chord_m = 0;
h.ultimate_shear_each_N = 0; h.ultimate_moment_each_Nm = 0;
if r==0, return; end
semi = b/2*ft2m; x = 1-r;
chord = 2*S/(b*(1+msn.TR))*(msn.TR+(1-msn.TR)*r)*ft2m;
depth = .65*msn.TCA*chord; width = .40*chord;
L = max(p.overlap_min_m,p.overlap_stroke_fraction*h.stroke_each_m);
assert(h.stroke_each_m+L < (1-r)*semi,'AEGAtelescopingmechanism:nesting', ...
    'Moving panel plus overlap does not fit inside the fixed core.');
% Elliptic lift integrated outboard of the stationary motor/joint at ULF.
I0 = pi/4-.5*(x*sqrt(max(0,1-x*x))+asin(x));
I1 = max(0,1-x*x)^(3/2)/3;
V = 2*msn.ULF*MTOW*lb2N/pi*I0;
M = 2*msn.ULF*MTOW*lb2N*semi/pi*(I1-x*I0);
rho = p.cfrp_density_kg_m3;
% Top/bottom caps and two webs, duplicated only over the lap length.
caps_kg = 2*(2*M/(depth*p.cap_allowable_MPa*1e6))*L*rho;
webs_kg = 2*(V/(p.web_allowable_MPa*1e6))*L*rho;
skin_kg = 2*2*(width+depth)*L*p.sleeve_laminate_mm/1000*rho;
joint_kg = caps_kg+webs_kg+skin_kg;
h.Actuators_lb = kg2lb*2*(p.actuator_each_kg+p.actuator_kg_per_m_stroke*h.stroke_each_m);
h.Guides_lb = kg2lb*2*p.guides_kg_per_m*(h.stroke_each_m+L);
h.LocksBearings_lb = kg2lb*2*p.locks_bearings_each_kg;
h.ControlsWiring_lb = kg2lb*p.controls_wiring_total_kg;
h.Seals_lb = kg2lb*4*chord*p.seal_kg_per_m;
h.OverlapCaps_lb = kg2lb*caps_kg;
h.OverlapWebs_lb = kg2lb*webs_kg;
h.OverlapSkin_lb = kg2lb*skin_kg;
h.LocalFittings_lb = kg2lb*joint_kg*p.local_fittings_fraction;
h.TorsionBucklingReserve_lb = kg2lb*joint_kg*p.torsion_buckling_reserve_fraction;
for j = 1:numel(fields), h.total_lb = h.total_lb+h.(fields{j}); end
h.overlap_each_m = L; h.joint_chord_m = chord;
h.ultimate_shear_each_N = V; h.ultimate_moment_each_Nm = M;
end
