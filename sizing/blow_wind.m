function CL_blown = blow_wind(msn, DG, lift_cfg, PTO)
    if nargin < 2
        error("please provide msn, flight speed, and flight time to blow_wind function.")
    end

    % Conversions
    KT2FPS   = 1.688;
    W2KW   = 737.56;  % ft*lb/s per kW

    % Flight Conditions
    u_0_kts = msn.VS0;
    rho    = msn.rho_SL;

    % Define the initial parameters
    S_ref = msn.SW; % wing reference area, ft^2
    b_ref = msn.SPAN;
    N      = msn.NPROP;

    [prop_diam, A_tot] = AEGAprop(msn, S_ref);
    A_prop = A_tot/N;

    switch lift_cfg
        case 'landing'
            u_0   = u_0_kts .* KT2FPS;
            CL    = msn.CLmax_L;
            CDi   = CL^2/(pi*msn.AR*msn.e_osw);
            T_tot = 0.5*rho*u_0^2*S_ref*(msn.CD0 + CDi) - DG*sin(deg2rad(msn.approach_angle));

        case 'takeoff'
        if nargin < 3 || isempty(PTO)
            error('blow_wind:PTO', 'takeoff needs installed shaft power PTO, kW');
        end
            CL    = msn.CLmax_TO;
            u_0   = 1.1*sqrt(2*msn.WS/(rho*CL));   % liftoff, unblown-stall basis
            Pid   = msn.prof*PTO*W2KW;          % ideal power into slipstream
            rA    = rho*A_tot;
            vi    = fzero(@(v) 2*rA*v*(u_0 + v)^2 - Pid, [0 500]);
            T_tot = 2*rA*vi*(u_0 + vi);

        otherwise
            error('blow_wind:cfg', 'lift_cfg must be ''landing'' or ''takeoff''');
    end
    T           = T_tot/N;
    u_e         = u_0*sqrt(1 + T/(0.5*rho*A_prop*u_0^2));
    prop_factor = sqrt((u_0 + u_e)/(2*u_e));        % wake contraction
    p_blown     = min(prop_factor*prop_diam*N/b_ref, 1);
    q_ratio     = (u_e/u_0)^2;
    CL_blown    = p_blown*CL*q_ratio + (1 - p_blown)*CL;
    CL_blown    = min(CL_blown, msn.CLmax_cap);
end