function con = AEGAconstraint(msn, CD0, doplot)
%AEGACONSTRAINT  Constraint diagram for the AEGA, 14 CFR Part 22 / ASTM F2245.
%
%   con = AEGAconstraint(msn, CD0, doplot)
%   AEGAconstraint()   runs the baseline and plots
%
%   msn     shared inputs from AEGAinputs(). READ ONLY.
%   CD0     zero-lift drag coefficient. Pass out.CD0 from AEGAsize. The old
%           hardcoded 0.0341 was 42 percent above what the drag build-up
%           returns and made every power curve too high.
%   doplot  true to draw the diagram (default true)
%
%   RETURNS con.PW_kWkg, the governing takeoff power loading at the design
%   wing loading. That is the number meant to replace the hardcoded 0.176
%   in AEGAsize.
%
%   UNITS: lb, ft, s. Power-to-weight is carried internally in horsepower
%   per pound and converted to kilowatts per kilogram on output.

if nargin < 1 || isempty(msn), msn = AEGAinputs(); end
if nargin < 2 || isempty(CD0), CD0 = 0.024; end   % from the drag build-up
if nargin < 3, doplot = true; end

%% ======================= INPUTS ========================================
g0     = msn.g0;
rho0   = msn.rho_SL;
rho_cr = msn.rho_cr;
AR     = msn.AR;
e      = msn.e_osw;              % was 0.70 here and 0.80 in AEGAsize
K1     = 1/(pi*AR*e);
CL_max_TO = msn.CLmax_TO;
CL_max_L  = msn.CLmax_L;
eta_cl = msn.etap_cl;            % CLIMB and TAKEOFF. A propeller optimised
                                 % for 120 kt does not hold cruise efficiency
                                 % at 60 kt. Using one value for every
                                 % condition returned 0.085 kW/kg, below both
                                 % the Velis Electro and the Cessna 172S.
eta_cr = msn.etap_cr;            % CRUISE and TURN
V_cr   = msn.Vkt*1.68781;
V_S0   = msn.VS0*1.68781;

%% ======================= MISSION POINTS ================================
% This script only. Not shared design inputs.
ROC_fpm  = 730;      % ft/min climb target
V_cl_kts = 60;       % best-climb speed, kt
n_turn   = 1.5;      % load factor, about 48 deg bank
V_tn_kts = 65;       % manoeuvre speed, kt
S_TO     = msn.S_field;   % ft. NOTE: the requirement is 1500 ft OVER A
                          % 50 FT OBSTACLE, but the takeoff parameter
                          % correlation below is a GROUND ROLL fit. These
                          % are not the same distance. Resolve before use.
TOP_div  = 3.8;      % empirical takeoff parameter divisor. NO SOURCE.

alpha_P = 1.0;       % electric: no power lapse with altitude at these heights
beta    = 1.0;       % electric: weight is constant through the mission
HP      = 550;       % foot-pounds per second per horsepower
HP2KWKG = 1.6440;    % horsepower per pound to kilowatts per kilogram

W_S = linspace(4, 30, 200);

%% ======================= CONSTRAINTS ===================================
% Mattingly power-to-weight, divided by 550 to give horsepower per pound:
%   P/W = (beta/(eta_p*alpha_P)) * V * [ (q/(beta*W_S))*CD0
%                                        + K1*(n*beta*W_S/q)^2/(W_S/q)
%                                        + (1/V)*dh/dt ] / 550

% --- 1. Stall. 14 CFR Part 22 / MOSAIC: VS0 <= 61 KCAS. The team uses 60.
%        NOT 45 kt: that is the pre-MOSAIC light-sport definition and it
%        puts this boundary 44 percent too far left.
WS_stall = 0.5*rho0*V_S0^2*CL_max_L;

% --- 2. Cruise, at altitude
q_cr = 0.5*rho_cr*V_cr^2;
PW_cruise = (beta/(eta_cr*alpha_P)).*V_cr.*((q_cr./(beta.*W_S)).*CD0 ...
            + K1.*((beta.*W_S)./q_cr))/HP;

% --- 3. Rate of climb, sea level
dh_dt   = ROC_fpm/60;
V_climb = V_cl_kts*1.68781;
q_climb = 0.5*rho0*V_climb^2;
PW_climb = (beta/(eta_cl*alpha_P)).*(V_climb.*((q_climb./(beta.*W_S)).*CD0 ...
           + K1.*((beta.*W_S)./q_climb)) + dh_dt)/HP;

% --- 4. Level turn, sea level
V_turn = V_tn_kts*1.68781;
q_turn = 0.5*rho0*V_turn^2;
PW_turn = (beta/(eta_cr*alpha_P)).*V_turn.*((q_turn./(beta.*W_S)).*CD0 ...
          + K1.*((n_turn.*beta.*W_S./q_turn).^2)./(W_S./q_turn))/HP;

% --- 5. Takeoff
TOP = S_TO/TOP_div;
PW_takeoff = W_S./(TOP*CL_max_TO*1.0);

%% ======================= DESIGN POINT ==================================
PW_req = max([PW_cruise; PW_climb; PW_turn; PW_takeoff], [], 1);
[~, iD] = min(abs(W_S - WS_stall));      % design sits at the stall boundary
con.WS_design  = WS_stall;
con.PW_hp_lb   = PW_req(iD);
con.PW_kWkg    = con.PW_hp_lb*HP2KWKG;
con.driver     = driverName(PW_cruise(iD), PW_climb(iD), PW_turn(iD), ...
                            PW_takeoff(iD));
con.W_S        = W_S;
con.PW_cruise  = PW_cruise;
con.PW_climb   = PW_climb;
con.PW_turn    = PW_turn;
con.PW_takeoff = PW_takeoff;
con.CD0        = CD0;
con.msn        = msn;

%% ======================= PLOT ==========================================
if doplot
    figure('Color',[1 1 1],'Position',[100 100 800 600]);
    hold on; grid on; box on;
    plot(W_S, PW_cruise,  'b-',  'LineWidth',2, 'DisplayName', ...
         sprintf('Cruise (%d kt @ %d ft)', msn.Vkt, msn.h_cr));
    plot(W_S, PW_climb,   'r-',  'LineWidth',2, 'DisplayName', ...
         sprintf('Climb (%d ft/min @ %d kt)', ROC_fpm, V_cl_kts));
    plot(W_S, PW_turn,    'm--', 'LineWidth',2, 'DisplayName', ...
         sprintf('Level turn (%.1fg @ %d kt)', n_turn, V_tn_kts));
    plot(W_S, PW_takeoff, 'g-.', 'LineWidth',2, 'DisplayName', ...
         sprintf('Takeoff (%d ft)', S_TO));
    xline(WS_stall, 'k--', 'LineWidth',2, 'DisplayName', ...
          sprintf('Stall, VS0 = %d KCAS (%.1f psf)', msn.VS0, WS_stall));
    plot(con.WS_design, con.PW_hp_lb, 'ko', 'MarkerSize',10, ...
         'MarkerFaceColor','y', 'DisplayName','Design point');
    xlabel('Wing loading, W/S (lb/ft^2)','FontSize',12,'FontWeight','bold');
    ylabel('Power loading, P/W (hp/lb)','FontSize',12,'FontWeight','bold');
    title('AEGA constraint diagram, 14 CFR Part 22', ...
          'FontSize',14,'FontWeight','bold');
    axis([4 30 0 0.15]);
    legend('Location','northwest','FontSize',10);
end

if nargout == 0
    fprintf('\n  CONSTRAINT RESULT\n');
    fprintf('  ------------------------------------------\n');
    fprintf('  Design wing loading       %8.2f lb/ft^2\n', con.WS_design);
    fprintf('  Required power loading    %8.4f hp/lb\n',  con.PW_hp_lb);
    fprintf('                            %8.4f kW/kg\n',  con.PW_kWkg);
    fprintf('  Governing constraint      %8s\n',          con.driver);
    fprintf('  (AEGAsize currently hardcodes 0.176 kW/kg)\n\n');
    clear con
end
end

%% ========================================================================
function s = driverName(c, cl, t, to)
[~, k] = max([c, cl, t, to]);
names = {'cruise','climb','turn','takeoff'};
s = names{k};
end