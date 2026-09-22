function out = AEGAsize(msn)
%AEGASIZE  Close the weight and sizing loop for a battery-electric trainer.
%
%   out = AEGAsize(msn)   sizes one design
%   AEGAsize()            sizes the baseline and prints the result
%
%   msn is the shared input struct from AEGAinputs(). READ ONLY: loop results
%   go into the local struct `st`, which is what AEGAweight receives. The old
%   pattern of copying msn and writing DG/SW/PTO into the copy is what made
%   msn.WF and msn.SWFUS silently ignored.
%
%   The cfg argument is gone. Its propulsor-trade knobs (ing, dist, wrec,
%   Kfus, KHT, KVT, dS, FFc, oth) served a study that is now closed; git has
%   them if the boundary-layer-ingestion case has to be reopened. dWinst,
%   Kgear, HHT and NEW moved into msn.
%
%   UNITS: weight lb | length ft | area ft^2 | speed ft/s unless noted

if nargin < 1 || isempty(msn), msn = AEGAinputs(); end

%% ======================= INPUTS ========================================
payload = msn.payload;  range = msn.range;  reserve = msn.reserve;
Vkt     = msn.Vkt;      VS0   = msn.VS0;    ovh     = msn.ovh;
rho_SL  = msn.rho_SL;   rho_cr = msn.rho_cr;  nu = msn.nu_cr;
AR      = msn.AR;       TR    = msn.TR;     e_osw   = msn.e_osw;
Vh = msn.Vh;  Vv = msn.Vv;  Lh = msn.Lh;  Lv = msn.Lv;
XL = msn.XL;  WFus = msn.WFus;  DFus = msn.DFus;
SMISC = msn.SMISC;  SCOV = msn.SCOV;  WETR = msn.WETR;
Cf_w = msn.Cf_w;  FF_w = msn.FF_w;
Cf_t = msn.Cf_t;  FF_t = msn.FF_t;
Cf_m = msn.Cf_m;  FF_m = msn.FF_m;
excr = msn.excr;
eta_m = msn.eta_m;  eta_pe = msn.eta_pe;  prof = msn.prof;
NPROP = msn.NPROP;
whkg = msn.whkg;    fusable = msn.fusable;

%% ======================= ITERATION CONTROL =============================
% This script only. Not design inputs.
DG    = 2050;   % first guess, lb
NMAX  = 12;     % outer iteration cap
TOL   = 0.5;    % convergence tolerance, lb

%% ======================= CONSTANTS =====================================
KT2FPS = 1.688;      % knots to feet per second
NM2FT  = 6076.12;    % nautical miles to feet
FTLB   = 2.6552e6;   % foot-pounds per kilowatt-hour
LB     = 2.20462;    % kilograms to pounds
W2KW   = 737.56;     % foot-pounds per second per kilowatt

%% ======================= FIXED FOR THE WHOLE RUN =======================
% CRUISE IS AT ALTITUDE. rho_cr, not rho_SL. The stall/wing-loading
% calculation below is the only place sea level belongs, because VS0 is
% certified at sea level standard day.
V   = Vkt*KT2FPS;
q   = 0.5*rho_cr*V^2;                       % cruise dynamic pressure, lb/ft^2
Req = (range + reserve/60*Vkt)*NM2FT;       % equivalent still-air distance, ft

% Design wing loading comes from the constraint diagram. It depends only on
% the stall and field-length inputs, not on CD0, so it is fixed for the run.
con   = AEGAconstraint(msn, [], false);
WSR   = con.WS_design;
CLmax = msn.CLmax_L;                        % carried for the printout only
DAV      = (WFus + DFus)/2;                                   % Eq. 57
SWFUS    = pi()*(XL/DAV - 1.7)*DAV^2;                         % Eq. 61
Ref      = V*XL/nu;                         % fuselage Reynolds number
Cf_f     = 0.455/log10(Ref)^2.58;           % Prandtl-Schlichting flat plate
fineness = XL/DAV;
FF_f     = 1 + 60/fineness^3 + fineness/400;
f_fus    = Cf_f*FF_f*SWFUS*excr;            % fuselage drag area, ft^2
f_msc    = Cf_m*FF_m*SMISC*excr;

hist = zeros(NMAX,2);

%% ======================= SIZING LOOP ===================================
for i = 1:NMAX

    % ---- maximum lift coefficient -------------------------------------
    % An INPUT, not a computed result. blow_wind is a check on the
    % converged design, not a driver: closing CLmax against wing area has
    % no fixed point (smaller wing -> smaller span -> smaller propellers ->
    % higher disc loading -> higher slipstream velocity -> smaller wing).

    % ---- geometry follows from the current weight guess ----------------
    SW   = DG/WSR;
    SPAN = sqrt(AR*SW);
    cr   = 2*SW/(SPAN*(1+TR));                       % root chord
    MAC  = (2/3)*cr*(1 + TR + TR^2)/(1+TR);          % mean aerodynamic chord
    SHT  = Vh*MAC*SW/Lh;
    SVT  = Vv*SPAN*SW/Lv;

    % ---- drag build-up -------------------------------------------------
    f_wing = Cf_w*FF_w*WETR*(SW - SCOV)*excr;
    f_tail = Cf_t*FF_t*WETR*(SHT + SVT)*excr;
    f      = f_wing + f_tail + f_fus + f_msc;
    CD0    = f/SW;

    % propeller geometry follows the span, it is not an input
    [Dprop, Adisc] = AEGAprop(msn, SW);

    % ---- installed power from the constraint diagram, at this CD0 ------
    % P/W depends on W/S, CD0, K and efficiencies, not on DG, so this is a
    % closed-form call, not a nested loop.
    con  = AEGAconstraint(msn, CD0, false);
    PTO  = con.PW_kWkg*DG/LB;                        % takeoff shaft power, kW

    % if msn.use_blown_wind
    %     WSR = 0.5*rho_SL*(VS0*KT2FPS)^2*msn.CLmax_L;
    %     for k = 1:20
    %         SW   = DG/WSR;             SPAN = sqrt(AR*SW);
    %         cr   = 2*SW/(SPAN*(1+TR)); MAC  = (2/3)*cr*(1+TR+TR^2)/(1+TR);
    %         SHT  = Vh*MAC*SW/Lh;   SVT  = Vv*SPAN*SW/Lv;
    %         % ---- drag build-up -------------------------------------------------
    %         f_wing = Cf_w*FF_w*WETR*(SW - SCOV)*excr;
    %         f_tail = Cf_t*FF_t*WETR*(SHT + SVT)*excr;
    %         CD0    = (f_wing + f_tail + f_fus + f_msc)/SW;
    %         msn.SW = SW;  msn.SPAN = SPAN;  msn.CD0 = CD0;
    %         CLmax_blown = blow_wind(msn, VS0, 'landing');
    %         WSRnew = 0.5*rho_SL*(VS0*KT2FPS)^2*CLmax_blown;
    %         if abs(WSRnew - WSR) < 1e-3, break; end
    %         WSR = WSRnew;
    %     end
    % end

    if msn.use_blown_wind
        WSR = 0.5*rho_SL*(VS0*KT2FPS)^2*msn.CLmax_L;
        for k = 1:20
            SW   = DG/WSR;             SPAN = sqrt(AR*SW);
            cr   = 2*SW/(SPAN*(1+TR)); MAC  = (2/3)*cr*(1+TR+TR^2)/(1+TR);
            SHT  = Vh*MAC*SW/Lh;   SVT  = Vv*SPAN*SW/Lv;
            % ---- drag build-up -------------------------------------------------
            f_wing = Cf_w*FF_w*WETR*(SW - SCOV)*excr;
            f_tail = Cf_t*FF_t*WETR*(SHT + SVT)*excr;
            CD0    = (f_wing + f_tail + f_fus + f_msc)/SW;
            msn.SW = SW;  msn.SPAN = SPAN;  msn.CD0 = CD0;
            CLmax_blown = blow_wind(msn, VS0, 'landing');
            WSRnew = 0.5*rho_SL*(VS0*KT2FPS)^2*CLmax_blown;
            if abs(WSRnew - WSR) < 1e-3, break; end
            WSR = WSRnew;
        end
        if k == 20, warning('AEGAsize:blown', 'blown W/S did not converge'); end
        [Dprop, Adisc] = AEGAprop(msn, SW);             % props on the blown wing
        con = AEGAconstraint(msn, CD0, false);     % power at blown W/S, CD0
        PTO = con.PW_kWkg*DG/LB;
    end


    CL     = WSR/q;
    CDi    = CL^2/(pi*AR*e_osw);
    LD     = CL/(CD0 + CDi);

    D      = DG/LD;                                  % cruise drag = thrust
    % ---- propulsive efficiency from disc loading -----------------------
    CT   = D/(q*Adisc);
    etap = 2/(1 + sqrt(1 + CT))*prof;
    eta  = eta_m*eta_pe*etap;

    % ---- mission energy and battery ------------------------------------
    Ebat = D*Req/eta*(1 + ovh)/FTLB;                 % kWh usable

    % ---- component weights ---------------------------------------------
    st = struct('DG', DG, 'SW', SW, 'SHT', SHT, 'SVT', SVT, ...
                'PTO_kW', PTO, 'Ebat', Ebat, 'SWFUS', SWFUS, ...
                'Dprop', Dprop);
    W = AEGAweight(msn, st);

    DGout = W.empty + payload;
    hist(i,:) = [DG, DGout];
    if abs(DGout - DG) < TOL, break; end

    if i == 1
        DG = DGout;                                  % plain fixed-point step
    else                                             % secant step thereafter
        r1 = hist(i,1)   - hist(i,2);
        r0 = hist(i-1,1) - hist(i-1,2);
        DG = hist(i,1) - r1*(hist(i,1) - hist(i-1,1))/(r1 - r0);
    end
end

%% ======================= RESULTS =======================================
out.MTOW       = DGout;
out.W          = W;
out.SW         = SW;
out.span       = SPAN;
out.MAC        = MAC;
out.SHT        = SHT;
out.SVT        = SVT;
out.WSR        = WSR;
out.CLmax      = CLmax;
out.CD0        = CD0;
out.LD         = LD;
out.drag       = D;
out.eta_prop   = etap;
out.eta_total  = eta;
out.Ebat       = Ebat;
out.pack_kWh   = Ebat/fusable;
out.PTO_kW     = PTO;
out.Pcruise_kW = D*V/eta/W2KW;
out.con        = con;
% ---- sport-pilot operating check -------------------------------------
% Part 22 certifies on VS0 in the LANDING configuration. Sport-pilot
% OPERATION (14 CFR 61.316) is a separate test on VS1, CLEAN. Nothing used
% to check the second one.
out.VS1        = sqrt(2*WSR/(msn.rho_SL*msn.CLmax_clean))/1.688;
out.VS1_ok     = out.VS1 <= msn.VS1_op;
out.CLclean_req = WSR/(0.5*msn.rho_SL*(msn.VS1_op*1.688)^2);
out.Dprop      = Dprop;
out.Adisc      = Adisc;
out.iterations = i;
out.history    = hist(1:i,:);
out.converged  = abs(hist(i,2) - hist(i,1)) < TOL;
out.msn        = msn;    % the inputs travel with the answer. save('run.mat',
                         % 'out') now reproduces this result exactly.

%% ======================= PRINTOUT ======================================
if nargout == 0
    fprintf('\n  SIZING RESULT   (%d passes, converged = %d)\n', i, out.converged);
    fprintf('  ------------------------------------------\n');
    fprintf('  Maximum takeoff weight    %8.0f lb\n', out.MTOW);
    fprintf('  Empty weight              %8.0f lb\n', W.empty);
    fprintf('  Battery                   %8.0f lb\n', W.battery);
    fprintf('  Pack energy               %8.1f kWh\n', out.pack_kWh);
    fprintf('  CLmax (landing)           %8.3f\n', CLmax);
    fprintf('  Wing area                 %8.2f ft^2\n', SW);
    fprintf('  Span                      %8.2f ft\n', SPAN);
    fprintf('  Wing loading              %8.2f lb/ft^2\n', WSR);
    fprintf('  CD0                       %8.4f\n', CD0);
    fprintf('  Cruise L/D                %8.2f\n', LD);
    fprintf('  Propeller efficiency      %8.3f\n', etap);
    fprintf('  Takeoff power             %8.0f kW\n', PTO);
    fprintf('  Power loading             %8.4f kW/kg (%s governs)\n', con.PW_kWkg, con.driver);
    fprintf('  Cruise power              %8.1f kW\n', out.Pcruise_kW);
    fprintf('  Propeller diameter        %8.2f ft\n', Dprop);
    fprintf('  VS1 clean                 %8.1f kt  (61.316 limit %d)\n', ...
            out.VS1, msn.VS1_op);
    if ~out.VS1_ok
        fprintf(['  *** FAILS sport-pilot operating limit. Needs ' ...
                 'CLmax clean %.2f, or W/S below %.1f lb/ft^2 ***\n'], ...
                out.CLclean_req, ...
                0.5*msn.rho_SL*(msn.VS1_op*1.688)^2*msn.CLmax_clean);
    end
    fprintf('\n');
    clear out
end
end