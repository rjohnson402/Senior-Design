%% LIGHT-SPORT AIRCRAFT (LSA - ASTM F2245) CONSTRAINT DIAGRAM SCRIPT
% Units: Imperial (lb, ft, s, hp)
clear; clc; close all;

%% ========================================================================
% 1. AIRCRAFT & ENVIRONMENTAL PARAMETERS (LSA ASSUMPTIONS)
% ========================================================================
g0 = 32.174;                % Acceleration due to gravity (ft/s^2)
rho0 = 0.002377;            % Sea-level air density (slugs/ft^3)

% Aerodynamic Parameters (ASTM F2245 LSA Trainer)
AR = 8.5;                   % Aspect ratio (typical high-efficiency LSA wing)
e = 0.78;                   % Oswald efficiency factor
K1 = 1 / (pi * AR * e);     % Induced drag factor [Formula: K = 1 / (pi * AR * e)]
CD0 = 0.030;                % Zero-lift drag coefficient (strut-braced/fixed gear)
CL_max = 1.5;               % Max lift coefficient (clean)
CL_max_TO = 1.7;            % Max lift coefficient (takeoff configuration)
CL_max_L = 1.9;             % Max lift coefficient (landing configuration)

% Propulsion & Weight Parameters
eta_p = 0.72;               % Propeller efficiency (fixed pitch / slow speed optimized)
alpha_P = 1.0;              % Electric motor power lapse rate (constant power at low alt)
beta = 1.0;                 % Weight fraction W/W_TO (Electric: constant weight across mission)

% Design Space Vector (Wing Loading range in lb/ft^2 for LSA focus)
W_S = linspace(4, 25, 100); 

%% ========================================================================
% 2. CONSTRAINT CALCULATIONS (Power-to-Weight in hp/lb)
% ========================================================================
% Note: Mattingly Power-to-Weight Formula (ft-lb/s per lb):
% P_SL/W_TO = (beta / (eta_p * alpha_P)) * V * { (q*S / (beta*W_TO)) * [CD0 + K1*(n*beta*W_TO / (q*S))^2] + (1/V)*(dh/dt) + (1/g0)*(dV/dt) }
% Divided by 550 to convert ft-lb/(s*lb) to Shaft Horsepower per lb (hp/lb).

% --- CONSTRAINT 1: LSA Stall Speed Limit (ASTM F2245 max stall limit = 45 kts / 75.95 ft/s) ---
V_stall = 45 * 1.68781;     % Stall speed limit: 45 knots converted to ft/s
% Formula: W/S_max = 0.5 * rho0 * V_stall^2 * CL_max_L
WS_stall_limit = 0.5 * rho0 * (V_stall^2) * CL_max_L; 

% --- CONSTRAINT 2: LSA Cruise Velocity ---
V_cruise_kts = 95;                      % Target LSA cruise speed in knots
V_cr = V_cruise_kts * 1.68781;          % Convert to ft/s
h_cr = 2000;                            % Cruise altitude (ft)
[~, ~, ~, rho_cr] = atmospheric_props(h_cr);
q_cr = 0.5 * rho_cr * V_cr^2;           % Dynamic pressure [Formula: q = 0.5 * rho * V^2]

% Formula: (P/W)_cruise = (beta / (eta_p * alpha_P)) * V_cr * [ (q_cr / (beta * W_S)) * CD0 + K1 * (beta * W_S / q_cr) ] / 550
PW_cruise = (beta / (eta_p * alpha_P)) .* V_cr .* ((q_cr ./ (beta .* W_S)) .* CD0 + K1 .* ((beta .* W_S) ./ q_cr)) / 550;

% --- CONSTRAINT 3: Rate of Climb (ROC) ---
ROC_fpm = 650;                          % Target rate of climb for LSA (ft/min)
dh_dt = ROC_fpm / 60;                   % Convert to ft/s
V_climb = 60 * 1.68781;                 % Climb speed: 60 knots in ft/s
q_climb = 0.5 * rho0 * V_climb^2;       % Dynamic pressure at sea level

% Formula: (P/W)_climb = (beta / (eta_p * alpha_P)) * [ V_climb * ((q_climb / (beta * W_S))*CD0 + K1*(beta*W_S / q_climb)) + dh_dt ] / 550
PW_climb = (beta / (eta_p * alpha_P)) .* (V_climb .* ((q_climb ./ (beta .* W_S)) .* CD0 + K1 .* ((beta .* W_S) ./ q_climb)) + dh_dt) / 550;

% --- CONSTRAINT 4: Level Co-Altitude Turn (1.5g LSA Moderate Turn) ---
n_turn = 1.5;                           % Load factor (~48 deg bank angle)
V_turn = 65 * 1.68781;                  % Maneuver speed: 65 knots in ft/s
q_turn = 0.5 * rho0 * V_turn^2;         % Dynamic pressure

% Formula: (P/W)_turn = (beta / (eta_p * alpha_P)) * V_turn * [ (q_turn / (beta * W_S))*CD0 + K1*(n_turn*beta*W_S / q_turn)^2 / (W_S / q_turn) ] / 550
PW_turn = (beta / (eta_p * alpha_P)) .* V_turn .* ((q_turn ./ (beta .* W_S)) .* CD0 + K1 .* ((n_turn .* beta .* W_S ./ q_turn).^2) ./ (W_S ./ q_turn)) / 550;

% --- CONSTRAINT 5: LSA Takeoff Ground Roll / Field Length ---
S_TO = 1000;                            % Target takeoff distance (ft)
sigma_TO = 1.0;                         % Sea level density ratio
% Empirical LSA Takeoff Parameter: TOP_LSA = S_TO / 3.8
TOP_LSA = S_TO / 3.8;                     
% Formula: (P/W)_takeoff = (W_S) / (TOP_LSA * CL_max_TO * sigma_TO)
PW_takeoff = W_S ./ (TOP_LSA * CL_max_TO * sigma_TO);

%% ========================================================================
% 3. PLOTTING THE CONSTRAINT DIAGRAM
% ========================================================================
figure('Color', [1 1 1], 'Position', [100 100 800 600]);
hold on; grid on; box on;

% Plot Constraint Curves
plot(W_S, PW_cruise, 'b-', 'LineWidth', 2, 'DisplayName', 'Cruise (95 kts @ 2,000 ft)');
plot(W_S, PW_climb, 'r-', 'LineWidth', 2, 'DisplayName', 'Climb Rate (650 ft/min)');
plot(W_S, PW_turn, 'm--', 'LineWidth', 2, 'DisplayName', 'Level Turn (1.5g @ 65 kts)');
plot(W_S, PW_takeoff, 'g-.', 'LineWidth', 2, 'DisplayName', 'Takeoff Distance (1,000 ft)');

% Plot Stall Boundary Line
xline(WS_stall_limit, 'k--', 'LineWidth', 2, 'DisplayName', sprintf('LSA Stall Limit (%.1f psf)', WS_stall_limit));

% Axis Labels and Formatting
xlabel('Wing Loading, W_{TO}/S (lb/ft^2)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Power-to-Weight Ratio, P_{SL}/W_{TO} (hp/lb)', 'FontSize', 12, 'FontWeight', 'bold');
title('ASTM F2245 LSA Electric Aircraft Constraint Diagram', 'FontSize', 14, 'FontWeight', 'bold');
axis([4 25 0 0.12]);
legend('Location', 'northwest', 'FontSize', 10);

% Highlight Design Feasible Region
text(9, 0.08, 'FEASIBLE REGION', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0.5 0]);

%% ========================================================================
% 4. ATMOSPHERIC AUXILIARY FUNCTION
% ========================================================================
function [T, P, a, rho] = atmospheric_props(h)
    % Standard Atmosphere model for troposphere
    T0 = 518.67;        % Sea level temp (deg R)
    P0 = 2116.2;        % Sea level pressure (psf)
    L = 0.00356616;     % Temperature lapse rate (deg R/ft)
    
    T = T0 - L * h;
    P = P0 * (T / T0)^(5.2561);
    rho = P / (1716.5 * T);
    a = sqrt(1.4 * 1716.5 * T);
end