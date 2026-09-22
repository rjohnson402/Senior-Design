function CL_blown = blow_wind(msn, u_0_kts, lift_cfg)
    if nargin < 3
        error("please provide msn, flight speed, and flight time to blow_wind function.")
    end

    % Conversions
    KT2FPS   = 1.688;

    % Flight Conditions
    u_0 = u_0_kts .* KT2FPS; % value for initial velocity
    switch lift_cfg
        case 'landing'
            CL = msn.CLmax_L; rho = msn.rho_SL;
        case 'takeoff'
            CL = msn.CLmax_TO; rho = msn.rho_SL;
        case 'Cruise'
            CL = msn.CLmax_clean; rho = msn.rho_cr;
    end

    % Define the initial parameters
    S_ref = msn.SW; % wing reference area, ft^2
    b_ref = msn.SPAN;
    AR = msn.AR;
    num_props = msn.NPROP;
    WFus    = msn.WFus;% fuselage width

    e_osw   = msn.e_osw;
    CD0    = msn.CD0;

    prop_diam = (b_ref - WFus) / num_props;
    A_prop = pi * (prop_diam/2)^2; % value for area property
    
    CDi_new = CL.^2 ./ (pi * AR * e_osw);
    T_tot = 0.5 .* rho .* u_0.^2 .* S_ref .* (CD0 + CDi_new);

    T = T_tot / num_props;
    u_e = u_0 .* (T ./ (A_prop .* u_0.^2 .* rho ./ 2) + 1).^(1/2);
    prop_factor = sqrt((u_0 + (u_e - u_0)/2)/(u_e));
    prop_wash_b = (prop_factor * prop_diam) * num_props;
    p_blown = prop_wash_b/b_ref;

    q_ratio = u_e^2 / u_0^2;
    CL_eff = CL * q_ratio; 

    CL_blown = p_blown * (CL_eff) + (1 - p_blown) * (CL);
end