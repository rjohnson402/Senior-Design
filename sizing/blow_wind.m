function CL_blown = blow_wind(msn, u_0_kts, lift_cfg)
    if nargin < 3
        error("please provide msn, flight speed, and flight time to blow_wind function.")
    end

    % Conversions
    KT2FPS   = 1.688;

    % Flight Conditions
    rho = pick(msn, 'rho', 0.002048); % value for air density
    kin_nu  = pick(msn,'nu',    3.68041e-7);
    nu = kin_nu / rho; % dynamic viscosity, lb s / ft^2
    
    u_0 = u_0_kts .* KT2FPS; % value for initial velocity


    
    
    
    % Define the initial parameters
    W = pick(msn,'DG0',    2000); % weight, lbs
    S_ref = msn.SW; % wing reference area, ft^2
    b_ref = msn.SPAN;
    AR = pick(msn,'AR',       12);
    num_props = pick(msn,'NPROP',     6);
    WFus    = pick(msn,'WFus',      3.66);% fuselage width
    DFus    = pick(msn,'DFus',      4.16);% fuselage depth
    e_osw   = pick(msn,'e_osw',     0.80);
    CD0    = pick(msn,'CD0',      0.0216);
    switch lift_cfg
        case 'landing'
            CL = pick(msn, 'CLmax', 2.1);
        case 'takeoff'
            CL = pick(msn, 'CLmax', 2.1);
        case 'Cruise'
            CL = msn.CL_cruise;
    end
    
    prop_diam = (b_ref - WFus) / num_props;
    
    A_prop = pi * (prop_diam/2)^2; % value for area property

    
    CDi_new = CL.^2 ./ (pi * AR * e_osw);
    T_tot_new = 0.5 .* rho .* u_0.^2 .* S_ref .* (CD0 + CDi_new);
    T_tot = T_tot_new - 1;
    
    while abs(T_tot_new - T_tot) > 1e-6
        T_tot = T_tot_new;
        T = T_tot / num_props;
        u_e = u_0 .* (T ./ (A_prop .* u_0.^2 .* rho ./ 2) + 1).^(1/2);
        prop_factor = sqrt((u_0 + (u_e - u_0)/2)/(u_e));
        prop_wash_b = (prop_factor * prop_diam) * num_props;
        p_blown = prop_wash_b/b_ref;

        q_ratio = u_e^2 / u_0^2;
        CL_eff = CL * q_ratio; 

        CL_eff_true = p_blown * (CL_eff) + (1 - p_blown) * (CL);

        CDi_new = CL_eff_true.^2 ./ (pi * AR * e_osw);
        T_tot_new = 0.5 .* rho .* u_0.^2 .* S_ref .* (CD0 + CDi_new);
    end
    CL_blown = CL_eff_true;
end