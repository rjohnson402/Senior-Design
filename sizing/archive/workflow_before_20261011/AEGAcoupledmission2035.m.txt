function [mis,t,cruise] = AEGAcoupledmission2035(msn,DG,S,b,layout,CD0,P,cg,cruise,opt,mis)
% Replace the blanket non-cruise allowance with an explicit phase schedule.
% Project route distances include climb, idle descent and approach travel.
t=AEGAflightphases2035(msn,DG,S,b,layout,CD0,P,cg,cruise,opt);
names=t.Phase;
climb=names=="Initial climb" | names=="Clean climb";
arrival=names=="Descent" | names=="Approach" | names=="Landing / flare" | ...
    names=="Landing ground roll / reverse";
routes=startsWith(names,"Route leg "); reserve=names=="Reserve";
takeoff=names=="Takeoff";
removed=[sum(t.Distance_nm(climb)) sum(t.Distance_nm(arrival))];
idx=find(routes);
assert(sum(t.Distance_nm(routes))+1e-9>=sum(removed),'AEGAcoupledmission2035:route', ...
    'Route is shorter than modeled climb and arrival distances.');
for side=1:2
    left=removed(side); sequence=idx;
    if side==2, sequence=flipud(sequence); end
    for j=sequence(:).'
        used=min(left,t.Distance_nm(j)); old=t.Distance_nm(j);
        t.Distance_nm(j)=old-used; t.Duration_hr(j)=t.Distance_nm(j)/t.Speed_ktas(j);
        t.Energy_kWh(j)=t.Energy_kWh(j)*(old-used)/max(old,eps); left=left-used;
        if left<=1e-9, break; end
    end
end
for j=1:numel(cruise)
    k=find(names==cruise(j).phase,1);
    cruise(j).distance_nm=t.Distance_nm(k); cruise(j).duration_hr=t.Duration_hr(k);
    cruise(j).energy_kWh=t.Energy_kWh(k)*(1+opt.phase_energy_margin);
end
t.EnergyWithAllowance_kWh=t.Energy_kWh*(1+opt.phase_energy_margin);
mis.E_range=sum(t.EnergyWithAllowance_kWh);
% AEGAmission already supplies battery power at the peak-speed geometry.
% Three-stop mission repeats the same low-speed schedule; reserve is flown
% at the shared profile's reserve speed rather than silently at peak speed.
n=mis.xc.n_departures;
xc_cruise_nm=max(0,mis.xc.route_nm-n*sum(removed));
low=takeoff | climb | arrival;
xc_low=n*sum(t.Energy_kWh(low));
xc_cruise=mis.Pcruise_kW*xc_cruise_nm/msn.Vkt;
xc_reserve=sum(t.Energy_kWh(reserve));
mis.E_ppl_xc=(xc_low+xc_cruise+xc_reserve)*(1+opt.phase_energy_margin);
mis.xc.cruise_distance_nm=xc_cruise_nm;
mis.xc.E_low_phases_kWh=xc_low*(1+opt.phase_energy_margin);
mis.xc.E_cruise_reserve_kWh=(xc_cruise+xc_reserve)*(1+opt.phase_energy_margin);
mis.E_required=mis.E_range; mis.driver=char(opt.mission_profile.name);
if msn.enforce_ppl_xc && mis.E_ppl_xc>mis.E_range
    mis.E_required=mis.E_ppl_xc; mis.driver='PPL solo cross-country';
end
mis.phases=cruise; mis.operating_phases=t;
mis.project_route_nm=sum(t.Distance_nm(routes | climb | arrival));
mis.phase_energy_margin=opt.phase_energy_margin;
mis.accounting='Explicit takeoff/climb/descent/arrival; route distance shared; separate energy allowance';
end
