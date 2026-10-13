function [CL_blown,bw] = blow_wind(msn,DG,lift_cfg,PTO)
if nargin < 3
    error('please provide msn, DG, and lift configuration.')
end
%% constants
KT2FPS = 1.688;
W2KW = 737.56;
rho = msn.rho_SL;
%% geometry
S_ref = msn.SW;
b_ref = msn.SPAN;
semi = b_ref/2;
c_root = 2*S_ref/(b_ref*(1 + msn.TR));
c_tip = msn.TR*c_root;
y_root = msn.WFus/2;
[D_equiv,A_tot,~,~,layout] = AEGAprop(msn,S_ref);
D_side = layout.D_side;
y_prop = layout.y_side;
A_side = pi*(D_side/2).^2;
%% flight condition
switch lift_cfg
    case 'landing'
        u_0 = msn.VS0*KT2FPS;
        [CL_base,flap_area_frac] = landing_cl_base(msn,S_ref,b_ref);
        CDi = CL_base^2/(pi*msn.AR*msn.e_osw);
        dCD_flap = msn.CD_flap_factor*msn.flap_chord_frac*flap_area_frac*sind(msn.flap_def_L)^2;
        q0 = 0.5*rho*u_0^2;
        D_land = q0*S_ref*(msn.CD0 + dCD_flap + CDi);
        T_tot = max(D_land - DG*sind(msn.approach_angle),0);
    case 'takeoff'
        if nargin < 4 || isempty(PTO)
            error('takeoff requires installed shaft power PTO.')
        end
        CL_base = msn.CLmax_TO;
        flap_area_frac = NaN;
        u_0 = 1.1*sqrt(2*msn.WS/(rho*CL_base));
        Pid = msn.prof*PTO*W2KW;
        rA = rho*A_tot;
        vi = fzero(@(v) 2*rA*v*(u_0 + v)^2 - Pid,[0 500]);
        T_tot = 2*rA*vi*(u_0 + vi);
    otherwise
        error('lift_cfg must be landing or takeoff.')
end
%% distribute thrust by disk area
T_side = (T_tot/2)*(A_side/sum(A_side));
delta_CL = 0;
S_blown_half = 0;
M_half = 0;
for j = 1:length(D_side)
    Aprop = A_side(j);
    Tprop = T_side(j);
    if Tprop > 0
        u_e = u_0*sqrt(1 + Tprop/(0.5*rho*Aprop*u_0^2));
        q_ratio = (u_e/u_0)^2;
        prop_factor = sqrt((u_0 + u_e)/(2*u_e));
    else
        q_ratio = 1;
        prop_factor = 1;
    end
    wake_width = prop_factor*D_side(j);
    y1 = max(y_prop(j) - wake_width/2,y_root);
    y2 = min(y_prop(j) + wake_width/2,semi);
    Sstrip_half = trapezoid_wing_area(y1,y2,c_root,c_tip,semi);
    if strcmp(lift_cfg,'landing')
        lift_weight_half = local_landing_cl_area(msn,y1,y2,c_root,c_tip,semi,y_root);
    else
        lift_weight_half = CL_base*Sstrip_half;
    end
    delta_CL = delta_CL + 2*lift_weight_half/S_ref*(q_ratio - 1);
    S_blown_half = S_blown_half + Sstrip_half;
    M_half = M_half + Tprop*y_prop(j);
end
CL_blown = CL_base + delta_CL;
CL_blown = min(CL_blown,msn.CLmax_cap);
blown_area_frac = min(2*S_blown_half/S_ref,1);
if T_tot > 0
    thrust_moment_norm = M_half/((T_tot/2)*semi);
else
    thrust_moment_norm = 0;
end
%% outputs
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
function [CL_base,flap_area_frac] = landing_cl_base(msn,S_ref,b_ref)
semi = b_ref/2;
c_root = 2*S_ref/(b_ref*(1 + msn.TR));
c_tip = msn.TR*c_root;
y_root = msn.WFus/2;
if isfield(msn,'flap_span_frac')
    y_flap_end = msn.flap_span_frac*semi;
else
    y_flap_end = 0.80*semi;
end
Aflap_half = trapezoid_wing_area(y_root,y_flap_end,c_root,c_tip,semi);
flap_area_frac = 2*Aflap_half/S_ref;
dcl_flap_local = msn.dclmax_flap_L*msn.K_flap_sweep;
CL_base = msn.CLmax_clean + dcl_flap_local*flap_area_frac;
end
function CLA = local_landing_cl_area(msn,y1,y2,c_root,c_tip,semi,y_root)
Astrip = trapezoid_wing_area(y1,y2,c_root,c_tip,semi);
if isfield(msn,'flap_span_frac')
    y_flap_end = msn.flap_span_frac*semi;
else
    y_flap_end = 0.80*semi;
end
yf1 = max(y1,y_root);
yf2 = min(y2,y_flap_end);
Aflap = trapezoid_wing_area(yf1,yf2,c_root,c_tip,semi);
dcl_flap_local = msn.dclmax_flap_L*msn.K_flap_sweep;
CLA = msn.CLmax_clean*Astrip + dcl_flap_local*Aflap;
end
function A = trapezoid_wing_area(y1,y2,c_root,c_tip,semi)
if y2 <= y1
    A = 0;
    return
end
slope = (c_tip - c_root)/semi;
A = c_root*(y2 - y1) + 0.5*slope*(y2^2 - y1^2);
end