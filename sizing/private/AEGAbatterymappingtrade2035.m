function study = AEGAbatterymappingtrade2035(m,opt)
% Compare the requested cross-paired supply architecture with the old mapping.
if nargin<2, opt=struct(); end
folder=fullfile(AEGAroot(),'trade_results',['battery_mapping_' char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]);
if isfield(opt,'output_root'), folder=fullfile(opt.output_root,'battery_mapping'); end
if ~isfolder(folder), mkdir(folder); end
maps={ [1 5;2 6;3 7;4 8], [1 5;2 6;3 8;4 7] };
names=["Mirrored baseline","Cross-paired proposal"];
study=struct('inputs',m,'output_dir',folder,'aircraft',{{}},'energy',{{}});
rows=struct([]);
for j=1:2
    mm=m; mm.battery_motor_pairs=maps{j}; a=AEGAsize(mm);
    assert(a.feasible && a.converged && isequal(a.eo.pairs,maps{j}));
    assert(isequal(a.eo.alive(1,:),true(1,8)));
    for k=1:4, assert(isequal(find(~a.eo.alive(k+1,:)),sort(maps{j}(k,:)))); end
    e=AEGAbankenergyaudit2035(a);
    study.aircraft{j}=a; study.energy{j}=e;
    row=struct('Mapping',names(j),'MTOW_lb',a.MTOW,'Installed_kW',a.PTO_kW, ...
        'WorstFailureRequired_kW',max(a.eo.required_kW(2:5)), ...
        'MinSurvivingCruiseMotors',min(sum(a.eo.alive(2:5,[4 8]),2)), ...
        'AggregatePack_kWh',a.pack_kWh,'ProportionalBanks_kWh',e.proportional_total_kWh, ...
        'EqualIsolatedBanks_kWh_at_current_mass',e.equal_isolated_total_kWh, ...
        'EqualBankEnergyPass',e.equal_bank_energy_pass,'PowerLiftScreenPass',a.feasible, ...
        'AsymmetricTrimValidated',false);
    if isempty(rows), rows=row; else, rows(end+1)=row; end
    writetable(e.bank_table,fullfile(folder,sprintf('bank_energy_%d.csv',j)));
end
study.summary=struct2table(rows);
assert(study.summary.MinSurvivingCruiseMotors(2)==1);
writetable(study.summary,fullfile(folder,'comparison.csv'));
save(fullfile(folder,'battery_mapping.mat'),'study'); disp(study.summary);
end
