function W = AEGAweight(msn, st)
%AEGAWEIGHT  Component weight build-up for a battery-electric light trainer.
%
%   W = AEGAweight(msn, st)  returns a struct of component weights in pounds.
%   AEGAweight()             runs the baseline and prints a weight statement.
%
%   msn  design inputs from AEGAinputs(). READ ONLY - this function never
%        writes to it.
%   st   loop state from AEGAsize: DG, SW, SHT, SVT, PTO_kW, Ebat, SWFUS.
%        These are RESULTS, not inputs. Omit any field and a standalone
%        fallback is used so AEGAweight() alone still runs.
%
%   Adapted from the NASA Flight Optimization System (FLOPS) general aviation
%   equation set: Wells, Horvath & McCullers, NASA/TM-2017-219627 Vol. I, 2017.
%   Equation numbers in the comments refer to that report.
%
%   UNITS:  weight lb | length ft | area ft^2 | speed ft/s | gear length in
%           density slug/ft^3 | dynamic pressure lb/ft^2 | power kW | energy kWh

if nargin < 1 || isempty(msn), msn = AEGAinputs(); end
if nargin < 2, st = struct(); end

%% ======================= LOOP STATE ====================================
% Standalone fallbacks only. In a sizing run AEGAsize supplies all of these.
DG     = state(st,'DG',     2200);   % design gross weight
SW     = state(st,'SW',       80.0); % wing reference area
SHT    = state(st,'SHT',      20);   % horizontal tail area
SVT    = state(st,'SVT',      15);   % vertical tail area
PTO_kW = state(st,'PTO_kW',  165);   % takeoff shaft power
Ebat   = state(st,'Ebat',    130);   % usable mission energy, kWh
Dprop  = state(st,'Dprop',     2.88);% propeller diameter, ft. DERIVED by
                                     % AEGAprop from span packing, not an
                                     % input. The fallback is the converged
                                     % baseline value.

%% ======================= INPUTS ========================================
ULF    = msn.ULF;      NSEAT  = msn.NSEAT;    NFLCR  = msn.NFLCR;
AR     = msn.AR;       TR     = msn.TR;       SWEEP  = msn.SWEEP;
TCA    = msn.TCA;      FCOMP  = msn.FCOMP;    FLAPR  = msn.FLAPR;
ARVT   = msn.ARVT;     TCVT   = msn.TCVT;     SWPVT  = msn.SWPVT;
HHT    = msn.HHT;
XL     = msn.XL;       WF     = msn.WFus;     DF     = msn.DFus;
XLP    = msn.XLP;
rho_c  = msn.rho_cr;   dV_ne  = msn.dV_ne;
kWkg_m = msn.kWkg_m;   kWkg_pe = msn.kWkg_pe;
fred   = msn.fred;     kgkW_th = msn.kgkW_th;
NPROP  = msn.NPROP;    NBLADE = msn.NBLADE;   AF     = msn.AF;
whkg   = msn.whkg;     fusable = msn.fusable;
WAV    = msn.WAV;      fmarg  = msn.fmarg;
KELEC  = msn.KELEC;    KFURN  = msn.KFURN;    NELEC  = msn.NELEC;
NEW    = msn.NEW;      Kgear  = msn.Kgear;    dWinst = msn.dWinst;

%% ======================= CONSTANTS =====================================
LB     = 2.20462;      % kilograms to pounds
KT2FPS = 1.688;        % knots to feet per second
RHO_SL = 0.002377;     % sea level density, slug/ft^3
v_cruise = msn.Vkt*KT2FPS;   % cruise true airspeed, ft/s

% FLOPS Table 1 general aviation coefficients. This script only.
A1 = 30;  A2 = 0;  A3 = 0.25;  A4 = 0.5;
A5 = 0.5; A6 = 0.16; A7 = 1.2;
CAYF  = 1;   % single fuselage
PCTL  = 1;   % wing carries all load
FSTRT = 0;   % no strut bracing
FAERT = 0;   % no aeroelastic tailoring
VARSWP = 0;  % no variable sweep

%% ======================= WING WEIGHT ===================================
SPAN  = sqrt(AR*SW);
EM    = 1 - 0.25*FSTRT;                                        % Eq. 11
TLAM  = tand(SWEEP) - 2*(1-TR)/((1+TR)*AR);                    % Eq. 14
SLAM  = TLAM/sqrt(1 + TLAM^2);                                 % Eq. 13
CAYA  = max(AR - 5, 0);                                        % Eq. 17
C6    = 0.5*FAERT - 0.16*FSTRT;
C4    = 1 - 0.5*FAERT;
CAYL  = (1 - SLAM^2)*(1 + C6*SLAM^2 + 0.03*CAYA*C4*SLAM);      % Eq. 12
BT    = 0.215*(0.37 + 0.7*TR)*(SPAN^2/SW)^EM/(CAYL*TCA);       % Eq. 10
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
DAV   = (WF + DF)/2;                                           % Eq. 57
SWFUS = state(st,'SWFUS', pi()*(XL/DAV - 1.7)*DAV^2);          % Eq. 61
WFUSE = 0.052*SWFUS^1.086*(ULF*DG)^0.177*QCRUS^0.241;          % Eq. 60

%% ======================= LANDING GEAR WEIGHT ===========================
WLDG = DG;                          % ELECTRIC: nothing burns off, so the
                                    % aircraft lands at takeoff weight
                                    % (Eq. 65 with RFACT = 0)
XMLG = 0.0625*XL*12*Kgear;                                     % Eq. 66
XNLG = 0.7*XMLG;                                               % Eq. 67
WLGM = 0.0117*WLDG^0.95*XMLG^0.43;                             % Eq. 63
WLGN = 0.0480*WLDG^0.67*XNLG^0.43;                             % Eq. 64

%% ======================= SURFACE CONTROL WEIGHT ========================
v_dive = v_cruise + dV_ne*KT2FPS;
QDIVE  = 0.5*RHO_SL*v_dive^2;       % always sea level                Eq. 100
WSC    = 0.404*SW^0.317*(DG/1000)^0.602*ULF^0.525*QDIVE^0.345; % Eq. 99

%% ======================= PROPULSION WEIGHT =============================
WMOT   = LB*(1 + fred)*PTO_kW/kWkg_m;   % replaces the FLOPS engine equation
WPE    = LB*(1 + fred)*PTO_kW/kWkg_pe;
WTHERM = LB*kgkW_th*PTO_kW;
WBLADE = 3.28e-6*AF^2*Dprop^3;      % Amatt, Bates & Borst, USAAMRDL TR 73-34B
WPROP  = NPROP*NBLADE*WBLADE;       % BLADES ONLY. Scales as D^3, so it says
                                    % many small propellers weigh less than
                                    % one big one. Hubs, spinners, pitch
                                    % mechanisms and mounts are NOT here -
                                    % they are in msn.dWinst.
WBAT   = LB*Ebat/(fusable*whkg/1000);                          % Eq. 96

%% ======================= SYSTEMS WEIGHT ================================
NPASS     = max(NSEAT - NFLCR, 0);
WELEC_raw = 92*XL^0.4*WF^0.14*1^0.27*max(NELEC,1)^0.69 ...
            *(1 + 0.044*NFLCR + 0.0015*NPASS);                 % Eq. 106
                                    % NELEC, not NPROP. The N^0.69 term is
                                    % transport engine-electrical and does
                                    % not describe a high-voltage DC bus.
WELEC     = KELEC*WELEC_raw;
WFURN_raw = 44*NSEAT + 2.6*XLP*(WF + DF);                      % Eq. 110
WFURN     = KFURN*WFURN_raw;

%% ======================= TOTALS ========================================
Wstruct = WWING + WHT + WVT + WFUSE + WLGM + WLGN;             % Eq. 136
Wprop   = WMOT + WPE + WTHERM + WPROP + dWinst;                % Eq. 137
Wsys    = WSC + WAV + WELEC + WFURN;                           % Eq. 138
Wmarg   = fmarg*(Wstruct + Wprop + Wsys);

W.wing        = WWING;   W.htail      = WHT;    W.vtail   = WVT;
W.fuse        = WFUSE;   W.gear       = WLGM + WLGN;
W.structure   = Wstruct;
W.motor       = WMOT;    W.power_elec = WPE;    W.thermal = WTHERM;
W.propeller   = WPROP;   W.install    = dWinst;
W.propulsion  = Wprop;
W.controls    = WSC;     W.avionics   = WAV;
W.electrical  = WELEC;   W.furnishings = WFURN;
W.systems     = Wsys;
W.electrical_raw  = WELEC_raw;   % uncalibrated FLOPS values, kept visible
W.furnishings_raw = WFURN_raw;
W.margin      = Wmarg;
W.battery     = WBAT;
W.empty       = Wstruct + Wprop + Wsys + Wmarg + WBAT;
W.span        = SPAN;    W.BT = BT;  W.qcruise = QCRUS;  W.SWFUS = SWFUS;

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
    fprintf('  Propeller blades            %8.1f lb\n', WPROP);
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
function v = state(s, name, default)
%STATE  Loop-state field with a standalone fallback.
%   Used ONLY for quantities AEGAsize computes. Design inputs are read
%   directly from msn so that a typo is an error, not a silent default.
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = default;
end
end