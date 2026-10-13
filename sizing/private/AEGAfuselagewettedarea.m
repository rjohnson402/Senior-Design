function area = AEGAfuselagewettedarea(msn)
% Shared fuselage wetted area in ft^2 for drag and structural weight.
% Empty/missing override retains the FLOPS geometry estimate for old inputs.
if isfield(msn,'fuselage_wetted_ft2') && ~isempty(msn.fuselage_wetted_ft2)
    area=msn.fuselage_wetted_ft2;
    validateattributes(area,{'numeric'},{'scalar','real','finite','positive'}, ...
        mfilename,'fuselage_wetted_ft2');
else
    diameter=(msn.WFus+msn.DFus)/2;
    area=pi*(msn.XL/diameter-1.7)*diameter^2; % FLOPS Eq.61
end
end
