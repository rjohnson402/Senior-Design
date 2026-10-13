function mis = AEGAmission(msn,DG,D,eta,con,PTO_kW)
% mission-energy checks for the electric trainer

%% constants
KT2FPS = 1.688;
NM2FT = 6076.12;
FTLB = 2.6552e6;
W2KW = 737.56;
HP2KW = 0.745699872;

%% common cruise condition
V = msn.Vkt*KT2FPS;
Pcruise_kW = D*V/eta/W2KW;

%% project range mission
Req_range_ft = (msn.range + msn.reserve/60*msn.Vkt)*NM2FT;
E_range = D*Req_range_ft/eta*(1 + msn.ovh)/FTLB;

%% ppl solo cross-country mission
leg_nm = msn.ppl_xc_leg_nm(:)';
n_landings = numel(leg_nm);
n_departures = n_landings;
route_nm = sum(leg_nm);

route_ok = route_nm >= 150 && n_landings >= 3 && leg_nm(1) > 50;

if msn.enforce_ppl_xc && ~route_ok
    error('ppl cross-country route does not meet the required mission geometry')
end

takeoff_min = msn.ppl_xc_takeoff_min;
climb_alt_ft = msn.ppl_xc_climb_alt_ft;

% Takeoff uses full installed shaft power, matching the blown-lift model.
% Keep five-argument callers compatible by deriving the installed rating.
if nargin < 6 || isempty(PTO_kW)
    PTO_kW = con.PW_kWkg*DG/2.20462;
end
validateattributes(PTO_kW,{'numeric'},{'scalar','real','finite','positive'});
Ptakeoff_kW = PTO_kW/(msn.eta_m*msn.eta_pe);
Pclimb_kW = con.PW_at_design.climb*DG*HP2KW/(msn.eta_m*msn.eta_pe);

takeoff_hr = takeoff_min/60;
climb_hr = climb_alt_ft/con.ROC_fpm/60;
climb_nm_each = con.V_climb_kt*climb_hr;

% remove horizontal distance traveled during climb from cruise distance
cruise_nm = max(route_nm - n_departures*climb_nm_each,0);

% mission energy
E_xc_takeoff = n_departures*Ptakeoff_kW*takeoff_hr;
E_xc_climb = n_departures*Pclimb_kW*climb_hr;
E_xc_cruise = Pcruise_kW*(cruise_nm/msn.Vkt + msn.reserve/60);

E_ppl_xc = E_xc_takeoff + E_xc_climb + E_xc_cruise;

%% governing mission
if msn.enforce_ppl_xc && E_ppl_xc > E_range
    E_required = E_ppl_xc;
    driver = 'PPL solo cross-country';
else
    E_required = E_range;
    driver = 'project range';
end

%% outputs
mis.E_required = E_required;
mis.driver = driver;
mis.Pcruise_kW = Pcruise_kW;
mis.E_range = E_range;
mis.E_ppl_xc = E_ppl_xc;

mis.xc.route_ok = route_ok;
mis.xc.leg_nm = leg_nm;
mis.xc.route_nm = route_nm;
mis.xc.n_departures = n_departures;
mis.xc.n_full_stop_landings = n_landings;

mis.xc.takeoff_min_each = takeoff_min;
mis.xc.climb_alt_ft = climb_alt_ft;
mis.xc.climb_time_min_each = 60*climb_hr;
mis.xc.climb_distance_nm_each = climb_nm_each;
mis.xc.cruise_distance_nm = cruise_nm;
mis.xc.reserve_min = msn.reserve;

mis.xc.Ptakeoff_kW = Ptakeoff_kW;
mis.xc.Pclimb_kW = Pclimb_kW;
mis.xc.Pcruise_kW = Pcruise_kW;

mis.xc.E_takeoff_kWh = E_xc_takeoff;
mis.xc.E_climb_kWh = E_xc_climb;
mis.xc.E_cruise_reserve_kWh = E_xc_cruise;
end