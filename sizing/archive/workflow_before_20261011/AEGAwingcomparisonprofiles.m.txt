function profiles = AEGAwingcomparisonprofiles(msn)
% Shared mission examples. Mixed legs count toward the same total route.
profiles(1) = struct('name',string(sprintf('Current %.0f-knot mission',msn.Vkt)), ...
    'route_speed_ktas',msn.Vkt,'route_distance_nm',msn.range,'reserve_speed_ktas',msn.Vkt);
% 30 min at 100 knots covers 50 nm; remainder is flown at 160 knots.
assert(msn.range>50,'Mixed route requires more than 50 nm.');
profiles(2) = struct('name',"Illustrative 100/160-knot mission", ...
    'route_speed_ktas',[100 160],'route_distance_nm',[50 msn.range-50], ...
    'reserve_speed_ktas',msn.Vkt);
end
