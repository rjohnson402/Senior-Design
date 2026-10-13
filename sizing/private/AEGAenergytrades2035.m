function study=AEGAenergytrades2035(msn,opt)
% Reclose aircraft mass at each PACK-level specific energy, fixed W/S and AR.
validateattributes(opt.pack_Whkg,{'numeric'},{'vector','real','finite','positive'});
values=unique(opt.pack_Whkg(:).');
details=cell(numel(values),1); rows=cell(numel(values),1);
for k=1:numel(values)
    m=msn; m.whkg=values(k);
    row=struct('Pack_Whkg',values(k),'MTOW_lb',NaN,'Battery_lb',NaN, ...
        'Pack_kWh',NaN,'UsableMission_kWh',NaN,'WingArea_ft2',NaN, ...
        'Span_ft',NaN,'Installed_kW',NaN,'CruiseBattery_kW',NaN, ...
        'Landing_ft',NaN,'Converged',false,'PassesScreen',false,'Status',"");
    try
        r=AEGAsize(m); details{k}=r;
        row.MTOW_lb=r.MTOW; row.Battery_lb=r.W.battery;
        row.Pack_kWh=r.pack_kWh; row.UsableMission_kWh=r.Ebat;
        row.WingArea_ft2=r.SW; row.Span_ft=r.span; row.Installed_kW=r.PTO_kW;
        row.CruiseBattery_kW=r.Pcruise_kW; row.Landing_ft=r.con.S_land_ft;
        row.Converged=r.converged; row.PassesScreen=r.feasible; row.Status=string(r.status);
        fprintf('Pack %.0f Wh/kg: MTOW %.1f lb; battery %.1f lb / %.2f kWh; passes %d\n', ...
            values(k),r.MTOW,r.W.battery,r.pack_kWh,r.feasible);
    catch err
        row.Status=string(err.identifier)+": "+string(err.message);
        fprintf('Pack %.0f Wh/kg: unavailable (%s)\n',values(k),err.identifier);
    end
    rows{k}=row;
end
study=struct('inputs',msn,'options',opt,'cases',struct2table(vertcat(rows{:})), ...
    'details',{details});
if opt.doplot
    f=figure('Color','w','Visible',opt.figure_visible,'Position',[100 100 1250 720]);
    tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
    fields={'MTOW_lb','Battery_lb','Pack_kWh','Installed_kW'};
    labels={'MTOW, lb','Battery weight, lb','Installed battery energy, kWh','Installed shaft power, kW'};
    t=study.cases; finite=t.Converged & isfinite(t.MTOW_lb); passing=finite & t.PassesScreen;
    for j=1:numel(fields)
        nexttile; hold on; grid on;
        y=t.(fields{j}); y(~finite)=NaN;
        plot(t.Pack_Whkg,y,'--','Color',[.25 .45 .65],'HandleVisibility','off');
        y(~passing)=NaN;
        plot(t.Pack_Whkg,y,'-o','LineWidth',1.8,'Color',[.15 .4 .7],'MarkerFaceColor','w');
        bad=finite & ~t.PassesScreen;
        plot(t.Pack_Whkg(bad),t.(fields{j})(bad),'x','Color',[.85 .3 .1],'MarkerSize',8);
        xline(msn.whkg,':','Reference','Color',[.45 .45 .45],'HandleVisibility','off');
        xlabel('Battery pack specific energy, Wh/kg'); ylabel(labels{j});
        if numel(values)>1, xlim([min(values) max(values)]); end
        if numel(values)<=12, xticks(values); end
    end
    sgtitle({ 'Battery Pack Specific Energy Sensitivity', ...
        sprintf('%.0f nm at %.0f KTAS + %.0f min reserve | %.0f lb payload | %.0f%% usable', ...
        msn.range,msn.Vkt,msn.reserve,msn.payload,100*msn.fusable), ...
        sprintf('AR %.1f | W/S %.1f lb/ft^2 | %.2f-ft cruise / %.2f-ft high-lift | aircraft re-sized at each energy density', ...
        msn.AR,msn.WS_design,msn.cruise_prop_diameter_ft,msn.high_lift_prop_diameter_ft)},'FontSize',12,'Color','k');
    % Make exported figures readable independently of MATLAB's desktop theme.
    set(findall(f,'Type','Axes'),'Color','w','XColor','k','YColor','k');
    set(findall(f,'Type','Text'),'Color','k');
    if opt.save_plots
        if ~isfolder(opt.output_dir), mkdir(opt.output_dir); end
        exportgraphics(f,fullfile(opt.output_dir,'Battery_Energy_Density_Sensitivity.png'),'Resolution',180);
        savefig(f,fullfile(opt.output_dir,'Battery_Energy_Density_Sensitivity.fig'));
    end
end
if ~isempty(opt.output_dir)
    if ~isfolder(opt.output_dir), mkdir(opt.output_dir); end
    writetable(study.cases,fullfile(opt.output_dir,'battery_energy_density.csv'));
    save(fullfile(opt.output_dir,'battery_energy_trade.mat'),'study');
    AEGAtradeassumptions2035(study);
    fid=fopen(fullfile(opt.output_dir,'STUDY_NOTES.txt'),'w'); assert(fid>=0);
    guard=onCleanup(@()fclose(fid));
    fprintf(fid,'PACK-level energy density grid %s Wh/kg; energy, not power density.\n',mat2str(values));
    fprintf(fid,'Fixed AR %.2f, W/S %.2f; selected prop diameters unchanged. Geometry, installed power, battery energy and MTOW reclosed at each sample.\n',msn.AR,msn.WS_design);
    fprintf(fid,'Specific energy does not change available motor power or usable fraction. Equal isolated bank energy and asymmetric control remain unvalidated.\n');
end
end
