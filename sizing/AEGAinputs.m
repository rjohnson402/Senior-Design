function msn = AEGAinputs()
%AEGAINPUTS  Single source of truth for AEGA design inputs.
%
%   msn = AEGAinputs()   returns the current baseline input struct.
%
%   Scripts read these design choices. Sizing adds derived geometry to its
%   local copy; DG, SW, PTO_kW, Ebat and Dprop are calculated results.
%
%   Current concept: W/S = 27 lb/ft^2, AR = 15.5, taper = .35, 6% ground reverse.
%   The adaptive wing extends to AR18; fixed-wing trades search up to AR18.
%   For one-off alternatives, copy and override:
%       msn = AEGAinputs();
%       msn.WS_design = 30;  msn.AR = 13.5;
%       out = AEGAsize(msn);
%
%   Values deliberately NOT here, because they belong to one script only:
%     AEGAweight   - FLOPS Table 1 constants A1..A7, CAYF, PCTL, FSTRT,
%                    FAERT, VARSWP
%     AEGAsize     - NMAX, TOL, secant update
%     AEGAconstraint - ROC target, climb/turn speeds, load factor, TOP
%
%   UNITS: weight lb | length ft | area ft^2 | speed ft/s unless the field
%          name says otherwise | density slug/ft^3 | power kW | energy kWh
%
%   OWNER: one person. Changes go through review, not straight to main.

%% ===================== MISSION REQUIREMENTS =========================
msn.payload  = 400;      % lb, 2 x (185 + 15)
msn.range    = 250;      % nm, current team study; assigned requirement is 300.
msn.assigned_range_nm = 300; % keep the requirement gap visible; re-size to assess it.
msn.reserve  = 45;       % minutes at cruise
msn.Vkt      = 120;      % cruise, knots TRUE airspeed
msn.VS0      = 60;       % KCAS, project landing-config target; powered-lift sizing screen.
msn.VS1_op   = 59;       % KCAS, separate clean-stall study target (disabled).
                         % Certification/operating applicability needs separate review.
msn.ovh      = 0.04;     % taxi, takeoff, climb, descent energy allowance
msn.S_field  = 1500;     % ft, field length over a 50 ft obstacle. Used by
                         %   AEGAconstraint for BOTH takeoff and landing.
msn.enforce_VS1  = false; % true: size W/S to the VS1_op sport-pilot limit
msn.enforce_land = true; % enforce the stated landing field target in current sizing
msn.dV_ne    = 50;       % kt, never-exceed margin over cruise. Equivalent to
                         %   VD = 1.417 VC. Should be a formula tied to the
                         %   ASTM F2245 design speeds, not a constant.
msn.approach_angle = 3;  % approach_angle is in degrees


msn.CLmax_cap = 4.0;     % hard cap on the blown CLmax. A STATED ASSUMPTION,
                         %   not a computed result. The dynamic-pressure
                         %   blend has no upper bound and knows nothing about
                         %   separation, so without this it runs away.

%% ===================== ATMOSPHERE ===================================
msn.h_cr     = 5000;             % ft, cruise altitude
msn.rho_SL   = 0.002377;         % slug/ft^3, sea level ISA
msn.rho_cr   = 0.002048;         % slug/ft^3, ISA at 5000 ft
msn.mu_cr    = 3.68041e-7;       % DYNAMIC viscosity, slug/(ft*s)
msn.nu_cr    = msn.mu_cr/msn.rho_cr;   % KINEMATIC viscosity, ft^2/s
msn.g0       = 32.174;           % ft/s^2

%% ===================== AERODYNAMIC COEFFICIENTS =====================

% Selected wing section. clmax_2d=2.3 is the team's 2D analysis result;
% Reynolds number, transition/roughness and solver settings are still needed.
% UIUC coordinates confirm approximately 17% thickness near 30% chord.
msn.airfoil = struct('name','LS(1)-0417MOD', ...
    'thickness_chord',.17,'max_thickness_xc',.30, ...
    'clmax_2d',2.3,'wing_clmax_factor',.90, ...
    'analysis_Re',[],'analysis_Mach',[], ...
    'clmax_basis','Team-supplied 2D analysis; operating conditions unconfirmed', ...
    'coordinate_file',fullfile(AEGAroot(),'data','aerodynamics','ls417mod.dat'));
% 0.90 is an analyst finite-wing allowance, not a validated stall prediction.
% This is the CLEAN, unpowered wing value BEFORE flaps or propeller blowing.
msn.CLmax_clean = msn.airfoil.clmax_2d*msn.airfoil.wing_clmax_factor; % 2.07

% --------------------- Landing flaps ---------------------------------
% Preliminary large single-slotted flap geometry.
% Flaps extend from near the fuselage to about 80% of each semispan.
% About 69% of the wing planform lies within the flapped span.
msn.flap_chord_frac = 0.32;    % flap chord / local wing chord
msn.flap_area_frac  = 0.69;    % flapped wing planform area / total wing area
msn.flap_def_L      = 40;      % landing flap deflection, deg

% Approximate section CLmax increase from the landing flap.
% Roskam-style finite-wing correction:
%
% Delta CLmax = Delta clmax * (S_wf/S) * K_sweep
%
% This gives approximately:
% Delta CLmax = 1.40 * 0.69 * 0.92 = 0.89
msn.dclmax_flap_L = 1.40;
msn.K_flap_sweep  = 0.92;

msn.dCLmax_L_flap = msn.dclmax_flap_L ...
                   * msn.flap_area_frac ...
                   * msn.K_flap_sweep;

% Unblown landing CLmax.
% Actual-thrust propeller blowing is added later by the sizing/phase models.
msn.CLmax_L = msn.CLmax_clean + msn.dCLmax_L_flap;

% Retain the previous whole-wing takeoff flap allowance (2.1 - 1.6 = .5).
% This is an assumed increment, not LS(1)-0417MOD flapped section data.
msn.dCLmax_TO_flap = .50;
msn.CLmax_TO = msn.CLmax_clean + msn.dCLmax_TO_flap; % unblown, 2.57

% --------------------- Landing flap drag ------------------------------
% Actual movable flap area is approximately:
%
% S_flap/S = (flap chord fraction)*(flapped wing area fraction)
%
%          = 0.32 * 0.69
%          = 0.221
%
% For preliminary sizing, model the highly deflected flap approximately
% as a plate exposed to the flow. The sin^2(delta) term represents the
% increasing projected area as the flap is deflected.
%
% This is a rough conceptual-design drag model, not a final CFD result.
msn.CD_flap_factor = 1.10;

msn.dCD_flap_L = msn.CD_flap_factor ...
                * msn.flap_chord_frac ...
                * msn.flap_area_frac ...
                * sind(msn.flap_def_L)^2;

% Current estimate gives Delta CD_flap approximately 0.10.

% --------------------- Landing ground roll ----------------------------
% Touchdown speed relative to stall speed.
msn.VTD_factor = 1.15;

% Effective tire/brake friction coefficient on dry pavement.
msn.mu_brake = 0.35;

% Reverse thrust after touchdown expressed as a fraction of aircraft weight.
%
% T_reverse = reverse_TW * W
%
% Conditional reversing-pitch concept: both cruise props, ground roll only.
% Target is capped by assigned power and a static momentum screen; it is not
% a validated reverse propeller map. Set reverse_TW=0 to disable braking
% credit while retaining the installed hardware; also set hardware_lb=0
% for a separately sized aircraft without reversing hardware.
msn.reverse_TW = 0.06; % nominal total reverse target, fraction of aircraft weight
msn.reverse_model='delayed-target';
msn.reverse_delay_s=2; msn.reverse_ramp_s=1;
msn.reverse_engage_below_kt=55; % first brake below this speed; wait at least 2 s
msn.reverse_fade_start_kt=15; msn.reverse_off_kt=5;
msn.reverse_shaft_request_kW=18; msn.reverse_rating_fraction=.50;
msn.reverse_static_merit=.50; msn.reverse_hardware_lb=2.20462*9;
msn.reverse_pair_available=true;
% private-pilot solo cross-country sizing mission
% three legs give 150 nm total with three full-stop landings
% the first leg is greater than 50 nm
msn.enforce_ppl_xc = true;
msn.ppl_xc_leg_nm = [60 45 45];
msn.ppl_xc_takeoff_min = 1.0;
msn.ppl_xc_climb_alt_ft = 5000;
% After touchdown the aircraft is de-rotated, so the wing does not remain
% at CLmax. Assume ground-roll CL is 50% of the unblown landing CLmax.
msn.CL_ground_frac = 0.50;

msn.e_osw = 0.80; % replaced below by the supplied clean polar's effective e

%% ===================== WING =========================================
msn.WS_design = 27;     % lb/ft^2; landing margin is recalculated by the shared sizing model
msn.AR = 15.5;          % current team reference; sizing and reference sweeps honor this input
msn.TR = 0.35;
msn.SWEEP = 2;        % deg, QUARTER-CHORD convention for the new analysis handoff
msn.sweep_reference = 'quarter-chord';
msn.TCA = msn.airfoil.thickness_chord; % wing weight and telescoping spar depth
msn.FCOMP = 0.80;      % moderate FLOPS composite credit; not a material mass fraction
                         % 24% bending-term, 10.2% surface, 18% miscellaneous reductions
                         % see assumption_review_20261013/REVIEW.md
msn.FLAPR = 0.333;
msn.flap_span_frac = 0.80;

%% ===================== TAILS ========================================
msn.Vh     = 0.60;       % horizontal tail volume coefficient
msn.Vv     = 0.040;      % vertical tail volume coefficient
msn.Lh     = 18;      % ft, horizontal tail arm
msn.Lv     = 19;      % ft, vertical tail arm
msn.ARVT   = 1.5;        % vertical tail aspect ratio. Confirm with controls.
msn.TCVT   = 0.10;       % NO SOURCE. Implies a NACA 0010-class section.
msn.SWPVT  = 20;         % deg. NO SOURCE. Measure off the fin layout.
msn.HHT    = 1;          % provisional T-tail (+20% fin weight); trim not established

%% ===================== FUSELAGE =====================================
msn.XL     = 22.0;       % ft, length. NO SOURCE - needs a station diagram.

msn.WFus = 48/12;   % 4.00 ft, exterior width
msn.DFus = 50/12;   % 4.17 ft, exterior depth
msn.fuselage_wetted_ft2 = 184.5; % updated team fuselage wetted area, ft^2
                            % ft^2; confirm against complete fuselage CAD wetted area
                            % [] uses the length/width/depth estimate for BOTH models
msn.fuselage_mass_factor = .90; % provisional 10% credit below raw FLOPS Eq. 60
                               % allowance for joints, cutouts and practical construction
msn.XLP    = 4.0;        % ft, cabin length (drives furnishings)

%% ===================== DRAG BUILD-UP ================================
msn.SMISC  = 48.4;       % ft^2, gear fairings, canopy, junctions. NO SOURCE.
msn.SCOV   = 6.78;       % ft^2, wing area buried in the fuselage
msn.WETR   = 2.05;       % wetted / planform ratio, wing and tails
msn.Cf_w   = 0.0033;
msn.FF_w   = 1.30;
msn.Cf_t   = 0.0036;
msn.FF_t   = 1.20;
msn.Cf_m   = 0.0040;
msn.FF_m   = 1.30;
msn.Cf_c   = 0.0030;     % configuration-added surfaces
msn.excr   = 1.13;       % conceptual excrescence/interference allowance, retained

%% ===================== PROPULSION ===================================
msn.NPROP   = 8;         % propulsors
msn.cruise_prop_diameter_ft = 2.75; % updated midterm reference, two outer props
msn.high_lift_prop_diameter_ft = 1.5; % practical near-minimum sampled choice
msn.battery_motor_pairs = [1 5;2 6;3 7;4 8]; % baseline used by existing wing studies
% Proposed cross-pair option: [1 5;2 6;3 8;4 7]. One cruise motor survives
% every single bank loss. Requires yaw/roll control and bank-energy analysis.
msn.prop_anchor_diameter_ft = 3.2; % retain common physical hubs from prior trades
msn.prop_root_tip_ratio = 1.30;
msn.prop_bank_frac = [];     
% msn.Dprop REMOVED. Propeller diameter is now DERIVED from span packing
% by AEGAprop(), because a fixed value goes stale the moment the wing
% changes: at the converged span of 33 ft the old 2.43 ft understated disc
% area by 46 percent, and blow_wind was deriving a different diameter than
% AEGAsize was using.
msn.use_blown_wind  = true; % 1 if true, 0 if false
msn.fill    = 0.90;      % disc diameter / station pitch
msn.NBLADE  = 5;         % shared blade-count placeholder; verify each prop group's design
msn.AF      = 130;       % blade activity factor. ESTIMATE - needs the
                         %   USAAMRDL TR 73-34B blade data.
msn.kWkg_m  = 17.0;     % retained team 2035 bare-motor target, per user direction
                         % RPM/torque and continuous rating remain unverified
msn.kWkg_pe = 14.0;      % power electronics, project statement
msn.fred    = 0.05;      % mass allowance only; motor count does not prove redundancy
msn.kgkW_th = 0.06;      % thermal management, kg per kW installed. NO SOURCE.
                         %   NASA STARC-ABL basis would give roughly double.
msn.eta_m   = 0.95;
msn.eta_pe  = 0.97;
msn.prof    = 0.86;      % propeller profile factor, CRUISE
% Two cruise motors sized for the cruise mission; six high-lift motors supply
% residual low-speed thrust and the blowing/failure requirements separately.
% No peak overload is credited. Empty cruise rating means automatic sizing.
msn.prop_power = struct('mode','cruise-residual','cruise_rating_margin',1.02, ...
    'cruise_pair_rating_kW',[],'max_installed_shaft_kW',Inf);
% Preliminary NASA PEGASUS-inspired rotating-disk / lifting-line interaction.
% Blade geometry/map is unavailable: these are explicit design assumptions.
% Enabled for cruise/reserve only; see docs/WINGTIP_PROPELLER_MODEL.md.
msn.wingtip_prop = struct('enabled',true,'design_J',1.35,'rpm',[], ...
    'reference_speed_ktas',[],'rotation',1,'hub_radius_fraction',.20, ...
    'x_over_D',.25,'lift_curve_slope',2*pi,'panels',64,'max_tip_mach',.85);
% rotation +1 = inboard-up (both sides mirrored); -1 = inboard-down.
% Empty rpm designs each diameter at design_J, then holds RPM across phases.
msn.etap_cl = 0.65;      % propeller efficiency in CLIMB and TAKEOFF. A prop
                         %   optimised for 120 kt does not hold cruise
                         %   efficiency at 60 kt. Using the cruise value here
                         %   was making AEGAconstraint return 0.085 kW/kg,
                         %   below both the Velis Electro and the 172S.
msn.etap_cr = 0.84;      % propeller efficiency in CRUISE and TURN
% Installed power is solved by the sizing/constraint loop, not entered by hand.
msn.dWinst  = 120;       % lb, nacelles, pylons, hubs, harness. ALL ESTIMATE:
                         %   64 nacelles + 16 hubs + 40 harness. Now the
                         %   largest unmodelled mass in the aircraft.
            

%% ===================== BATTERY ======================================
msn.whkg    = 400;       % Wh/kg at PACK level, project statement.
                         %   Velis Electro today: 24.8 kWh / 140 kg = 177.
msn.fusable = 0.90;      % usable fraction of installed capacity
                         % Design-point pack capability; no additional ageing derate.

%% ===================== STRUCTURES ===================================
msn.ULF    = 5.7;        % requested ULTIMATE load factor, used directly in weight/joint loads
msn.NSEAT  = 2;
msn.NFLCR  = 1;          % FLOPS Eq. 118 uses 1 for general aviation
msn.Kgear  = 1.0;        % gear length multiplier, 1.0 for a tractor
msn.NEW    = 0;          % no large-engine inertia-relief credit for this small DEP layout
msn.wing_mass_factor = 1.0; % no extra reduction after the FLOPS FCOMP composite credit

%% ===================== SYSTEMS AND CALIBRATION ======================
msn.WAV    = 40;         % lb, avionics. NO SOURCE - itemise from vendor data.
msn.fmarg  = 0.05;       % retained dry-empty weight allowance, excludes battery/payload
                         % 10% was evaluated as a sensitivity, not adopted
msn.KELEC  = 0.16;       % on FLOPS Eq. 106, calibrated to Velis Electro
msn.KFURN  = 0.35;       % on FLOPS Eq. 110, same single calibration point
msn.NELEC  = 1;          % propulsor count SEEN BY Eq. 106. The N^0.69 term
                         %   is transport engine-electrical and does not
                         %   apply to distributed electric propulsion:
                         %   it returns 267 lb at N=8 against a bottom-up
                         %   harness estimate near 40 lb. Harness mass is
                         %   carried in dWinst instead.

%% ===================== TEAM POLAR CALIBRATION =======================
% Source copied intact to data/aerodynamics. Five clean points, alpha 0-8 deg.
% Fit uses the summary's own CLwtot / CDtot pair. The fit intercept includes
% a wake-drag offset; it must NOT be replaced by the summary Cd0 alone.
msn.polar = AEGAreadpanelpolar();
msn.e_osw = msn.polar.e_effective;
% Frozen legacy buildup at S=73.4, b=30.9, taper=.35, 120 KTAS, 5000 ft,
% 28 x 4 x 4.1667-ft fuselage and the original skin-friction/tail assumptions.
% Holding this calibration reference fixed preserves geometry sensitivities.
msn.polar.reference_raw_drag_area_ft2 = 1.9805210514734117;
msn.drag_buildup_scale = msn.polar.CD0_fit*msn.polar.Sref_ft2 ...
    /msn.polar.reference_raw_drag_area_ft2;
% Team-supplied final midterm clean-aircraft CD0. This overrides the older
% polar intercept for sizing and trades; the original polar data stay intact.
% [] restores the geometry-sensitive calibrated buildup. Fixed CD0 suppresses
% its area/geometry sensitivity and must be stated on the trade-study slides.
msn.CD0_override = 0.020768;

end
