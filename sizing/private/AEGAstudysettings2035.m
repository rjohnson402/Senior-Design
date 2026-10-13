function c = AEGAstudysettings2035(msn)
% Shared current-study choices. Mission/technology come from the input struct.
% AR18 is the requested conceptual ceiling; prop hardware is a study choice.
if nargin<1, msn=AEGAinputs(); end
[~,~,c.technology]=AEGAtelescopingassumptions2035();
mapping={'pack_Whkg','whkg';'usable_fraction','fusable'; ...
    'motor_kWkg','kWkg_m';'inverter_kWkg','kWkg_pe'; ...
    'motor_efficiency','eta_m';'inverter_efficiency','eta_pe'};
for j=1:size(mapping,1), c.technology.(mapping{j,1})=msn.(mapping{j,2}); end
if isfield(msn,'wing_mass_factor'), c.technology.wing_mass_factor=msn.wing_mass_factor; end
c.AR_max=18; c.reference_AR=msn.AR; c.reference_taper=msn.TR;
c.high_lift_diameter_ft=2.8; c.cruise_diameter_ft=4.5;
c.anchor_high_lift_diameter_ft=3.2; c.prop_gap_ft=.15;
if isfield(msn,'cruise_prop_diameter_ft'), c.cruise_diameter_ft=msn.cruise_prop_diameter_ft; end
if isfield(msn,'high_lift_prop_diameter_ft'), c.high_lift_diameter_ft=msn.high_lift_prop_diameter_ft; end
if isfield(msn,'prop_anchor_diameter_ft'), c.anchor_high_lift_diameter_ft=msn.prop_anchor_diameter_ft; end
c.WS=unique([12:2:48 msn.WS_design]);
c.AR=unique([8:2:18 msn.AR]); c.AR=c.AR(c.AR>=8 & c.AR<=18);
c.cruise_diameters_ft=[2:.25:3.5 4:.5:6]; % bracket the observed 2.75-3-ft minimum
c.high_lift_diameters_ft=unique([1:.25:2 2.4 2.8 3.2 c.high_lift_diameter_ft]);
c.prop_WS=msn.WS_design; % isolate prop diameter at the selected wing loading
c.taper_bounds=[.15 .70]; c.taper_grid=unique([.15 .20 .35 .50 .70 msn.TR]);
c.retraction_bounds=[.20 .45];
c.enforce_landing=msn.enforce_land; % live project policy, currently true
end
