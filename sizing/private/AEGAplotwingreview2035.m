function f=AEGAplotwingreview2035(s,folder)
% Show the calculated weight trough and why its lighter designs are rejected.
% This plot never changes the sizing or feasibility flags.
chosen=s.AR_best(s.AR_best.PassesScreen & strcmp(s.AR_best.Selection,'Minimum MTOW'),:);
f=figure('Visible','off','Color','w','Position',[100 80 1250 850]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
nexttile; plot(chosen.AR,chosen.MTOW_lb,'-o','LineWidth',2,'Color',[0 .35 .65]); grid on;
xlabel('Aspect ratio'); ylabel('Minimum passing MTOW, lb'); title('Best passing design at each AR');
ars=intersect([14 16 18],unique(s.AR.AR)');
colors=[0 .35 .65;.8 .3 .05;.15 .5 .25];
nexttile; curves('MTOW_lb',false);
xlabel('Wing loading, lb/ft^2'); ylabel('Calculated MTOW, lb'); title('Full search; crosses mark rejected designs');
xlim([min(s.options.WS) max(s.options.WS)]); legend('Location','northeast');
nexttile; curves('MTOW_lb',true);
xlabel('Wing loading, lb/ft^2'); ylabel('Calculated MTOW, lb'); title('Weight trough and feasible cutoff');
zoom_bounds=[max(min(s.options.WS),20) min(max(s.options.WS),36)];
if zoom_bounds(1)<zoom_bounds(2), xlim(zoom_bounds); end
a=s.AR(s.AR.AR==18 & s.AR.Converged & isfinite(s.AR.MTOW_lb),:);
if ~isempty(a)
    [~,j]=min(a.MTOW_lb); lowest=a(j,:);
    passing=a(a.PassesScreen,:);
    if ~isempty(passing)
        [~,j]=min(passing.MTOW_lb); best=passing(j,:);
        plot(best.WS_lb_ft2,best.MTOW_lb,'p','MarkerSize',13,'MarkerFaceColor',[.15 .5 .25],'Color','k','HandleVisibility','off');
        if ~lowest.PassesScreen
            plot(lowest.WS_lb_ft2,lowest.MTOW_lb,'d','MarkerSize',9,'Color','k','LineWidth',1.5,'HandleVisibility','off');
            subtitle(sprintf('AR18: passing min W/S %.2f; rejected weight trough W/S %.2f',best.WS_lb_ft2,lowest.WS_lb_ft2));
        end
    end
    nearby=s.AR(ismember(s.AR.AR,ars) & s.AR.Converged & isfinite(s.AR.MTOW_lb) & ...
        s.AR.WS_lb_ft2>=zoom_bounds(1) & s.AR.WS_lb_ft2<=zoom_bounds(2),:);
    if ~isempty(nearby), ylim([min(nearby.MTOW_lb)-25 max(nearby.MTOW_lb)+25]); end
end
nexttile; curves('Landing_ft',false); hold on;
yline(s.inputs.S_field,'k-',sprintf('%.0f-ft target',s.inputs.S_field), ...
    'LineWidth',1.5,'LabelHorizontalAlignment','left','HandleVisibility','off');
xlabel('Wing loading, lb/ft^2'); ylabel('Modeled landing over 50 ft, ft'); title('Landing Field-Length Constraint');
if zoom_bounds(1)<zoom_bounds(2), xlim(zoom_bounds); end
sgtitle(AEGAtradetitle2035('Wing Loading and Aspect Ratio Trade Study',s.inputs, ...
    sprintf('x: rejected | reverse target %.0f%% W, below %.0f kt after %.0f s; hardware %.1f lb', ...
    100*s.inputs.reverse_TW,s.inputs.reverse_engage_below_kt, ...
    s.inputs.reverse_delay_s,s.inputs.reverse_hardware_lb)),'Color','k','FontSize',12);
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k','FontSize',10);
set(findall(f,'Type','text'),'Color','k'); set(findall(f,'Type','legend'),'Color','w','TextColor','k');
if nargin>1 && ~isempty(folder)
    exportgraphics(f,fullfile(folder,'01_wing_loading_and_AR.png'),'Resolution',180);
    savefig(f,fullfile(folder,'01_wing_loading_and_AR.fig'));
end
    function curves(field,zoomed)
        hold on; grid on;
        for k=1:numel(ars)
            t=sortrows(s.AR(s.AR.AR==ars(k),:),'WS_lb_ft2'); color=colors(k,:);
            values=t.(field); values(~t.Converged | ~isfinite(values))=NaN;
            plot(t.WS_lb_ft2,values,'--','LineWidth',1.1,'Color',color,'HandleVisibility','off');
            passing=values; passing(~t.PassesScreen)=NaN;
            plot(t.WS_lb_ft2,passing,'-o','LineWidth',1.7,'Color',color,'DisplayName',sprintf('AR%d',ars(k)));
            bad=t.Converged & ~t.PassesScreen & isfinite(values);
            plot(t.WS_lb_ft2(bad),values(bad),'x','Color',color,'MarkerSize',5,'HandleVisibility','off');
            if zoomed, set(gca,'YLimMode','auto'); end
        end
    end
end
