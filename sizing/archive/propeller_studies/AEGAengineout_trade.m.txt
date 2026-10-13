function trade = AEGAengineout_trade(msn,ref,opt)
function trade = AEGAengineout_trade(msn,ref,opt)
% Compare diameter ratios at the original wing loading and fixed disk area.
if nargin < 3, opt = struct(); end
ratios = 1:0.05:1.60;
opt.WS = ref.WSR;
opt.doplot = false;
opt.print = false;
trade.ratios = ratios;
trade.two_out_kW = zeros(3,numel(ratios));
trade.four_out_kW = zeros(3,numel(ratios));
trade.thrust_moment = zeros(3,numel(ratios));
for i = 1:numel(ratios)
    fprintf('Diameter-ratio trade: %d/%d (ratio %.2f)\n',i,numel(ratios),ratios(i));
    drawnow;
    opt.ratio = ratios(i);
    s = AEGAengineout(msn,ref,opt);
    for f = 1:3
        d = s.family(f).reference;
        trade.two_out_kW(f,i) = max(d.required_hp_lb(2:29))*ref.MTOW*.745699872;
        trade.four_out_kW(f,i) = d.required_hp_lb(30)*ref.MTOW*.745699872;
        trade.thrust_moment(f,i) = d.thrust_moment_norm(1);
    end
end
trade.families = {'Equal','Two-size','Graded'};
figure('Color','w','Name','Engine-out diameter-ratio trade');
tiledlayout(1,3);
values = {trade.two_out_kW,trade.four_out_kW,trade.thrust_moment};
names = {'Worst 2 out: required installed power','4 inboard out: required installed power', ...
    'All-operating normalized thrust moment'};
for j = 1:3
    nexttile; hold on; grid on; box on;
    set(gca,'Color','w','XColor','k','YColor','k');
    v = values{j}; v(~isfinite(v)) = NaN;
    plot(ratios,v.','-o','LineWidth',1.5);
    if j <= 2
        yline(ref.PTO_kW,'k--','Original installed power','HandleVisibility','off');
        ylabel('Total installed shaft power, kW');
    else
        ylabel('sum(|y| T) / (Ttotal b/2)');
    end
    xlabel('Root / tip diameter ratio');
    title(names{j},'Color','k');
    legend(trade.families,'Location','best','TextColor','k','Color','w');
end
if s.options.include_climb
    sgtitle(sprintf('Fixed weight: lift + approach + %.1f%% climb at %.0f kt', ...
        100*s.options.selected_climb_gradient,s.options.climb_speed_kt),'Color','k');
else
    sgtitle('Fixed weight: lift + approach only','Color','k');
end
end