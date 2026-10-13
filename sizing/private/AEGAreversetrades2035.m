function s=AEGAreversetrades2035(msn,opt)
% Conditional reversing-pitch hardware versus the trainer's no-reverse case.
if nargin<1, msn=AEGAinputs(); end
if nargin<2, opt=struct(); end
if ~isfield(opt,'WS'), opt.WS=unique([20:2:36 msn.WS_design 25.25 31.25]); end
if ~isfield(opt,'refine'), opt.refine=true; end
if ~isfield(opt,'output_dir'), opt.output_dir=''; end
if ~isfield(opt,'doplot'), opt.doplot=false; end
if ~isfield(opt,'publish_review'), opt.publish_review=true; end
cfg=AEGAstudysettings2035(msn);
targets=[0 .03 .05 .06 .08 .06 .06 .06];
names=["No reverse" "3% target" "5% target" "6% nominal target" "8% optimistic target" ...
    "6% target, heavier hardware" "6% target, 3-second delay" "Reversing hardware, reverse unavailable"];
rows=cell(0,1); details=cell(0,1); bestRows=cell(numel(targets),1);
for k=1:numel(targets)
    mm=AEGAreversecase2035(msn,targets(k));
    if k==6, mm.reverse_hardware_lb=2.20462*14; end
    if k==7, mm.reverse_delay_s=3; end
    if k==8, mm.reverse_TW=0; end % installed hardware remains in the weight
    [m,o]=AEGAstudycase2035(mm,cfg);
    coarseIndices=zeros(numel(opt.WS),1);
    for j=1:numel(opt.WS), coarseIndices(j)=evaluate(opt.WS(j)); end
    coarse=struct2table(vertcat(rows{coarseIndices}));
    passing=coarse(coarse.PassesScreen,:);
    if opt.refine && ~isempty(passing)
        [~,j]=min(passing.MTOW_lb); center=passing.WS_lb_ft2(j);
        fine=setdiff(center-2:.25:center+2,opt.WS);
        fine=fine(fine>=min(opt.WS) & fine<=max(opt.WS));
        for ws=fine, evaluate(ws); end
    end
    allRows=struct2table(vertcat(rows{:})); group=allRows(allRows.CaseIndex==k & allRows.PassesScreen,:);
    assert(~isempty(group),'AEGAreversetrades2035:noPassing','No passing sample: %s.',names(k));
    [~,j]=min(group.MTOW_lb); bestRows{k}=table2struct(group(j,:));
    fprintf('Reverse study: %s: %.1f lb at W/S %.2f; landing %.0f ft, without reverse %.0f ft.\n', ...
        names(k),group.MTOW_lb(j),group.WS_lb_ft2(j),group.Landing_ft(j),group.NoReverseLanding_ft(j));
end
s=struct('source_inputs',msn,'options',opt,'cases',struct2table(vertcat(rows{:})), ...
    'best',struct2table(vertcat(bestRows{:})),'details',{details});
s.best.DeltaMTOW_lb=s.best.MTOW_lb-s.best.MTOW_lb(1);
if ~isempty(opt.output_dir)
    if ~isfolder(opt.output_dir), mkdir(opt.output_dir); end
    writetable(s.cases,fullfile(opt.output_dir,'01_reverse_cases.csv'));
    writetable(s.best,fullfile(opt.output_dir,'02_reverse_selections.csv'));
    save(fullfile(opt.output_dir,'reverse_trade.mat'),'s');
    nominal=details{s.best.DetailIndex(4)};
    writetable(nominal.con.landing_ground_roll.trace,fullfile(opt.output_dir,'03_nominal_reverse_ground_roll.csv'));
    writetable(nominal.operating_phases,fullfile(opt.output_dir,'04_nominal_reverse_flight_phases.csv'));
    if opt.doplot, draw(s,opt.output_dir); end
    write_report(s,opt.output_dir);
end
    function index=evaluate(ws)
        r=AEGAsize(m,ws,o); details{end+1,1}=r; index=numel(details);
        roll=r.con.landing_ground_roll;
        rows{index,1}=struct('CaseIndex',k,'Case',names(k),'WS_lb_ft2',ws, ...
            'MTOW_lb',r.MTOW,'Landing_ft',r.con.S_land_ft,'NoReverseLanding_ft',r.con.S_land_no_reverse_ft, ...
            'PassesScreen',r.feasible,'MeetsFieldWithoutReverse',r.con.S_land_no_reverse_ft<=msn.S_field, ...
            'RequestedReverseTW',m.reverse_TW,'AchievableStaticScreenTW',roll.peak_reverse_TW, ...
            'ReverseHardware_lb',r.W.reverse_hardware,'ReverseBattery_kWh',roll.battery_energy_kWh, ...
            'ReversePeakPower_kW',max(roll.trace.ReverseShaft_kW),'GroundRoll_s',roll.duration_s, ...
            'Delay_s',m.reverse_delay_s,'EngageBelow_kt',m.reverse_engage_below_kt, ...
            'ActivationTime_s',roll.activation_time_s,'Status',string(r.status),'DetailIndex',index);
    end
end

function draw(s,folder)
f=figure('Visible','off','Color','w','Position',[100 100 1200 540]);
cleanup=onCleanup(@() close(f)); tiledlayout(1,2,'TileSpacing','compact');
colors=[.1 .35 .65;.65 .45 .1;.1 .55 .3;.8 .25 .1];
for panel=1:2
    nexttile; hold on; grid on;
    for k=1:4
        t=sortrows(s.cases(s.cases.CaseIndex==k,:),'WS_lb_ft2'); color=colors(k,:);
        field='MTOW_lb'; if panel==2, field='Landing_ft'; end
        plot(t.WS_lb_ft2,t.(field),'--','Color',color,'HandleVisibility','off');
        y=t.(field); y(~t.PassesScreen)=NaN;
        plot(t.WS_lb_ft2,y,'-o','Color',color,'LineWidth',1.7,'DisplayName',t.Case(1));
        b=s.best(k,:); plot(b.WS_lb_ft2,b.(field),'p','Color',color,'MarkerSize',12,'MarkerFaceColor',color,'HandleVisibility','off');
    end
    xlabel('Wing loading, lb/ft^2'); xlim([min(s.options.WS) max(s.options.WS)]);
    if panel==1
        ylabel('MTOW including reverse hardware, lb'); title('Hardware cost versus allowed wing loading'); legend('Location','northeast');
    else
        ylabel('Landing over 50 ft, ft'); title('Below 55 kt; 2-second minimum delay; 1-second ramp');
        yline(s.source_inputs.S_field,'k-','1500-ft target','HandleVisibility','off');
    end
end
sgtitle('Conditional reversing cruise props | solid = passing; dashed = rejected | 3–8% thrust targets are assumptions','Color','k');
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k'); set(findall(f,'Type','text'),'Color','k');
set(findall(f,'Type','legend'),'Color','w','TextColor','k');
exportgraphics(f,fullfile(folder,'05_reverse_trade.png'),'Resolution',180); savefig(f,fullfile(folder,'05_reverse_trade.fig'));
end

function write_report(s,folder)
root=AEGAroot(); fid=fopen(fullfile(folder,'README.md'),'w'); guard=onCleanup(@() fclose(fid));
fprintf(fid,'# Reverse-thrust trade for the trainer\n\n');
reference=s.details{s.best.DetailIndex(1)};
fprintf(fid,'This compares the AR%.2f, taper %.2f reference with two %.2f-ft cruise / six %.2f-ft high-lift props, re-closing weight, power and mission energy for each W/S. Reverse capability is conditional on a suitable negative-pitch propeller design, not a demonstrated hardware capability.\n\n',reference.msn.AR,reference.msn.TR,reference.prop_layout.D_side(end),reference.prop_layout.D_side(1));
fprintf(fid,'Nominal assumptions: reverse target 6%% of weight; engagement only after braking below 55 kt AND at least 2 seconds since touchdown; 1-second ramp from that activation time; thrust fades below 15 kt to zero at 5 kt; two cruise props only. Speed is ground-roll speed in the still-air model. Added hardware is 9 kg (19.8 lb), with the normal weight margin applied. The 55-kt threshold, two 4-kg hub/pitch/beta increments and 1-kg control allowance are analyst assumptions, not manufacturer operating limits or masses.\n\n');
fprintf(fid,'Requested shaft power is 15 kW for 3/5%%, 18 kW for 6%% and 25 kW for 8%%. It is capped at half the cruise pair''s assigned peak rating. A static momentum screen with an assumed .50 figure of merit further caps reverse thrust. This is not a reverse Ct/Cp map and does not prove thrust at touchdown advance ratio. Reverse consumes battery energy; no regeneration is credited. The rollout''s energy is included once per landing in the project and three-stop missions. No reverse thrust or lift benefit is applied in flight.\n\n');
fprintf(fid,'| Case | Best passing W/S | MTOW, lb | Change, lb | Landing, ft | Same aircraft without reverse, ft | Added hardware, lb |\n|---|---:|---:|---:|---:|---:|---:|\n');
for j=1:height(s.best)
    t=s.best(j,:); fprintf(fid,'| %s | %.2f | %.1f | %+.1f | %.0f | %.0f | %.1f |\n', ...
        t.Case,t.WS_lb_ft2,t.MTOW_lb,t.DeltaMTOW_lb,t.Landing_ft,t.NoReverseLanding_ft,t.ReverseHardware_lb);
end
fprintf(fid,'\nThe no-reverse distance evaluates the SAME installed-hardware aircraft after disabling reverse; it is not the separately resized no-reverse optimum. The last row also re-sizes the hardware-equipped aircraft for unavailable reverse.\n\n');
fprintf(fid,'For a trainer, retain landing capability without reverse and treat it as an optional stopping aid. Reversing pitch adds hardware and maintenance, requires a ground-only interlock and matched commands, and creates asymmetric braking if one outboard prop reverses alone. The sizing model does not establish those controls or an aborted-reverse go-around transition.\n\n');
fprintf(fid,'[Hartzell Manual 168, external beta system](https://hartzellprop.com/wp-content/uploads/2012/12/168-0000-R03-AW.pdf) describes dedicated pitch/reverse mechanisms. [MT''s electric-prop range](https://www.mt-propeller.com/mt/en/products/propeller-systems/electric-propellers-1086/) states its optional reverse application is airships; this is not an available certified trainer solution. [NACA negative-thrust/torque tests](https://ntrs.nasa.gov/citations/19930091716) establish that the operating regime depends on blade angle and speed. None supplies our numeric thrust or mass assumptions.\n\n');
if s.options.doplot, fprintf(fid,'![Reverse trade](05_reverse_trade.png)\n\n'); end
fprintf(fid,'Run `AEGAtrades(''reverse'')` from the sizing folder. Current AEGAinputs enables the conditional 6%% case. This supporting study retains separately sized no-reverse and installed-hardware/reverse-unavailable cases.\n');
clear guard
if ~s.options.publish_review, return; end
doc=fileread(fullfile(folder,'README.md')); [~,name]=fileparts(folder);
doc=strrep(doc,'(05_reverse_trade.png)',['(trade_results/' name '/05_reverse_trade.png)']);
fid=fopen(fullfile(root,'REVERSE_THRUST_REVIEW.md'),'w'); guard=onCleanup(@() fclose(fid)); fprintf(fid,'%s',doc);
end
