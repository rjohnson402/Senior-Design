clear all

%% Mission, technology, geometry
msn.payload = 400;        % 2 occupants x 200 lb incl. baggage
msn.range   = 300;        % nautical miles
msn.reserve = 45;         % minutes at cruise
msn.Vkt     = 120;        % cruise, knots true airspeed
msn.VS0     = 60;         % stall, knots calibrated airspeed
msn.CLmax   = 2.1;        % landing configuration, idle power
msn.ovh     = 0.04;       % taxi, takeoff, climb, descent allowance
% Atmosphere
msn.rho     = 0.002377;   % sea level density, slug/ft^3
msn.nu      = 1.572e-4;   % kinematic viscosity, ft^2/s
% Wing geometry
msn.AR      = 14;
msn.TR      = 0.45;
msn.e_osw   = 0.80;       % Oswald efficiency factor
% Tail sizing
msn.Vh      = 0.60;       % horizontal tail volume coefficient
msn.Vv      = 0.040;      % vertical tail volume coefficient
msn.Lh      = 12.47;      % horizontal tail arm, ft
msn.Lv      = 12.47;      % vertical tail arm, ft
% Drag build-up
msn.XL      = 24.0;       % fuselage length
msn.WFus    = 3.66;       % fuselage width
msn.DFus    = 4.16;       % fuselage depth
msn.SMISC   = 48.4;       % gear fairings, canopy, junctions
msn.SCOV    = 6.78;       % wing area buried in the fuselage
msn.WETR    = 2.05;       % wetted / planform for wing and tails
msn.Cf_w    = 0.0033;
msn.FF_w    = 1.30;
msn.Cf_t    = 0.0036;
msn.FF_t    = 1.20;
msn.Cf_m    = 0.0040;
msn.FF_m    = 1.30;
msn.Cf_c    = 0.0030;     % configuration-added surfaces
msn.excr    = 1.13;       % excrescence and interference factor
% Propulsion and efficiency
msn.PWkWkg  = 0.176;      % takeoff power loading, kW per kg
msn.eta_m   = 0.95;
msn.eta_pe  = 0.97;
msn.prof    = 0.86;       % propeller profile factor
msn.NPROP   = 8;
msn.Dprop   = 6.23;       % diameter, ft
% Battery
msn.whkg    = 350;        % pack specific energy, Wh/kg
msn.fusable = 0.90;
% Iteration control
msn.DG0     = 2050;       % first guess, lb
msn.NMAX    = 12;
msn.TOL     = 0.5;        % convergence tolerance, lb

%% Configuration modifiers (propulsor trade study)
cfg.dS      = 0;          % added wetted area, ft^2
cfg.FFc     = 1.0;        % interference factor on that area
cfg.ing     = 0;          % fraction of fuselage wake ingested
cfg.dist    = 0;          % distortion loss on the ingested gain
cfg.wrec    = 0.5;        % wake recovery factor
cfg.Adisc   = -1;         % total disc area; -1 = compute it
cfg.dWinst  = 0;          % nacelles, ducts, pylons, lb
cfg.Kgear   = 1.0;        % gear length multiplier
cfg.Kfus    = 1.0;        % fuselage wetted area multiplier
cfg.KHT     = 1.0;        % horizontal tail area multiplier
cfg.KVT     = 1.0;        % vertical tail area multiplier
cfg.HHT     = 0;          % T-tail flag
cfg.NEW     = 0;          % wing-mounted motors, keep at 0
cfg.oth     = 0;          % other cruise power penalty

out = AEGAsize(msn, cfg);