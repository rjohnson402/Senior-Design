function check_reverse2035(s)
% Ground-roll, hardware and energy checks independent of the trade selection.
if nargin<1
    m=AEGAinputs(); [a,o]=AEGAstudycase2035(AEGAreversecase2035(m));
    r=AEGAsize(a,24,o);
    s=struct('best',table(true,r.con.S_land_ft,r.con.S_land_no_reverse_ft,1, ...
        'VariableNames',{'PassesScreen','Landing_ft','NoReverseLanding_ft','DetailIndex'}), ...
        'details',{{r}});
end
assert(all(s.best.PassesScreen));
v=struct('best',table(true(height(s.best),1),true(height(s.best),1), ...
    repmat("Fixed",height(s.best),1),'VariableNames',{'PassesScreen','PhaseSchedulePass','Family'}), ...
    'best_details',{cell(height(s.best),1)});
for j=1:height(s.best)
    r=s.details{s.best.DetailIndex(j)}; m=r.msn; g=r.con.landing_ground_roll;
    v.best_details{j}=r;
    assert(abs(r.weight_residual_lb)<r.options.weight_tolerance);
    assert(r.W.reverse_hardware==m.reverse_hardware_lb);
    assert(abs(r.con.S_land_ft-r.con.S_land_air_ft-g.distance_ft)<1e-9);
    assert(r.con.S_land_no_reverse_ft>=r.con.S_land_ft-1e-9);
    assert(max(g.trace.ReverseShaft_kW)<=m.reverse_available_shaft_kW+1e-8);
    assert(g.peak_reverse_TW<=m.reverse_TW+1e-8);
    airborne=r.operating_phases(r.operating_phases.RequiredForSizing,:);
    assert(all(airborne.Thrust_lb>=0));
    if m.reverse_TW>0
        assert(all(g.trace.ReverseTW(g.trace.Time_s<=m.reverse_delay_s)==0));
        assert(all(g.trace.ReverseTW(g.trace.Speed_kt>m.reverse_engage_below_kt)==0));
        assert(g.activation_time_s>=m.reverse_delay_s);
        assert(all(g.trace.ReverseTW(g.trace.Time_s<=g.activation_time_s)==0));
        assert(all(g.trace.ReverseTW(g.trace.Time_s<=g.activation_time_s+m.reverse_ramp_s) ...
            <=g.peak_reverse_TW+1e-8));
        assert(g.trace.ReverseTW(end)==0);
        fine=AEGAlandingroll2035(m,r.CD0,r.CLmax,r.WSR,800);
        assert(abs(fine.distance_ft-g.distance_ft)<1,'Rollout quadrature is not converged.');
        % Force the speed condition to govern, rather than the time delay.
        late=m; late.reverse_engage_below_kt=35;
        delayed=AEGAlandingroll2035(late,r.CD0,r.CLmax,r.WSR);
        assert(delayed.activation_time_s>m.reverse_delay_s);
        assert(all(delayed.trace.ReverseTW(delayed.trace.Speed_kt>35)==0));
        assert(delayed.distance_ft>=g.distance_ft-1e-8);
        assert(delayed.battery_energy_kWh<=g.battery_energy_kWh+1e-8);
        blocked=m; blocked.reverse_pair_available=false;
        stopped=AEGAlandingroll2035(blocked,r.CD0,r.CLmax,r.WSR);
        assert(stopped.peak_reverse_TW==0 && stopped.shaft_energy_kWh==0);
        assert(abs(stopped.distance_ft-g.no_reverse_distance_ft)<1e-9);
        noPower=m; noPower.reverse_available_shaft_kW=0;
        absent=AEGAlandingroll2035(noPower,r.CD0,r.CLmax,r.WSR);
        assert(abs(absent.distance_ft-g.no_reverse_distance_ft)<1e-9);
        phase=r.operating_phases(r.operating_phases.Phase=="Landing ground roll / reverse",:);
        assert(height(phase)==1 && phase.HighLiftThrottle_percent==0 && phase.CLmaxCredited==0);
        assert(abs(phase.Energy_kWh-g.battery_energy_kWh)<1e-12);
        assert(abs(phase.BatteryPower_kW*phase.Duration_hr-g.battery_energy_kWh)<1e-12);
        atLimit=AEGAlandingroll2035(m,r.CD0,r.CLmax,r.con.limits.land);
        assert(abs(r.con.S_land_air_ft+atLimit.distance_ft-m.S_field)<1e-5);
    else
        assert(g.battery_energy_kWh==0);
    end
end
check_coupledflight2035(v);
old=AEGAsize(AEGAlegacyinputs2035(),32,struct());
assert(abs(old.MTOW-2349.7110165744)<.01);
fprintf('PASS: delayed/ramped ground reverse, power/static cap, pair-unavailable/no-power cases, hardware closure, rollout convergence, mission energy and archived baseline.\n');
end
