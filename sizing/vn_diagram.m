function loads = vn_diagram(msn,out)

% Run msn = AEGAinputs()
% Run out = AEGAsize(msn)
% Run vn_diagram(msn,out)

fps2kts = 0.592484;
% INPUTS
n_positive = 3.8; % from old part 23 reqs
n_negative = -1.52; % from old part 23 reqs
pos_gust = 50;
dive_speed_factor = 1.25;
% Code



% Plot v-n diagram
figure(1)
syms v
pos_stall_line = 0.5 * msn.rho_cr * v^2 * out.SW * out.CLmax_TO / out.MTOW;
neg_stall_line = -0.5 * msn.rho_cr * v^2 * out.SW * out.CLmax_TO / out.MTOW;
n_pos_line = n_positive;
n_neg_line = n_negative;

v_int = solve(pos_stall_line == n_pos_line, v);
y_int = subs(pos_stall_line, v, v_int);

% Convert to numbers for plotting
v_int = double(v_int);
y_int = double(y_int);

fplot(pos_stall_line, [0,300], 'LineWidth', 1.5)
hold on

xlabel("Equivalent Airspeed [ft/s]")
ylabel("Load Factor (n)")
% grid on
title("V-n Diagram")
xlim([0 300])
ylim([-5 5])
fplot(neg_stall_line, [0,300], 'LineWidth', 1.5)
fplot(n_pos_line, 'LineWidth', 1.5)
fplot(n_neg_line, 'LineWidth', 1.5)

y = linspace(-5, 5, 100);

plot(v_int*ones(size(y)), y, '--', 'Color', 'k')
plot(msn.VS0/fps2kts*ones(size(y)), y, '--', 'Color', 'k')

pos_gust_line = 1 + 0.5*msn.rho_cr*v*4.5*pos_gust/out.WSR;
neg_gust_line = -pos_gust_line+2;
fplot(pos_gust_line, [0 300], 'Color', 'bl', 'LineStyle', '--')
fplot(neg_gust_line, [0 300], 'Color', 'bl', 'LineStyle', '--')

plot(msn.Vkt/fps2kts*ones(size(y)), y, 'Color', 'bl', 'LineStyle', '--')
plot(msn.Vkt*dive_speed_factor/fps2kts*ones(size(y)), y, 'Color', 'bl', 'LineStyle', '--')
end