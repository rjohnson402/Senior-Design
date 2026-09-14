function W = AEGAweight(ac)
%AEGAWEIGHT  Component weight build-up for a battery-electric light trainer.
%
%   W = AEGAweight(ac)  returns a struct of component weights in pounds.
%   AEGAweight()        runs the AEGA baseline and prints a weight statement.
%
%   Adapted from the NASA Flight Optimization System (FLOPS) general aviation
%   equation set: Wells, Horvath & McCullers, NASA/TM-2017-219627 Vol. I, 2017.
%   Equation numbers in the comments refer to that report.
%
%   UNITS:  weight lb | length ft | area ft^2 | speed ft/s | gear length in
%           density slug/ft^3 | dynamic pressure lb/ft^2 | power kW | energy kWh
%
%   Every input is optional. Anything you leave out falls back to the AEGA
%   baseline default listed below.
if nargin == 0, ac = struct(); end
%% ======================= 1. AIRCRAFT LEVEL =============================
DG     = pick(ac,'DG',     2050);   % design gross weight (the loop solves this)
ULF    = pick(ac,'ULF',    6.0);    % ultimate load factor = 4.0 g x 1.5 safety
                                    %   (ASTM F2245 light sport. Part 23 normal
                                    %    category would be 3.8 x 1.5 = 5.7)
NSEAT  = pick(ac,'NSEAT',  2);      % total seats
NFLCR  = pick(ac,'NFLCR',  1);      % flight crew; FLOPS Eq. 118 uses 1 for
                                    %   general aviation, not 2
%% ======================= 2. WING =======================================
SW     = pick(ac,'SW',     80.0);   % wing reference area
AR     = pick(ac,'AR',     14);     % aspect ratio, span^2 / area
TR     = pick(ac,'TR',     0.45);   % taper ratio, tip chord / root chord
SWEEP  = pick(ac,'SWEEP',  3);      % quarter-chord sweep, degrees
TCA    = pick(ac,'TCA',    0.15);   % thickness-to-chord ratio
FCOMP  = pick(ac,'FCOMP',  0.8);    % composite fraction: 0 metal, 1 all carbon
FLAPR  = pick(ac,'FLAPR',  0.333);  % movable surface area / wing area
                                    %   (FLOPS default; flaps + ailerons)
%% ======================= 3. TAILS ======================================
SHT    = pick(ac,'SHT',    11.6);   % horizontal tail area
SVT    = pick(ac,'SVT',     9.6);   % vertical tail area
ARVT   = pick(ac,'ARVT',    1.5);   % vertical tail aspect ratio
TCVT   = pick(ac,'TCVT',    0.10);  % vertical tail thickness-to-chord
SWPVT  = pick(ac,'SWPVT',  20);     % vertical tail sweep, degrees
%% ======================= 4. FUSELAGE ===================================
XL     = pick(ac,'XL',     24.0);   % fuselage length
WF     = pick(ac,'WF',      2.30);  % fuselage maximum width
DF     = pick(ac,'DF',      3.12);  % fuselage maximum depth
XLP    = pick(ac,'XLP',     8.0);   % cabin length (drives furnishings)
SWFUS  = pick(ac,'SWFUS', 156);     % fuselage wetted area
%% ======================= 5. FLIGHT CONDITION ===========================
rho_c    = pick(ac,'rho_c',    0.002377);  % density at cruise
v_cruise = pick(ac,'v_cruise', 202.6);     % 120 knots true airspeed in ft/s
dV_ne    = pick(ac,'dV_ne',     50);       % never-exceed margin over cruise, kt
%% ======================= 6. MOTOR AND POWER ELECTRONICS ================
PTO_kW  = pick(ac,'PTO_kW',  165);  % takeoff shaft power
kWkg_m  = pick(ac,'kWkg_m',    7.0);% motor power density
kWkg_pe = pick(ac,'kWkg_pe',  14.0);% power electronics (inverter) power density
fred    = pick(ac,'fred',      0.10);% redundancy penalty: dual windings and
                                    %   dual inverters on one shaft
kgkW_th = pick(ac,'kgkW_th',   0.06);% thermal management, kg per kW installed
                                    %   (radiator, pump, coolant)
%% ======================= 7. PROPELLER ==================================
NPROP   = pick(ac,'NPROP',   1);    % number of propellers
Dprop   = pick(ac,'Dprop',   6.23); % diameter, ft (6.23 ft = 1.9 m)
NBLADE  = pick(ac,'NBLADE',  3);    % blades per propeller
AF      = pick(ac,'AF',    100);    % blade activity factor
%% ======================= 8. BATTERY ====================================
Ebat    = pick(ac,'Ebat',    130);  % USABLE energy the mission needs, kWh
whkg    = pick(ac,'whkg',    350);  % pack specific energy including management
                                    %   and thermal hardware, Wh/kg
fusable = pick(ac,'fusable',   0.90);% usable fraction of installed capacity
%% ======================= 9. SYSTEMS AND EQUIPMENT ======================
WAV     = pick(ac,'WAV',      40);  % avionics: two-screen glass panel, radio,
                                    %   transponder, ADS-B
fmarg   = pick(ac,'fmarg',     0.05);% empty weight margin, conceptual allowance
%% ======================= 10. CALIBRATION FACTORS =======================
% FLOPS Eqs. 106 and 110 are transport-derived and badly over-predict at
% two-seat scale (electrical alone returns ~385 lb on a 2,050 lb aircraft).
% Both the raw and calibrated values are returned so the correction is visible
% and defensible. Calibrate against the Pipistrel Velis Electro: 943 lb empty,
% 1,323 lb gross, two 70 kg battery packs.
KELEC   = pick(ac,'KELEC',   0.16); % on FLOPS electrical  -> about 62 lb
KFURN   = pick(ac,'KFURN',   0.35); % on FLOPS furnishings -> about 70 lb
%% ======================= 11. CONFIGURATION TRADE MODIFIERS =============
% These are the knobs you change when scoring different propulsor layouts.
NEW    = pick(ac,'NEW',    0);      % wing-mounted motors -> inertia relief in
                                    %   Eq. 38. KEEP AT 0: the 3% per motor was
                                    %   calibrated on airliner engines, not on
                                    %   30 kg electric motors
HHT    = pick(ac,'HHT',    0);      % 0 body-mounted tail, 1 T-tail (+20% fin)
Kgear  = pick(ac,'Kgear',  1.0);    % gear length multiplier; use ~1.3 for a
                                    %   pusher needing propeller clearance
dWinst = pick(ac,'dWinst', 0);      % nacelles, ducts, pylons, mounts, lb
%% ======================= 12. CONSTANTS =================================
LB       = 2.20462;      % kilograms to pounds
KT2FPS   = 1.688;        % knots to feet per second
RHO_SL   = 0.002377;     % sea level density, slug/ft^3
%% ======================= WING WEIGHT ===================================
SPAN  = sqrt(AR*SW);
FSTRT = 0;  FAERT = 0;  VARSWP = 0;      % no strut bracing, no aeroelastic
                                         %   tailoring, no variable sweep
EM    = 1 - 0.25*FSTRT;                                        % Eq. 11
TLAM  = tand(SWEEP) - 2*(1-TR)/((1+TR)*AR);                    % Eq. 14
SLAM  = TLAM/sqrt(1 + TLAM^2);                                 % Eq. 13
CAYA  = max(AR - 5, 0);                                        % Eq. 17
C6    = 0.5*FAERT - 0.16*FSTRT;
C4    = 1 - 0.5*FAERT;
CAYL  = (1 - SLAM^2)*(1 + C6*SLAM^2 + 0.03*CAYA*C4*SLAM);      % Eq. 12
BT    = 0.215*(0.37 + 0.7*TR)*(SPAN^2/SW)^EM/(CAYL*TCA);       % Eq. 10
A1 = 30;  A2 = 0;  A3 = 0.25;  A4 = 0.5;                 % general aviation
A5 = 0.5; A6 = 0.16; A7 = 1.2;                           %   constants, Table 1
CAYF  = 1;                                               % single fuselage
PCTL  = 1;                                               % wing carries all load
VFACT = 1 + VARSWP*(0.96/cosd(SWEEP) - 1);
CAYE  = max(1 - 0.03*NEW, 0.84);                               % Eq. 38
W1NIR = A1*BT*(1 + sqrt(A2/SPAN))*ULF*SPAN ...
        *(1 - 0.4*FCOMP)*(1 - 0.1*FAERT)*CAYF*VFACT*PCTL/1e6;  % Eq. 33
SFLAP = FLAPR*SW;
W2    = A3*(1 - 0.17*FCOMP)*SFLAP^A4*DG^A5;                    % Eq. 35
W3    = A6*(1 - 0.3 *FCOMP)*SW^A7;                             % Eq. 36
W1    = (DG*CAYE*W1NIR + W2 + W3)/(1 + W1NIR) - W2 - W3;       % Eq. 37
WWING = W1 + W2 + W3;                                          % Eq. 45
%% ======================= TAIL WEIGHT ===================================
QCRUS = 0.5*rho_c*v_cruise^2;                                  % Eq. 49
WHT   = 0.016*SHT^0.873*(ULF*DG)^0.414*QCRUS^0.122;            % Eq. 48
CSVT  = cosd(SWPVT);
WVT   = 0.073*(1 + 0.2*HHT)*(ULF*DG)^0.376*QCRUS^0.122 ...
        *SVT^0.873*(ARVT/CSVT^2)^0.357/(100*TCVT/CSVT)^0.49;   % Eq. 52
%% ======================= FUSELAGE WEIGHT ===============================
WFUSE = 0.052*SWFUS^1.086*(ULF*DG)^0.177*QCRUS^0.241;          % Eq. 60
%% ======================= LANDING GEAR WEIGHT ===========================
WLDG = DG;                          % ELECTRIC: nothing burns off, so the
                                    % aircraft lands at takeoff weight and the
                                    % gear is sized for it (Eq. 65, RFACT = 0)
XMLG = 0.0625*XL*12*Kgear;          % main gear length in inches (Eq. 66)
XNLG = 0.7*XMLG;                    % nose gear length in inches (Eq. 67)
WLGM = 0.0117*WLDG^0.95*XMLG^0.43;                             % Eq. 63
WLGN = 0.0480*WLDG^0.67*XNLG^0.43;                             % Eq. 64
%% ======================= SURFACE CONTROL WEIGHT ========================
v_dive = v_cruise + dV_ne*KT2FPS;
QDIVE  = 0.5*RHO_SL*v_dive^2;       % always sea level: never-exceed speed is
                                    %   defined there                 Eq. 100
WSC    = 0.404*SW^0.317*(DG/1000)^0.602*ULF^0.525*QDIVE^0.345; % Eq. 99
%% ======================= PROPULSION WEIGHT =============================
WMOT   = LB*(1 + fred)*PTO_kW/kWkg_m;     % replaces the FLOPS engine equation
WPE    = LB*(1 + fred)*PTO_kW/kWkg_pe;
WTHERM = LB*kgkW_th*PTO_kW;
WBLADE = 3.28e-6*AF^2*Dprop^3;      % Amatt, Bates & Borst, USAAMRDL TR 73-34B
WPROP  = NPROP*NBLADE*WBLADE;       %   (not FLOPS; scales as diameter cubed)
WBAT   = LB*Ebat/(fusable*whkg/1000);                          % Eq. 96
%% ======================= SYSTEMS WEIGHT ================================
NPASS     = max(NSEAT - NFLCR, 0);
WELEC_raw = 92*XL^0.4*WF^0.14*1^0.27*max(NPROP,1)^0.69 ...
            *(1 + 0.044*NFLCR + 0.0015*NPASS);                 % Eq. 106
WELEC     = KELEC*WELEC_raw;
WFURN_raw = 44*NSEAT + 2.6*XLP*(WF + DF);                      % Eq. 110
WFURN     = KFURN*WFURN_raw;
%% ======================= TOTALS ========================================
Wstruct = WWING + WHT + WVT + WFUSE + WLGM + WLGN;             % Eq. 136
Wprop   = WMOT + WPE + WTHERM + WPROP + dWinst;                % Eq. 137
Wsys    = WSC + WAV + WELEC + WFURN;                           % Eq. 138
Wmarg   = fmarg*(Wstruct + Wprop + Wsys);
W.wing        = WWING;   W.htail    = WHT;    W.vtail = WVT;
W.fuse        = WFUSE;   W.gear     = WLGM + WLGN;
W.structure   = Wstruct;
W.motor       = WMOT;    W.power_elec = WPE;  W.thermal = WTHERM;
W.propeller   = WPROP;   W.install    = dWinst;
W.propulsion  = Wprop;
W.controls    = WSC;     W.avionics = WAV;
W.electrical  = WELEC;   W.furnishings = WFURN;
W.systems     = Wsys;
W.electrical_raw  = WELEC_raw;    % uncalibrated FLOPS values, kept visible
W.furnishings_raw = WFURN_raw;
W.margin      = Wmarg;
W.battery     = WBAT;
W.empty       = Wstruct + Wprop + Wsys + Wmarg + WBAT;
W.span        = SPAN;    W.BT = BT;   W.qcruise = QCRUS;
%% ======================= OPTIONAL PRINTOUT =============================
if nargout == 0
    fprintf('\n  WEIGHT STATEMENT   (design gross weight %.0f lb)\n', DG);
    fprintf('  ----------------------------------------------\n');
    fprintf('  Wing                        %8.1f lb\n', WWING);
    fprintf('  Horizontal tail             %8.1f lb\n', WHT);
    fprintf('  Vertical tail               %8.1f lb\n', WVT);
    fprintf('  Fuselage                    %8.1f lb\n', WFUSE);
    fprintf('  Landing gear                %8.1f lb\n', WLGM + WLGN);
    fprintf('    STRUCTURE                 %8.1f lb\n', Wstruct);
    fprintf('  Motor                       %8.1f lb\n', WMOT);
    fprintf('  Power electronics           %8.1f lb\n', WPE);
    fprintf('  Thermal management          %8.1f lb\n', WTHERM);
    fprintf('  Propeller                   %8.1f lb\n', WPROP);
    fprintf('  Installation                %8.1f lb\n', dWinst);
    fprintf('    PROPULSION (dry)          %8.1f lb\n', Wprop);
    fprintf('  Surface controls            %8.1f lb\n', WSC);
    fprintf('  Avionics                    %8.1f lb\n', WAV);
    fprintf('  Electrical      (raw %6.0f) %8.1f lb\n', WELEC_raw, WELEC);
    fprintf('  Furnishings     (raw %6.0f) %8.1f lb\n', WFURN_raw, WFURN);
    fprintf('    SYSTEMS                   %8.1f lb\n', Wsys);
    fprintf('  Margin                      %8.1f lb\n', Wmarg);
    fprintf('  Battery (%.0f kWh usable)   %8.1f lb\n', Ebat, WBAT);
    fprintf('  ----------------------------------------------\n');
    fprintf('  EMPTY WEIGHT                %8.1f lb\n\n', W.empty);
    clear W
end
end
%% ========================================================================
function v = pick(s, name, default)
%PICK  Return s.(name) if the caller supplied it, otherwise the default.
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = default;
end
end