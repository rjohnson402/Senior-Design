function m = AEGAlegacyinputs2035()
% Explicit October 6 fixture for historical numerical regression checks.
% Current studies always call AEGAinputs; this fixture is not a design option.
m=AEGAinputs(); m.WS_design=32; m.AR=13; m.e_osw=.80;
% Historical airfoil/lift assumptions must not inherit the current section.
m=rmfield(m,'airfoil'); m.TCA=.15; m.CLmax_clean=1.6;
m.CLmax_L=m.CLmax_clean+m.dCLmax_L_flap; m.CLmax_TO=2.1;
% Freeze historical structural assumptions independently of the live design.
m.ULF=6.0; m.wing_mass_factor=.80; m.fuselage_mass_factor=1.0;
m.FCOMP=.90; % freeze historical utilization independently of current review
m.fuselage_wetted_ft2=[]; % historical geometry estimate, independent of VSP updates
% Historical fixture intentionally predates propeller-wing interaction.
m.wingtip_prop.enabled=false;
m.prop_power.mode='disk-area';
m.enforce_land=false; m.reverse_TW=.08; m.drag_buildup_scale=1;
m.reverse_model='legacy-immediate'; % original instantaneous credit
m.reverse_hardware_lb=0; % historical fixture predates reversing hardware mass
m=rmfield(m,'polar');
if isfield(m,'CD0_override'), m=rmfield(m,'CD0_override'); end
if isfield(m,'battery_motor_pairs'), m=rmfield(m,'battery_motor_pairs'); end
end
