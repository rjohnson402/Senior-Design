function audit = AEGAbankenergyaudit2035(out)
% Normal mission energy allocation for isolated banks; no failure reserve claim.
% Existing mass sizing uses aggregate energy. This audit exposes stranded
% energy if equal-capacity banks cannot transfer power during normal flight.
m=out.msn; t=out.operating_phases; pairs=AEGAbatterypairs2035(m);
P=zeros(height(t),8); P(:,[1:3 5:7])=repmat(t.HighLiftShaft_kW/6,1,6);
P(:,[4 8])=repmat(t.CruiseShaft_kW/2,1,2);
share=P./max(sum(P,2),eps);
energy=share.*t.EnergyWithAllowance_kWh;
route=sum(energy,1);
reserve=t.Phase=="Reserve";
low=t.Phase=="Takeoff" | t.Phase=="Initial climb" | t.Phase=="Clean climb" | ...
    t.Phase=="Descent" | t.Phase=="Approach" | t.Phase=="Landing / flare" | ...
    t.Phase=="Landing ground roll / reverse";
xc=out.mission.xc.n_departures*sum(energy(low,:),1)+sum(energy(reserve,:),1);
xcCruise=out.mission.Pcruise_kW*out.mission.xc.cruise_distance_nm/m.Vkt*(1+out.options.phase_energy_margin);
xc([4 8])=xc([4 8])+xcCruise/2;
assert(abs(sum(route)-out.mission.E_range)<1e-7,'Unallocated route energy.');
assert(abs(sum(xc)-out.mission.E_ppl_xc)<1e-7,'Unallocated cross-country energy.');
er=zeros(4,1); ex=er; peak=er;
for j=1:4
    er(j)=sum(route(pairs(j,:))); ex(j)=sum(xc(pairs(j,:)));
    peak(j)=max(sum(P(:,pairs(j,:)),2))/(m.eta_m*m.eta_pe);
end
required=er;
if m.enforce_ppl_xc, required=max(er,ex); end
capacity=required/m.fusable;
equalUsable=out.pack_kWh*m.fusable/4;
audit=struct('pairs',pairs,'bank_table',table((1:4)',pairs(:,1),pairs(:,2),er,ex,required,capacity, ...
    repmat(equalUsable,4,1),required<=equalUsable,peak, ...
    'VariableNames',{'Bank','Motor1','Motor2','RouteUsable_kWh','XCUsable_kWh','RequiredUsable_kWh', ...
    'ProportionalNominal_kWh','EqualBankUsable_kWh','EqualBankEnergyPass','PeakBattery_kW'}), ...
    'proportional_total_kWh',sum(capacity),'equal_isolated_total_kWh',4*max(capacity), ...
    'aggregate_sized_kWh',out.pack_kWh,'equal_bank_energy_pass',all(required<=equalUsable), ...
    'scope','Normal-flight energy audit at this aircraft mass; no resized penalty, cell-rate/thermal validation or failed-bank energy reserve.');
end
