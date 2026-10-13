function d = AEGAparasiticdrag(msn,S,SHT,SVT)
% Geometry-sensitive clean drag area. Polar calibration is applied ONCE.
% The reference scale is fixed in AEGAinputs; changing candidate geometry
% changes its drag rather than recalibrating each candidate back to one CD0.
scale=1;
if isfield(msn,'drag_buildup_scale'), scale=msn.drag_buildup_scale; end
validateattributes(scale,{'numeric'},{'scalar','finite','positive'});
DAV=(msn.WFus+msn.DFus)/2;
d.fuselage_wetted_ft2=AEGAfuselagewettedarea(msn);
Re=msn.Vkt*1.688*msn.XL/msn.nu_cr; fineness=msn.XL/DAV;
Cf=.455/log10(Re)^2.58;
d.fuselage_ft2=scale*Cf*(1+60/fineness^3+fineness/400)*d.fuselage_wetted_ft2*msn.excr;
d.wing_per_planform=scale*msn.Cf_w*msn.FF_w*msn.WETR*msn.excr;
d.wing_ft2=d.wing_per_planform*(S-msn.SCOV);
d.tail_ft2=scale*msn.Cf_t*msn.FF_t*msn.WETR*(SHT+SVT)*msn.excr;
d.misc_ft2=scale*msn.Cf_m*msn.FF_m*msn.SMISC*msn.excr;
d.total_ft2=d.fuselage_ft2+d.wing_ft2+d.tail_ft2+d.misc_ft2;
if isfield(msn,'CD0_override') && ~isempty(msn.CD0_override)
    validateattributes(msn.CD0_override,{'numeric'},{'scalar','positive','finite'});
    d.raw_calibrated_total_ft2=d.total_ft2;
    factor=msn.CD0_override*S/d.total_ft2;
    for field={'fuselage_ft2','wing_per_planform','wing_ft2','tail_ft2','misc_ft2'}
        d.(field{1})=d.(field{1})*factor;
    end
    d.total_ft2=msn.CD0_override*S;
end
d.CD0=d.total_ft2/S;
end
