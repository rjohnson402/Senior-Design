function f=AEGAplotoptimizedwings2035(s)
% Selected physical planforms; fully retracted capability is not cruise use.
profiles=unique(s.best.Profile,'stable'); n=numel(profiles);
bottomOffset=.10; if n==1, bottomOffset=.35; end
f=figure('Name','Optimized wing geometries','Color','w', ...
    'Visible',s.options.figure_visible,'Position',[100 70 1200 max(470,360*n)]);
% A fixed figure header avoids tiled-layout title collisions when equal-scale
% high-AR planforms collapse the axes plot boxes to a very shallow height.
annotation(f,'textbox',[0 .90 1 .10],'String', ...
    {'Optimized Fixed and Variable-Span Wing Geometry', ...
    'Selected minimum-MTOW designs | dashed: minimum available span; orange: chosen cruise span'}, ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'FontSize',12,'EdgeColor','none','Interpreter','none');
for ip=1:n
    g=s.optimized_wings(s.optimized_wings.Profile==profiles(ip),:);
    maxSemi=max(g.SpanExtended_ft)/2;
    panel=0; rowHeight=.78/n;
    for family=["Fixed" "Adaptive"]
        panel=panel+1;
        ax=axes('Parent',f,'Position',[.07+.50*(panel-1) bottomOffset+(n-ip)*rowHeight .40 .55*rowHeight]);
        hold(ax,'on'); grid(ax,'on');
        j=find(s.best.Profile==profiles(ip) & s.best.Family==family,1);
        if isempty(j) || ~s.best.PassesScreen(j), title(ax,family+": no feasible selected design"); continue; end
        a=s.best_details{j}; root=2*a.SW/(a.span*(1+a.msn.TR));
        tip=root*a.msn.TR; semi=a.span/2;
        sweepLE=tand(a.msn.SWEEP)+(root-tip)/(2*a.span);
        [x,y]=outline(semi,root,tip,sweepLE);
        patch(ax,x,y,[.80 .88 .96],'EdgeColor',[0 .35 .65],'LineWidth',1.4, ...
            'DisplayName','Fully extended planform');
        r=a.options.retract_fraction;
        if r>0
            coreSemi=semi*(1-r); coreTip=root-(root-tip)*(1-r);
            [x,y]=outline(coreSemi,root,coreTip,sweepLE);
            plot(ax,x,y,'--','Color',[.35 .35 .35],'LineWidth',1.4, ...
                'DisplayName','Fully retracted capability');
        end
        frac=a.cruise_geometry.span/a.span;
        [x,y]=outline(semi*frac,root,root-(root-tip)*frac,sweepLE);
        plot(ax,x,y,'-','Color',[.85 .325 .098],'LineWidth',2,'DisplayName','Selected cruise planform');
        axis(ax,'equal'); set(ax,'YDir','reverse'); xlim(ax,[-maxSemi maxSemi]*1.06);
        ylim(ax,[-.75 max(root,semi*sweepLE+tip)+.75]);
        xlabel(ax,'Spanwise position, ft'); ylabel(ax,'Aft of root leading edge, ft');
        title(ax,{char(profiles(ip)),sprintf('%s | %.0f lb | AR %.2f | taper %.3f',family,a.MTOW,a.msn.AR,a.msn.TR)});
        subtitle(ax,{sprintf('S %.1f ft^2; W/S %.2f; span %.2f ft',a.SW,a.WSR,a.span), ...
            sprintf('Cruise span %.2f ft; actual retraction %.1f%%', ...
            a.cruise_geometry.span,100*a.cruise_geometry.actual_retraction_fraction)},'FontSize',10);
        legend(ax,'Location','southoutside');
    end
end
end

function [x,y]=outline(semi,root,tip,sweepLE)
dx=semi*sweepLE;
x=[-semi 0 semi semi 0 -semi -semi];
y=[dx 0 dx dx+tip root dx+tip dx];
end
