function fig=AEGAplotflightphases2035(s)
% Actual motor-group power fraction and lift CAPACITY, on each selected wing.
n=height(s.best);
fig=figure('Name','Throttle and blown-lift phase schedule','Color','w', ...
    'Visible',s.options.figure_visible,'Position',[120 60 1350 300*n]);
tiles=tiledlayout(fig,n,2,'TileSpacing','compact','Padding','compact');
title(tiles,{'Flight-Phase Propulsion Utilization and Lift Capability', ...
    'Throttle: assigned shaft rating fraction | blown lift evaluated at scheduled thrust'},'FontSize',12);
for j=1:n
    a=s.operating_phases(s.operating_phases.Profile==s.best.Profile(j) & ...
        s.operating_phases.Family==s.best.Family(j),:);
    if isempty(a), nexttile(tiles); nexttile(tiles); continue; end
    x=1:height(a);
    ax=nexttile(tiles); hold(ax,'on'); grid(ax,'on');
    h=bar(ax,x,[a.HighLiftThrottle_percent a.CruiseThrottle_percent],'grouped');
    h(1).FaceColor=[0 .447 .741]; h(2).FaceColor=[.85 .325 .098];
    yline(ax,100,'k:','HandleVisibility','off');
    ylabel(ax,'Assigned shaft rating (%)'); ylim(ax,[0 115]);
    legend(ax,{'Six high-lift motors','Two cruise motors'},'Location','best');
    title(ax,s.best.Profile(j)+" | "+s.best.Family(j));
    xticks(ax,x); xticklabels(ax,a.Phase); xtickangle(ax,30);
    ax=nexttile(tiles); hold(ax,'on'); grid(ax,'on');
    plot(ax,x,a.CLmaxUnblown,'o-','Color',[.35 .35 .35],'LineWidth',1.2);
    plot(ax,x,a.CLmaxBlown,'s-','Color',[0 .447 .741],'LineWidth',1.5);
    plot(ax,x,a.CLrequired,'x--','Color',[.85 .325 .098],'LineWidth',1.2);
    ylabel(ax,'Lift coefficient'); title(ax,'Available lift at scheduled throttle');
    legend(ax,{'Unblown capacity','Blown capacity','Required operating CL'},'Location','best');
    xticks(ax,x); xticklabels(ax,a.Phase); xtickangle(ax,30);
end
end
