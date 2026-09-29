function out = AEGAsize(msn)
% aegasize closes the coupled aircraft weight, wing, propulsion, and battery loop
%
% the main sequence is:
%   1. get the baseline wing-loading limit from aegaconstraint
%   2. iterate blown landing lift and wing loading
%   3. build the final wing and tail geometry
%   4. calculate drag and propeller geometry
%   5. calculate takeoff blown lift and required installed power
%   6. calculate cruise efficiency and mission energy
%   7. calculate component weights
%   8. repeat until mtow converges
%
% all design choices come from the msn structure returned by aegainputs
% quantities generated during sizing stay local or are returned in out

if nargin < 1 || isempty(msn)
    msn = AEGAinputs();
end

%% ======================= shared design inputs ===========================
% pull frequently used values out of msn so the sizing equations stay readable

payload = msn.payload;

Vkt = msn.Vkt;
VS0 = msn.VS0;

rho_SL = msn.rho_SL;
rho_cr = msn.rho_cr;
nu = msn.nu_cr;

AR = msn.AR;
TR = msn.TR;
e_osw = msn.e_osw;

Vh = msn.Vh;
Vv = msn.Vv;
Lh = msn.Lh;
Lv = msn.Lv;

XL = msn.XL;
WFus = msn.WFus;
DFus = msn.DFus;

SMISC = msn.SMISC;
SCOV = msn.SCOV;
WETR = msn.WETR;

Cf_w = msn.Cf_w;
FF_w = msn.FF_w;

Cf_t = msn.Cf_t;
FF_t = msn.FF_t;

Cf_m = msn.Cf_m;
FF_m = msn.FF_m;

excr = msn.excr;

eta_m = msn.eta_m;
eta_pe = msn.eta_pe;
prof = msn.prof;

fusable = msn.fusable;

%% ======================= iteration control ==============================
% dg is only the initial mtow guess
% the secant update below replaces it after each sizing pass

DG = 2050;
NMAX = 12;
TOL = 0.5;

%% ======================= constants =====================================
KT2FPS = 1.688;
LB = 2.20462;

%% ======================= cruise condition ===============================
% cruise dynamic pressure is fixed because speed and cruise altitude are
% design inputs rather than variables in the mtow loop

V = Vkt*KT2FPS;
q = 0.5*rho_cr*V^2;

%% ======================= initial constraint solution ====================
% this gives the baseline wing loading before blown lift is coupled to wing size
% blown lift is introduced later because it depends on the converged geometry

con = AEGAconstraint(msn,[],false);
WS0 = con.WS_design;

%% ======================= fixed fuselage drag ============================
% fuselage dimensions do not change inside the sizing loop, so its drag area
% can be calculated once before iteration

DAV = (WFus + DFus)/2;
SWFUS = pi*(XL/DAV - 1.7)*DAV^2;

Ref = V*XL/nu;
Cf_f = 0.455/log10(Ref)^2.58;

fineness = XL/DAV;
FF_f = 1 + 60/fineness^3 + fineness/400;

f_fus = Cf_f*FF_f*SWFUS*excr;
f_msc = Cf_m*FF_m*SMISC*excr;

%% ======================= convergence history ============================
% column 1 stores the guessed mtow
% column 2 stores the mtow returned by the component-weight build-up

hist = zeros(NMAX,2);

%% ======================= main sizing loop ===============================
for i = 1:NMAX

    %% ------------------- initialize this pass ---------------------------
    % start each mtow iteration from the baseline constraint wing loading
    % then allow the blown-wing calculation to modify it

    WSR = WS0;

    CLmax_L_blown = msn.CLmax_L;
    CLmax_TO_blown = msn.CLmax_TO;

    bw_L = struct();
    bw_TO = struct();

    % installed power from the previous pass is used to estimate takeoff
    % blowing before the current pass has solved its final power requirement

    PTO_prev = con.PW_kWkg*DG/LB;

    %% ------------------- converge landing blown lift --------------------
    % blown lift changes the allowable wing loading
    % wing loading changes wing area
    % wing area changes span and propeller geometry
    % propeller geometry then changes blown lift
    %
    % this inner loop closes that coupling before continuing the mtow loop

    if msn.use_blown_wind

        for k = 1:20

            % current wing geometry from the latest wing-loading estimate

            SW = DG/WSR;
            SPAN = sqrt(AR*SW);

            cr = 2*SW/(SPAN*(1 + TR));
            MAC = (2/3)*cr*(1 + TR + TR^2)/(1 + TR);

            % tail areas are based on the current wing geometry and volume coefficients

            SHT = Vh*MAC*SW/Lh;
            SVT = Vv*SPAN*SW/Lv;

            % current zero-lift drag coefficient
            % wing and tail drag areas change with geometry while the
            % fuselage and miscellaneous drag areas remain fixed

            f_wing = Cf_w*FF_w*WETR*(SW - SCOV)*excr;
            f_tail = Cf_t*FF_t*WETR*(SHT + SVT)*excr;

            CD0 = (f_wing + f_tail + f_fus + f_msc)/SW;

            % pass the current geometry to the local blown-wing model

            msn.SW = SW;
            msn.SPAN = SPAN;
            msn.CD0 = CD0;
            msn.WS = WSR;

            [CLmax_L_blown,bw_L] = sizing_blown_wing(msn,DG,'landing',[]);

            % recalculate the actual wing-loading limit using the updated
            % blown landing clmax rather than scaling the old limit manually

            con_ws = AEGAconstraint(msn,CD0,false,[],CLmax_L_blown,[]);
            WSRnew = con_ws.WS_design;

            % stop when wing loading has effectively stopped changing

            if abs(WSRnew - WSR) < 1e-3
                WSR = WSRnew;
                break
            end

            WSR = WSRnew;
        end

        if k == 20
            warning('AEGAsize:blown','blown W/S did not converge')
        end
    end

    %% ------------------- final wing geometry ----------------------------
    % rebuild geometry once using the converged wing loading for this mtow pass

    SW = DG/WSR;
    SPAN = sqrt(AR*SW);

    cr = 2*SW/(SPAN*(1 + TR));
    ctip = TR*cr;

    MAC = (2/3)*cr*(1 + TR + TR^2)/(1 + TR);

    SHT = Vh*MAC*SW/Lh;
    SVT = Vv*SPAN*SW/Lv;

    %% ------------------- final drag build-up ----------------------------
    % wetted-area drag changes as the wing and tail resize

    f_wing = Cf_w*FF_w*WETR*(SW - SCOV)*excr;
    f_tail = Cf_t*FF_t*WETR*(SHT + SVT)*excr;

    f = f_wing + f_tail + f_fus + f_msc;

    CD0 = f/SW;

    %% ------------------- propeller geometry -----------------------------
    % aegaprop packs the propellers across the available semispan
    %
    % if prop_root_tip_ratio exists, four props per wing are graded
    % linearly from the largest root prop to the smallest tip prop

    msn.SW = SW;
    msn.SPAN = SPAN;
    msn.CD0 = CD0;
    msn.WS = WSR;

    if isfield(msn,'prop_root_tip_ratio') && ~isempty(msn.prop_root_tip_ratio)

        if ~isfield(msn,'prop_Dratio_side') || isempty(msn.prop_Dratio_side)
            msn.prop_Dratio_side = linspace(msn.prop_root_tip_ratio,1,msn.NPROP/2);
        end
    end

    [Dprop,Adisc,~,~,prop_layout] = AEGAprop(msn,SW);

    %% ------------------- propeller weight diameter ----------------------
    % the blade-weight equation scales approximately with diameter cubed
    %
    % for unequal props, using the simple equivalent disk diameter would
    % underrepresent that cubic weighting, so use the cubic mean diameter

    if isfield(prop_layout,'D_side')
        Dprop_weight = mean(prop_layout.D_side.^3)^(1/3);
    else
        Dprop_weight = Dprop;
    end

    %% ------------------- coupled takeoff lift and installed power -------
    % Full installed power is used for both takeoff lift and mission energy.
    % Close the power/lift coupling at the current geometry and gross weight.
    if msn.use_blown_wind
        power_balance = @(P) takeoff_power_balance(P,msn,DG,CD0,WSR,CLmax_L_blown);
        P_hi = max(PTO_prev,1);
        bracketed = false;
        for ip = 1:60
            if power_balance(P_hi) >= 0
                bracketed = true;
                break
            end
            P_hi = 2*P_hi;
        end
        if ~bracketed
            error('AEGAsize:takeoffPower','Could not bracket takeoff power.');
        end
        [PTO,~,exitflag] = fzero(power_balance,[0 P_hi]);
        if exitflag <= 0 || ~isfinite(PTO) || PTO <= 0
            error('AEGAsize:takeoffPower','Takeoff power balance did not converge.');
        end
        [~,CLmax_TO_blown,bw_TO,con] = ...
            takeoff_power_balance(PTO,msn,DG,CD0,WSR,CLmax_L_blown);
    else
        con = AEGAconstraint(msn,CD0,false,WSR,CLmax_L_blown,CLmax_TO_blown);
        PTO = con.PW_kWkg*DG/LB;
    end

    %% ------------------- cruise aerodynamics ----------------------------
    % cruise cl comes directly from wing loading and dynamic pressure

    CL = WSR/q;

    % parabolic induced drag model

    CDi = CL^2/(pi*AR*e_osw);

    CD = CD0 + CDi;

    LD = CL/CD;

    % in level cruise thrust required equals drag

    D = DG/LD;

    %% ------------------- cruise propulsive efficiency -------------------
    % use total propeller disk area to estimate disk loading and ideal
    % propulsive efficiency, then apply the profile efficiency factor

    CT = D/(q*Adisc);

    etap = 2/(1 + sqrt(1 + CT))*prof;

    % total battery-to-thrust efficiency includes inverter and motor losses

    eta = eta_m*eta_pe*etap;

    %% ------------------- mission energy ---------------------------------
    % aegamission evaluates both the project range mission and the ppl
    % cross-country mission, then returns whichever requires more energy

    mission = AEGAmission(msn,DG,D,eta,con,PTO);

    Ebat = mission.E_required;

    %% ------------------- component weight build-up ----------------------
    % these are the quantities aegAweight needs from the current sizing pass

    st = struct('DG',DG,'SW',SW,'SHT',SHT,'SVT',SVT,...
                'PTO_kW',PTO,'Ebat',Ebat,'SWFUS',SWFUS,...
                'Dprop',Dprop_weight);

    W = AEGAweight(msn,st);

    %% ------------------- close the mtow loop ----------------------------
    % gross weight is empty weight plus the fixed payload

    DGout = W.empty + payload;

    hist(i,:) = [DG DGout];

    % if the guessed and calculated gross weights agree, sizing is converged

    if abs(DGout - DG) < TOL
        break
    end

    % use a direct fixed-point update on the first pass
    % after that use a secant update to accelerate convergence

    if i == 1
        DG = DGout;
    else
        r1 = hist(i,1) - hist(i,2);
        r0 = hist(i-1,1) - hist(i-1,2);

        DG = hist(i,1) - r1*(hist(i,1) - hist(i-1,1))/(r1 - r0);
    end
end

%% ======================= main aircraft outputs ==========================
out.MTOW = DGout;

out.W = W;

out.SW = SW;
out.span = SPAN;
out.MAC = MAC;

out.SHT = SHT;
out.SVT = SVT;

out.WSR = WSR;

out.CLmax = CLmax_L_blown;
out.CLmax_TO = CLmax_TO_blown;

out.CD0 = CD0;
out.CDi = CDi;
out.CD = CD;

out.LD = LD;
out.drag = D;

out.eta_prop = etap;
out.eta_total = eta;

%% ======================= mission outputs ================================
% ebat is usable energy required from the battery
% pack_kwh includes the allowed usable fraction of the installed pack

out.Ebat = Ebat;

out.Ebat_range = mission.E_range;
out.Ebat_ppl_xc = mission.E_ppl_xc;

out.mission_driver = mission.driver;
out.mission = mission;

out.pack_kWh = Ebat/fusable;

out.PTO_kW = PTO;
out.Pcruise_kW = mission.Pcruise_kW;

%% ======================= constraint outputs =============================
out.con = con;

%% ======================= clean stall check ==============================
% the blown landing configuration can support a high w/s while the clean
% wing still stalls too fast
%
% keep this as a separate check because sport-pilot clean-stall requirements
% are not the same as the powered landing clmax requirement

out.VS1 = sqrt(2*WSR/(rho_SL*msn.CLmax_clean))/KT2FPS;

out.VS1_ok = out.VS1 <= msn.VS1_op;

out.CLclean_req = WSR/(0.5*rho_SL*(msn.VS1_op*KT2FPS)^2);

%% ======================= propeller outputs ===============================
out.Dprop = Dprop;
out.Adisc = Adisc;

out.prop_layout = prop_layout;

%% ======================= detailed wing outputs ==========================
% these values are meant to make wing and constraint trades easier without
% digging back through the sizing equations after every run

out.wing.S = SW;
out.wing.span = SPAN;

out.wing.AR = AR;
out.wing.TR = TR;

out.wing.c_root = cr;
out.wing.c_tip = ctip;
out.wing.MAC = MAC;

out.wing.prop = prop_layout;

out.wing.blown_landing = bw_L;
out.wing.blown_takeoff = bw_TO;

%% ======================= wing-loading comparison ========================
% actual w/s is the value used by the sizing solution
%
% ws_vs0_limit is the exact stall-based limit using blown landing clmax
%
% ws_vs0_design includes the same 2 percent sizing margin used by the
% constraint model

out.wing.WS_actual = WSR;

out.wing.WS_VS0_limit = 0.5*rho_SL*(VS0*KT2FPS)^2*CLmax_L_blown;

out.wing.WS_VS0_design = 0.98*out.wing.WS_VS0_limit;

%% ======================= cruise wing-loading reference =================
% for a parabolic drag polar:
%
% cl at maximum l/d = sqrt(cd0/k)
%
% this provides a useful comparison between the wing loading selected by
% low-speed constraints and the wing loading preferred by cruise efficiency

out.wing.CL_cruise = CL;

out.wing.CL_LDmax = sqrt(CD0*pi*AR*e_osw);

out.wing.WS_LDmax = q*out.wing.CL_LDmax;

% this is the wing area that would place the current mtow at the theoretical
% maximum-l/d wing loading
%
% it is a diagnostic value, not automatically a new design wing area

out.wing.S_at_LDmax = out.MTOW/out.wing.WS_LDmax;

%% ======================= useful weight fractions ========================
% battery fraction is especially important for this design because battery
% mass is currently a very large part of mtow

out.battery_fraction = W.battery/out.MTOW;

out.empty_fraction = W.empty/out.MTOW;

%% ======================= convergence information ========================
out.iterations = i;

out.history = hist(1:i,:);

out.converged = abs(hist(i,2) - hist(i,1)) < TOL;

% store the final input structure with the result so each run remains traceable

out.msn = msn;

%% ======================= final constraint diagram =======================
% redraw the constraint diagram using the final converged drag, wing loading,
% and blown lift coefficients

AEGAconstraint(out.msn,out.CD0,true,out.WSR,out.CLmax,out.CLmax_TO)

end

%% =========================================================================
%% local function: blown-wing model
% evaluates either landing or takeoff blown lift using the actual propeller
% diameters, actual propeller locations, tapered wing chord, and flap region

function [CL_blown,bw] = sizing_blown_wing(msn,DG,lift_cfg,PTO)

KT2FPS = 1.688;
W2KW = 737.56;

rho = msn.rho_SL;

%% wing geometry
S_ref = msn.SW;
b_ref = msn.SPAN;

semi = b_ref/2;

c_root = 2*S_ref/(b_ref*(1 + msn.TR));
c_tip = msn.TR*c_root;

y_root = msn.WFus/2;

%% propeller geometry
% aegaprop returns the root-to-tip layout for one wing

[D_equiv,A_tot,~,~,layout] = AEGAprop(msn,S_ref);

D_side = layout.D_side;
y_prop = layout.y_side;

A_side = pi*(D_side/2).^2;

%% flight condition
switch lift_cfg

    case 'landing'

        % evaluate blowing at the specified landing stall speed

        u0 = msn.VS0*KT2FPS;

        % calculate the unblown landing clmax from the actual tapered wing
        % area covered by the flap

        [CL_base,flap_area_frac] = landing_cl_base(msn,S_ref,b_ref);

        CDi = CL_base^2/(pi*msn.AR*msn.e_osw);

        % update flap drag using the actual flapped planform fraction

        dCD_flap = msn.CD_flap_factor...
                   *msn.flap_chord_frac...
                   *flap_area_frac...
                   *sind(msn.flap_def_L)^2;

        q0 = 0.5*rho*u0^2;

        D_land = q0*S_ref*(msn.CD0 + dCD_flap + CDi);

        % thrust required during the specified descent angle

        T_tot = max(D_land - DG*sind(msn.approach_angle),0);

    case 'takeoff'

        if isempty(PTO)
            error('takeoff blown-wing calculation requires PTO.')
        end

        CL_base = msn.CLmax_TO;

        flap_area_frac = NaN;

        % evaluate takeoff blowing near liftoff speed

        u0 = 1.1*sqrt(2*msn.WS/(rho*CL_base));

        % convert installed shaft power into ideal slipstream power

        Pid = msn.prof*PTO*W2KW;

        rA = rho*A_tot;

        % actuator-disk solution for induced velocity

        vi = fzero(@(v) 2*rA*v*(u0 + v)^2 - Pid,[0 500]);

        T_tot = 2*rA*vi*(u0 + vi);

    otherwise

        error('lift_cfg must be landing or takeoff.')
end

%% distribute thrust across the propellers
% equal disk loading is assumed, so each prop receives thrust proportional
% to its individual disk area

T_side = (T_tot/2)*(A_side/sum(A_side));

%% integrate local blown lift
delta_CL = 0;

S_blown_half = 0;

M_half = 0;

for j = 1:length(D_side)

    Aprop = A_side(j);
    Tprop = T_side(j);

    %% local slipstream velocity
    if Tprop > 0

        ue = u0*sqrt(1 + Tprop/(0.5*rho*Aprop*u0^2));

        q_ratio = (ue/u0)^2;

        % approximate wake contraction between the propeller and wing

        prop_factor = sqrt((u0 + ue)/(2*ue));

    else

        q_ratio = 1;
        prop_factor = 1;
    end

    %% local portion of wing inside this slipstream
    wake_width = prop_factor*D_side(j);

    y1 = max(y_prop(j) - wake_width/2,y_root);
    y2 = min(y_prop(j) + wake_width/2,semi);

    Sstrip_half = trapezoid_wing_area(y1,y2,c_root,c_tip,semi);

    %% local lift weighting
    % landing gives extra cl weighting to the portion of the strip over the flap
    % takeoff currently uses the common input clmax_to across the strip

    if strcmp(lift_cfg,'landing')

        lift_weight_half = local_landing_cl_area...
            (msn,y1,y2,c_root,c_tip,semi,y_root);

    else

        lift_weight_half = CL_base*Sstrip_half;
    end

    %% add the dynamic-pressure lift increase
    delta_CL = delta_CL...
               + 2*lift_weight_half/S_ref*(q_ratio - 1);

    S_blown_half = S_blown_half + Sstrip_half;

    %% spanwise propulsive moment
    % this is a load-location proxy rather than a full structural bending model

    M_half = M_half + Tprop*y_prop(j);
end

%% total blown lift coefficient
CL_blown = CL_base + delta_CL;

CL_blown = min(CL_blown,msn.CLmax_cap);

%% blown wing area
blown_area_frac = min(2*S_blown_half/S_ref,1);

%% normalized spanwise thrust moment
% a value of 1 would correspond to all half-wing thrust acting at the tip
% lower values mean propulsion is concentrated farther inboard

if T_tot > 0
    thrust_moment_norm = M_half/((T_tot/2)*semi);
else
    thrust_moment_norm = 0;
end

%% diagnostic outputs
bw.CL_base = CL_base;
bw.CL_blown = CL_blown;

bw.blown_area_frac = blown_area_frac;

bw.thrust_moment_norm = thrust_moment_norm;

bw.Ttotal = T_tot;

bw.Adisc = A_tot;

bw.D_equiv = D_equiv;
bw.D_side = D_side;
bw.y_side = y_prop;

bw.c_root = c_root;
bw.c_tip = c_tip;

bw.flap_area_frac = flap_area_frac;

bw.WS_VS0_limit = 0.5*rho*(msn.VS0*KT2FPS)^2*CL_blown;

end

%% =========================================================================
%% local function: unblown landing clmax
% calculates how much actual tapered-wing planform lies inside the flap span
% rather than assuming the original fixed 0.69 wing-area fraction

function [CL_base,flap_area_frac] = landing_cl_base(msn,S_ref,b_ref)

semi = b_ref/2;

c_root = 2*S_ref/(b_ref*(1 + msn.TR));
c_tip = msn.TR*c_root;

y_root = msn.WFus/2;

if isfield(msn,'flap_span_frac') && ~isempty(msn.flap_span_frac)
    y_flap_end = msn.flap_span_frac*semi;
else
    y_flap_end = 0.80*semi;
end

y_flap_end = min(y_flap_end,semi);

Aflap_half = trapezoid_wing_area...
    (y_root,y_flap_end,c_root,c_tip,semi);

flap_area_frac = 2*Aflap_half/S_ref;

% local section clmax increment from the deployed flap

dcl_flap_local = msn.dclmax_flap_L*msn.K_flap_sweep;

% wing clmax equals clean clmax plus the flap increment weighted by area

CL_base = msn.CLmax_clean...
          + dcl_flap_local*flap_area_frac;

end

%% =========================================================================
%% local function: cl-weighted area of one landing slipstream strip
% part of a slipstream may lie over the flap and part may lie over clean wing
% this function weights those two regions separately

function CLA = local_landing_cl_area...
    (msn,y1,y2,c_root,c_tip,semi,y_root)

Astrip = trapezoid_wing_area...
    (y1,y2,c_root,c_tip,semi);

if isfield(msn,'flap_span_frac') && ~isempty(msn.flap_span_frac)
    y_flap_end = msn.flap_span_frac*semi;
else
    y_flap_end = 0.80*semi;
end

y_flap_end = min(y_flap_end,semi);

% portion of this strip that lies inside the flap span

yf1 = max(y1,y_root);
yf2 = min(y2,y_flap_end);

Aflap = trapezoid_wing_area...
    (yf1,yf2,c_root,c_tip,semi);

dcl_flap_local = msn.dclmax_flap_L*msn.K_flap_sweep;

% clean lift contribution applies over the entire strip
% flap increment only applies to the portion covered by the flap

CLA = msn.CLmax_clean*Astrip...
      + dcl_flap_local*Aflap;

end

%% =========================================================================
%% local function: tapered-wing strip area
% local chord varies linearly from root to tip
%
% integrating c(y) between y1 and y2 gives the actual planform area under
% a propeller slipstream

function A = trapezoid_wing_area...
    (y1,y2,c_root,c_tip,semi)

if y2 <= y1
    A = 0;
    return
end

slope = (c_tip - c_root)/semi;

A = c_root*(y2 - y1)...
    + 0.5*slope*(y2^2 - y1^2);

end
function [residual,CL_TO,bw_TO,con] = takeoff_power_balance(P,msn,DG,CD0,WS,CL_L)
[CL_TO,bw_TO] = sizing_blown_wing(msn,DG,'takeoff',P);
con = AEGAconstraint(msn,CD0,false,WS,CL_L,CL_TO);
residual = P - con.PW_kWkg*DG/2.20462;
end
