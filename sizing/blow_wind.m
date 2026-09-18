function CL_blown = blow_wind(msn, u_0_kts, flight_type)
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
    W = 1500; % weight, lbs
    S_ref = 140; % wing reference area, ft^2
    b_ref = 40;
    AR = 12;
    num_props = 8;
    
    e_osw   = pick(msn,'e_osw',     0.80);
    XL      = pick(msn,'XL',       24.0); % Fuselage length, ft^2
    WFus    = pick(msn,'WFus',      3.66); % max fuselage width, ft^2
    DFus    = pick(msn,'DFus',      4.16); % max fuselage depth, ft^2
    Cf_w    = pick(msn,'Cf_w',      0.0033);
    FF_w    = pick(msn,'FF_w',      1.30);
    Cf_t    = pick(msn,'Cf_t',      0.0036);
    FF_t    = pick(msn,'FF_t',      1.20);
    Cf_m    = pick(msn,'Cf_m',      0.0040);
    FF_m    = pick(msn,'FF_m',      1.30);
    Cf_c    = pick(msn,'Cf_c',      0.0030);% configuration-added surfaces
    excr    = pick(msn,'excr',      1.13); % excrescence and interference factor

    SMISC   = 48.4; % Misc stuff area, ft^2
    FFc = 1;
    WETR = 2.05;
    SHT = 20;
    SVT = 10;
    
    % Lift
    L = W;
    CL = 2 .* L ./ ( rho .* u_0.^2 .* S_ref);
    % Drag
    Ref   = u_0.*XL./nu;                            % fuselage Reynolds number
    Cf_f  = 0.455./log10(Ref).^2.58;              % Prandtl-Schlichting flat plate
    fineness = XL/((WFus + DFus)/2);
    FF_f  = 1 + 60/fineness^3 + fineness/400;
    DAV = (WFus + DFus) / 2;                        % Eq. 57
    SWFUS = pi() * (XL / DAV - 1.7) * DAV^2;    % Eq. 61
    f_fus = Cf_f*FF_f*SWFUS*excr;               % fuselage drag area, ft^2
    f_msc = Cf_m*FF_m*SMISC*excr;
    f_wing = Cf_w*FF_w*S_ref*WETR*excr;
    f_tail = Cf_t*FF_t*WETR*(SHT + SVT)*excr;
    f      = f_wing + f_tail + f_fus + f_msc;
    CD0    = f/S_ref;
    
    % We need CD0, T_tot, 
    
    prop_diam = (b_ref - WFus) / num_props;
    
    A_prop = pi * (prop_diam/2)^2; % value for area property   
    
    while abs(T_tot_new - T_tot) > 1e-6
        T_tot = T_tot_new;
        T = T_tot / num_props;
        u_e = u_0 .* (T ./ (A_prop .* u_0.^2 .* rho ./ 2) + 1).^(1/2);
        prop_factor = sqrt((u_0 + (u_e - u_0)/2)/(u_e));
        prop_wash_b = (prop_factor * prop_diam) * num_props;
        p_blown = prop_wash_b/b_ref;

        CL_new = p_blown * (2 .* W ./ (rho .* u_e.^2 .* S_ref)) + ...
            (1 - p_blown) * (2 .* W ./ (rho .* u_0.^2 .* S_ref));

        CDi_new = CL_new.^2 ./ (pi * AR * e_osw);
        T_tot_new = 0.5 .* rho .* u_e.^2 .* S_ref .* (CD0 + CDi_new);
    end
    CL_blown = CL_new;
end