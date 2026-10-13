function d = AEGAtelescopingjointdrag(msn,S,b,r,f,seal)
% Incremental drag area of two joints, beyond the generic excrescence factor.
% Geometry-based sensitivity, NOT a measured wing-joint drag correlation.
d = struct('step_ft2',0,'leak_ft2',0,'fairing_ft2',0,'total_ft2',0);
if r==0, return; end
c = 2*S/(b*(1+msn.TR))*(msn.TR+(1-msn.TR)*r)*.3048;
seam = 4*c; % upper/lower seam length on both wings, metres
step = (seal.step_closed_mm+(seal.step_extended_mm-seal.step_closed_mm)*f)/1000;
toft2 = 1/.3048^2;
d.step_ft2 = toft2*seal.step_effective_Cd*seal.seam_orientation_factor*seam*step;
d.leak_ft2 = toft2*seal.leak_effective_Cd*seam*seal.gap_mm/1000*seal.unsealed_fraction;
d.fairing_ft2 = toft2*seal.fairing_Cf*seal.fairing_form_factor*seam*seal.fairing_strip_mm/1000;
d.total_ft2 = d.step_ft2+d.leak_ft2+d.fairing_ft2;
end
