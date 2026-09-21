function con = AEGAConstraint(msn, CD0, doplot)
%AEGACONSTRAINT  Constraint diagram for the AEGA, 14 CFR Part 22 / ASTM F2245.
%
%   con = AEGAconstraint(msn, CD0, doplot)
%   AEGAconstraint()   runs the baseline, plots and prints
%
%   msn     shared inputs from AEGAinputs(). READ ONLY.
%   CD0     zero-lift drag coefficient. AEGAsize passes its own drag
%           build-up value on every pass; this default is only for
%           standalone runs (baseline build-up value).
%   doplot  true to draw the diagram (default true)
%
%   RETURNS the design point that AEGAsize sizes to:
%     con.WS_design   wing loading, lb/ft^2 = lowest ENFORCED limit line
%     con.PW_hp_lb    governing power loading at WS_design, hp/lb
%     con.PW_kWkg     same, kW/kg. Takeoff SHAFT power per unit MTOW.
%     con.driver      which constraint governs
%
%   THE FILE MUST BE NAMED AEGAconstraint.m. MATLAB resolves a function by
%   its file name, so AE4312Constraint.m could never be called as
%   AEGAconstraint from AEGAsize.
%
%   UNITS: lb, ft, s. Power loading is carried in hp/lb internally and
%   converted to kW/kg on output.

if nargin < 1 || isempty(msn), msn = AEGAinputs(); end
if nargin < 2 || isempty(CD0), CD0 = 0.0218; end
if nargin < 3, doplot = true; end

%% ======================= CONSTANTS =====================================
KT      = 1.68781;       % ft/s per knot
HP      = 550;           % ft*lb/s per hp
HP2KWKG = 1.6440;        % hp/lb to kW/kg

%% ======================= INPUTS ========================================
rho0    = msn.rho_SL;
rho_cr  = msn.rho_cr;
K1      = 1/(pi*msn.AR*msn.e_osw);
eta_cl  = msn.etap_cl;   % CLIMB. HOOK: replace with the actuator-disk
                         %   efficiency at con.V_climb_kt once that code
                         %   runs. AEGAsize has Adisc inside its loop.
eta_cr  = msn.etap_cr;   % CRUISE, and the TURN, which now sits near 110 kt
alpha_P = 1.0;           % electric: no altitude lapse. The lapse that does
                         %   exist is continuous/peak motor rating. Cruise
                         %   sits far below the governing line, so 1.0
                         %   does not change the design point.
beta    = 1.0;           % electric: weight is constant through the mission

%% ======================= MISSION POINTS (this script only) =============
ROC_fpm = 730;     % ft/min at sea level. C172S book value.
k_cl    = 1.3;     % climb speed / clean stall speed VS1. The old fixed
                   %   60 kt put the climb AT the stall speed once VS0
                   %   moved to 60 kt: CL = 2.10 at the design point, with
                   %   a clean CLmax of 1.6. P/W is within about 1 percent
                   %   of its minimum anywhere between 1.15 and 1.3 VS1.
n_turn  = 1.5;     % sustained level turn, about 48 deg bank
k_tn    = 1.3;     % turn speed / stall speed IN the turn, VS1*sqrt(n).
                   %   The old fixed 65 kt gave CL = 2.68 at the design point.

% TAKEOFF AND LANDING: Roskam, Airplane Design Part I, FAR 23 correlations.
%   takeoff  S_TOG = 4.9*TOP + 0.009*TOP^2,   S_TO = 1.66*S_TOG
%            TOP   = (W/S)*(W/P)/(sigma*CLmax_TO),  lb^2/(ft^2*hp)
%   landing  S_L   = 0.5136*VS0^2,  VS0 in KCAS  (1.938 x 0.265)
% Both distances are OVER A 50 FT OBSTACLE, which is what msn.S_field is.
% They replace TOP_div = 3.8, which had no source. For a C172S (14.7 psf,
% 14.2 lb/hp, CLmax_TO 1.5 assumed) it predicts 526 ft over 50 ft; the POH
% says about 1630 ft and Roskam gives 1413 ft.
sigma = 1.0;               % sea level ISA
S_TO  = msn.S_field;       % ft, takeoff over 50 ft
S_L   = msn.S_field;       % ft, landing over 50 ft, same field

W_S = linspace(4, 30, 261);    % lb/ft^2, plotting grid only

%% ======================= WING LOADING LIMITS (vertical lines) ==========
% 1. Light-sport CERTIFICATION: VS0 <= 61 KCAS, landing configuration, idle
%    power (MOSAIC, 14 CFR Part 22). The team designs to 60. Always enforced.
lim.VS0  = 0.5*rho0*(msn.VS0*KT)^2*msn.CLmax_L;
% 2. Sport-pilot OPERATION: VS1 <= 59 KCAS, clean (14 CFR 61.316). Not a
%    certification limit. Enforce only if the trainer must be flyable by
%    sport pilots.
lim.VS1  = 0.5*rho0*(msn.VS1_op*KT)^2*msn.CLmax_clean;
% 3. Landing distance over 50 ft, wheel brakes only.
VSL_max  = sqrt(S_L/0.5136);                               % KCAS
lim.land = 0.5*rho0*(VSL_max*KT)^2*msn.CLmax_L;

WS_design = lim.VS0;   set_by = 'VS0 certification';
if msn.enforce_VS1  && lim.VS1  < WS_design
    WS_design = lim.VS1;   set_by = 'VS1 sport pilot';
end
if msn.enforce_land && lim.land < WS_design
    WS_design = lim.land;  set_by = 'landing distance';
end

%% ======================= POWER LOADING CONSTRAINTS =====================
% Mattingly, beta = alpha = 1:
%   P/W = [ V*( q*CD0/(W/S) + K1*n^2*(W/S)/q ) + dh/dt ] / (eta*550)
% Climb and turn speeds scale with VS1, so each is flown at a FIXED CL
% across the whole diagram instead of a fixed speed.
PW = @(WS, V, n, dhdt, eta, rho) (beta/(eta*alpha_P)) * ...
     ( V.*( 0.5*rho*V.^2*CD0./(beta*WS) + K1*n^2*beta*WS./(0.5*rho*V.^2) ) ...
       + dhdt )/HP;

VS1  = @(WS) sqrt(2*WS/(rho0*msn.CLmax_clean));       % clean stall, ft/s
V_cr = msn.Vkt*KT;                                     % TRUE airspeed, ft/s
TOP  = (-4.9 + sqrt(4.9^2 + 4*0.009*S_TO/1.66))/(2*0.009);

f.cruise  = @(WS) PW(WS, V_cr, 1, 0, eta_cr, rho_cr);
f.climb   = @(WS) PW(WS, k_cl*VS1(WS), 1, ROC_fpm/60, eta_cl, rho0);
f.turn    = @(WS) PW(WS, k_tn*sqrt(n_turn)*VS1(WS), n_turn, 0, eta_cr, rho0);
f.takeoff = @(WS) WS/(sigma*msn.CLmax_TO*TOP);

names  = {'cruise','climb','turn','takeoff'};
curves = zeros(numel(names), numel(W_S));
atD    = zeros(numel(names), 1);
for k = 1:numel(names)
    fh          = f.(names{k});
    curves(k,:) = fh(W_S);
    atD(k)      = fh(WS_design);   % exact W/S, not the nearest grid point
end
[PW_req, kmax] = max(atD);
PW_margin = 1.02;  % 2% power margin 
PW_req    = PW_req * PW_margin;

WS_margin = 0.98; % 2% buffer on maximum wing loading
WS_design = lim.VS0 * WS_margin;   set_by = 'VS0 certification (92% max)';
%% ======================= RESULTS =======================================
con.WS_design  = WS_design;
con.set_by     = set_by;
con.limits     = lim;
con.PW_hp_lb   = PW_req;
con.PW_kWkg    = PW_req*HP2KWKG;
con.driver     = names{kmax};
for k = 1:numel(names)
    con.PW_at_design.(names{k}) = atD(k);
end
con.V_climb_kt = k_cl*VS1(WS_design)/KT;
con.CL_climb   = msn.CLmax_clean/k_cl^2;
con.V_turn_kt  = k_tn*sqrt(n_turn)*VS1(WS_design)/KT;
con.CL_turn    = msn.CLmax_clean/k_tn^2;
con.TOP        = TOP;
con.VS0_kt     = sqrt(2*WS_design/(rho0*msn.CLmax_L))/KT;
con.VS1_kt     = VS1(WS_design)/KT;
con.S_land_ft  = 0.5136*con.VS0_kt^2;
con.W_S        = W_S;
con.PW_cruise  = curves(1,:);
con.PW_climb   = curves(2,:);
con.PW_turn    = curves(3,:);
con.PW_takeoff = curves(4,:);
con.CD0        = CD0;
con.msn        = msn;

% limits that are checked but not enforced
viol = {};
if WS_design > lim.VS1*(1 + 1e-9)
    viol{end+1} = sprintf('VS1 clean = %.1f kt, sport-pilot limit %d KCAS', ...
                          con.VS1_kt, msn.VS1_op);
end
if WS_design > lim.land*(1 + 1e-9)
    viol{end+1} = sprintf('landing = %.0f ft over 50 ft, field %d ft', ...
                          con.S_land_ft, S_L);
end
con.violations = viol;

%% ======================= PLOT ==========================================
if doplot
    yl = [0 0.15];
    figure('Color',[1 1 1],'Position',[100 100 800 600]);
    hold on; grid on; box on;
    plot(W_S, con.PW_cruise,  'b-',  'LineWidth',2, 'DisplayName', ...
         sprintf('Cruise (%d kt @ %d ft)', msn.Vkt, msn.h_cr));
    plot(W_S, con.PW_climb,   'r-',  'LineWidth',2, 'DisplayName', ...
         sprintf('Climb (%d ft/min @ %.1f x clean stall)', ROC_fpm, k_cl));
    plot(W_S, con.PW_turn,    'm--', 'LineWidth',2, 'DisplayName', ...
         sprintf('Level turn (%.1fg @ %.1f x turn stall)', n_turn, k_tn));
    plot(W_S, con.PW_takeoff, 'g-.', 'LineWidth',2, 'DisplayName', ...
         sprintf('Takeoff (%d ft over 50 ft)', S_TO));
    plot(lim.VS0*[1 1],  yl, 'k-',  'LineWidth',2, 'DisplayName', ...
         sprintf('VS0 %d KCAS, certification (%.1f psf)', msn.VS0, lim.VS0));
    % plot(lim.VS1*[1 1],  yl, 'k:',  'LineWidth',2, 'DisplayName', ...
    %      sprintf('VS1 %d KCAS, sport pilot (%.1f psf)', msn.VS1_op, lim.VS1));
    plot(lim.land*[1 1], yl, 'k--', 'LineWidth',2, 'DisplayName', ...
         sprintf('Landing %d ft over 50 ft (%.1f psf)', S_L, lim.land));
    plot(WS_design, PW_req, 'ko', 'MarkerSize',10, ...
         'MarkerFaceColor','y', 'DisplayName','Design point');
    xlabel('Wing loading, W/S (lb/ft^2)','FontSize',12,'FontWeight','bold');
    ylabel('Power loading, P/W (hp/lb)','FontSize',12,'FontWeight','bold');
    title('AEGA constraint diagram, 14 CFR Part 22', ...
          'FontSize',14,'FontWeight','bold');
    axis([4 30 yl]);
    lg = legend('Location','northwest');
    set(lg, 'FontSize', 9);
end

%% ======================= PRINTOUT ======================================
if nargout == 0
    on = {'check only','ENFORCED'};
    fprintf('\n  CONSTRAINT RESULT   (CD0 = %.4f)\n', CD0);
    fprintf('  ------------------------------------------------------\n');
    fprintf('  Wing loading limits, lb/ft^2\n');
    fprintf('    VS0 %2d KCAS, landing config    %7.2f   ENFORCED\n', ...
            msn.VS0, lim.VS0);
    fprintf('    VS1 %2d KCAS, clean             %7.2f   %s\n', ...
            msn.VS1_op, lim.VS1, on{1 + msn.enforce_VS1});
    fprintf('    Landing %4d ft over 50 ft     %7.2f   %s\n', ...
            S_L, lim.land, on{1 + msn.enforce_land});
    fprintf('  Design wing loading              %7.2f   (%s)\n', ...
            WS_design, set_by);
    fprintf('  Power loading at design point, hp/lb\n');
    fprintf('    cruise                          %7.4f\n', atD(1));
    fprintf('    climb   %3.0f kt, CL %.2f        %7.4f\n', ...
            con.V_climb_kt, con.CL_climb, atD(2));
    fprintf('    turn    %3.0f kt, CL %.2f        %7.4f\n', ...
            con.V_turn_kt, con.CL_turn, atD(3));
    fprintf('    takeoff TOP %5.1f              %7.4f\n', TOP, atD(4));
    fprintf('  Required                         %7.4f hp/lb = %.4f kW/kg\n', ...
            con.PW_hp_lb, con.PW_kWkg);
    fprintf('  Governing constraint             %s\n', con.driver);
    for k = 1:numel(viol)
        fprintf('  *** exceeds %s ***\n', viol{k});
    end
    fprintf('\n');
    clear con
end
end