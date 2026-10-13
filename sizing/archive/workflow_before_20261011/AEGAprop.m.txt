function [Dprop, Adisc, station, span, layout] = AEGAprop(msn, SW)
% aegaprop generates propeller diameters and spanwise locations from wing packing
%
% [Dprop, Adisc, station, span] = AEGAprop(msn, SW)
% [Dprop, Adisc, station, span, layout] = AEGAprop(msn, SW)
%
% the first four outputs remain compatible with the original equal-prop model.
% Dprop is the equivalent equal-diameter propeller that gives the same total
% disk area as the actual layout. for equal props this is the actual diameter.
%
% optional input fields:
% msn.prop_Dratio_side = diameter ratios on one wing, root to tip
% msn.prop_gap = absolute tip-to-tip gap between adjacent props, ft
% msn.Adisc_target = optional total disk area target for all propellers, ft^2
%
% if prop_Dratio_side is not supplied, all propellers are equal size.
% if prop_gap is not supplied, msn.fill sets the gap so the equal-prop case
% exactly reproduces the original packing rule.
%
% units: ft and ft^2
span = sqrt(msn.AR*SW);
if mod(msn.NPROP,2) ~= 0
    error('msn.NPROP must be even.')
end
Nside = msn.NPROP/2;
y_root = msn.WFus/2;
semi = span/2;
usable_half_span = semi - y_root;
if usable_half_span <= 0
    error('wing semispan must exceed the fuselage half-width.')
end
station = usable_half_span/Nside;
if isfield(msn,'prop_gap')
    gap = msn.prop_gap;
else
    gap = (1 - msn.fill)*station;
end
if gap < 0
    error('propeller gap must be nonnegative.')
end
edge_gap = gap/2;
if isfield(msn,'prop_Dratio_side') && ~isempty(msn.prop_Dratio_side)
    ratio_side = msn.prop_Dratio_side(:).';
elseif isfield(msn,'prop_root_tip_ratio') && ~isempty(msn.prop_root_tip_ratio)
    ratio_side = linspace(msn.prop_root_tip_ratio,1,Nside);
else
    ratio_side = ones(1,Nside);
end

if length(ratio_side) ~= Nside
    error('msn.prop_Dratio_side must contain one value per propeller on one wing.')
end
if any(ratio_side <= 0)
    error('all propeller diameter ratios must be positive.')
end
if any(diff(ratio_side) > 0)
    error('propeller diameter ratios must be nonincreasing from root to tip.')
end
if isfield(msn,'Adisc_target') && ~isempty(msn.Adisc_target)
    if msn.Adisc_target <= 0
        error('msn.Adisc_target must be positive.')
    end
    Dscale = sqrt(2*msn.Adisc_target/(pi*sum(ratio_side.^2)));
elseif isfield(msn,'prop_bank_frac') && ~isempty(msn.prop_bank_frac)
    if msn.prop_bank_frac <= 0 || msn.prop_bank_frac >= 1
        error('msn.prop_bank_frac must be between 0 and 1.')
    end
    bank_width = msn.prop_bank_frac*usable_half_span;
    disc_span_budget = bank_width - edge_gap - (Nside - 1)*gap;
    if disc_span_budget <= 0
        error('propeller bank is too narrow for the specified gaps.')
    end
    Dscale = disc_span_budget/sum(ratio_side);
else
    disc_span_budget = usable_half_span - (Nside - 1)*gap - 2*edge_gap;
    if disc_span_budget <= 0
        error('propeller gaps leave no usable span for the propeller disks.')
    end
    Dscale = disc_span_budget/sum(ratio_side);
end
D_side = Dscale*ratio_side;
y_side = zeros(1,Nside);
y_side(1) = y_root + edge_gap + D_side(1)/2;
for j = 2:Nside
    y_side(j) = y_side(j - 1) + D_side(j - 1)/2 + gap + D_side(j)/2;
end
outer_edge = y_side(end) + D_side(end)/2;
tip_clearance = semi - outer_edge;
fits = tip_clearance >= edge_gap - 1e-10;
if ~fits
    error('propeller layout does not fit inside the available half-span.')
end
A_side = pi*(D_side/2).^2;
Adisc = 2*sum(A_side);
Dprop = sqrt(4*Adisc/(msn.NPROP*pi));
layout.D_side = D_side;
layout.D_all = [fliplr(D_side) D_side];
layout.y_side = y_side;
layout.ratio_side = ratio_side;
layout.A_side = A_side;
layout.gap = gap;
layout.edge_gap = edge_gap;
layout.tip_clearance = tip_clearance;
layout.usable_half_span = usable_half_span;
layout.D_equiv = Dprop;
layout.fits = fits;
layout.D_weight_equiv = mean(D_side.^3)^(1/3);
layout.bank_frac = (outer_edge - y_root)/usable_half_span;
end
