clear
close all
clc
%% blown-wing propulsor trade studies
% trade 1 checks equal-size propeller count and total disk area at fixed
% total shaft power rather than fixed thrust.
% trade 2 compares equal, two-size, and smoothly graded diameter families at
% fixed total disk area.
% trade 3 directly checks the original taper question by sweeping wing taper
% ratio and inboard diameter bias together.
% trade 4 keeps the free four-diameter search available, but it is off by
% default because trade 3 is more useful for the current design question.
%
% every layout is packed from the fuselage outward using actual propeller
% diameters plus a fixed tip-to-tip gap. unused span remains at the wing tip.
%
% the blown-lift calculation accounts for trapezoidal wing chord variation.
% it also treats the inner flapped region separately from the outer clean
% region when weighting the local slipstream lift increment.
msn = AEGAinputs();
DG = 2800;
CD0 = 0.026;
RUN_FREE_SWEEP = false;
%% trade 1: equal-size props, prop count vs total disk area at fixed power
SW1 = 100;
AR1 = 9.0;
TR1 = 0.45;
Nprop_vec = [6 8 10];
Adisc_vec = 25:2.5:40;
Adisc_ref1 = 35;
Treq1 = approach_thrust_required(msn,DG,CD0,SW1,AR1,TR1);
rho1 = msn.rho_SL;
u01 = msn.VS0*1.688;
ue_ref1 = u01*sqrt(1 + Treq1/(0.5*rho1*Adisc_ref1*u01^2));
Pair_ref1 = Treq1*(u01 + ue_ref1)/2;
FTLBS_TO_KW = 0.00135581795;
Pshaft1_kW = Pair_ref1*FTLBS_TO_KW/msn.etap_cl
CL1 = nan(length(Nprop_vec),length(Adisc_vec));
Pblown1 = nan(size(CL1));
Moment1 = nan(size(CL1));
ThrustRatio1 = nan(size(CL1));
Dprop1 = nan(size(CL1));
for iN = 1:length(Nprop_vec)
    N = Nprop_vec(iN);
    if mod(N,2) ~= 0
        error('trade 1 requires an even number of propellers.')
    end
    Nside = N/2;
    for iA = 1:length(Adisc_vec)
        Adisc = Adisc_vec(iA);
        D = sqrt(4*Adisc/(N*pi));
        D_side = D*ones(1,Nside);
        result = evaluate_blown_layout(msn,DG,CD0,SW1,AR1,TR1,D_side,'power',Pshaft1_kW);
        if result.fits
            CL1(iN,iA) = result.CL_blown;
            Pblown1(iN,iA) = result.blown_area_frac;
            Moment1(iN,iA) = result.thrust_moment_norm;
            ThrustRatio1(iN,iA) = result.Ttotal/Treq1;
            Dprop1(iN,iA) = D;
        end
    end
end
figure('Name','Trade 1 - Prop Count vs Disk Area at Fixed Power','Color','w')
tiledlayout(2,2)
nexttile
h = imagesc(Adisc_vec,Nprop_vec,CL1);
set(h,'AlphaData',~isnan(CL1))
set(gca,'YDir','normal')
colorbar
xlabel('Total Disk Area, ft^2')
ylabel('Number of Propellers')
title('Blown Landing C_{L,max}')
nexttile
h = imagesc(Adisc_vec,Nprop_vec,Pblown1);
set(h,'AlphaData',~isnan(Pblown1))
set(gca,'YDir','normal')
colorbar
xlabel('Total Disk Area, ft^2')
ylabel('Number of Propellers')
title('Fraction of Wing Area Blown')
nexttile
h = imagesc(Adisc_vec,Nprop_vec,ThrustRatio1);
set(h,'AlphaData',~isnan(ThrustRatio1))
set(gca,'YDir','normal')
colorbar
xlabel('Total Disk Area, ft^2')
ylabel('Number of Propellers')
title('Available Thrust / Approach Thrust Required')
nexttile
h = imagesc(Adisc_vec,Nprop_vec,Moment1);
set(h,'AlphaData',~isnan(Moment1))
set(gca,'YDir','normal')
colorbar
xlabel('Total Disk Area, ft^2')
ylabel('Number of Propellers')
title('Normalized Spanwise Thrust Moment')
sgtitle(sprintf('TRADE 1: Fixed Shaft Power = %.1f kW, S = %.0f ft^2, AR = %.1f, TR = %.2f',Pshaft1_kW,SW1,AR1,TR1))
%% trade 2: equal vs two-size vs graded families
SW2 = 100;
AR2 = 9.0;
TR2 = 0.45;
NPROP2 = 8;
Adisc2 = 0.35*SW2;
if mod(NPROP2,2) ~= 0
    error('trade 2 requires an even number of propellers.')
end
Nside2 = NPROP2/2;
if Nside2 ~= 4
    error('trade 2 is written for four propellers per wing.')
end
root_tip_vec = 1.00:0.05:1.60;
CL_equal = nan(size(root_tip_vec));
CL_two = nan(size(root_tip_vec));
CL_graded = nan(size(root_tip_vec));
Moment_equal = nan(size(root_tip_vec));
Moment_two = nan(size(root_tip_vec));
Moment_graded = nan(size(root_tip_vec));
Pblown_equal = nan(size(root_tip_vec));
Pblown_two = nan(size(root_tip_vec));
Pblown_graded = nan(size(root_tip_vec));
D_equal_family = nan(length(root_tip_vec),Nside2);
D_two_family = nan(length(root_tip_vec),Nside2);
D_graded_family = nan(length(root_tip_vec),Nside2);
for iR = 1:length(root_tip_vec)
    r = root_tip_vec(iR);
    ratio_equal = [1 1 1 1];
    ratio_two = [r r 1 1];
    ratio_graded = [r 1 + (2/3)*(r - 1) 1 + (1/3)*(r - 1) 1];
    D_equal = scale_ratios_to_disk_area(ratio_equal,Adisc2);
    D_two = scale_ratios_to_disk_area(ratio_two,Adisc2);
    D_graded = scale_ratios_to_disk_area(ratio_graded,Adisc2);
    result_equal = evaluate_blown_layout(msn,DG,CD0,SW2,AR2,TR2,D_equal,'approach',[]);
    result_two = evaluate_blown_layout(msn,DG,CD0,SW2,AR2,TR2,D_two,'approach',[]);
    result_graded = evaluate_blown_layout(msn,DG,CD0,SW2,AR2,TR2,D_graded,'approach',[]);
    if result_equal.fits
        CL_equal(iR) = result_equal.CL_blown;
        Moment_equal(iR) = result_equal.thrust_moment_norm;
        Pblown_equal(iR) = result_equal.blown_area_frac;
        D_equal_family(iR,:) = D_equal;
    end
    if result_two.fits
        CL_two(iR) = result_two.CL_blown;
        Moment_two(iR) = result_two.thrust_moment_norm;
        Pblown_two(iR) = result_two.blown_area_frac;
        D_two_family(iR,:) = D_two;
    end
    if result_graded.fits
        CL_graded(iR) = result_graded.CL_blown;
        Moment_graded(iR) = result_graded.thrust_moment_norm;
        Pblown_graded(iR) = result_graded.blown_area_frac;
        D_graded_family(iR,:) = D_graded;
    end
end
figure('Name','Trade 2 - Diameter Distribution Families','Color','w')
tiledlayout(1,3)
nexttile
plot(root_tip_vec,CL_equal,'-o',root_tip_vec,CL_two,'-o',root_tip_vec,CL_graded,'-o')
xlabel('D_1 / D_4')
ylabel('Blown Landing C_{L,max}')
legend('Equal','Two-size','Graded','Location','best')
grid on
nexttile
plot(root_tip_vec,Pblown_equal,'-o',root_tip_vec,Pblown_two,'-o',root_tip_vec,Pblown_graded,'-o')
xlabel('D_1 / D_4')
ylabel('Fraction of Wing Area Blown')
legend('Equal','Two-size','Graded','Location','best')
grid on
nexttile
plot(root_tip_vec,Moment_equal,'-o',root_tip_vec,Moment_two,'-o',root_tip_vec,Moment_graded,'-o')
xlabel('D_1 / D_4')
ylabel('Normalized Spanwise Thrust Moment')
legend('Equal','Two-size','Graded','Location','best')
grid on
sgtitle(sprintf('TRADE 2: Fixed A_{disc} = %.1f ft^2, N = %d, S = %.0f ft^2, AR = %.1f, TR = %.2f',Adisc2,NPROP2,SW2,AR2,TR2))
%% trade 3: wing taper ratio vs inboard propeller bias
TR_vec = 0.30:0.05:0.70;
root_tip_taper_vec = 1.00:0.05:1.60;
dCL3 = nan(length(TR_vec),length(root_tip_taper_vec));
dArea3 = nan(size(dCL3));
MomentReduction3 = nan(size(dCL3));
for iTR = 1:length(TR_vec)
    TR = TR_vec(iTR);
    for iR = 1:length(root_tip_taper_vec)
        r = root_tip_taper_vec(iR);
        ratio_equal = [1 1 1 1];
        ratio_graded = [r 1 + (2/3)*(r - 1) 1 + (1/3)*(r - 1) 1];
        D_equal = scale_ratios_to_disk_area(ratio_equal,Adisc2);
        D_graded = scale_ratios_to_disk_area(ratio_graded,Adisc2);
        result_equal = evaluate_blown_layout(msn,DG,CD0,SW2,AR2,TR,D_equal,'approach',[]);
        result_graded = evaluate_blown_layout(msn,DG,CD0,SW2,AR2,TR,D_graded,'approach',[]);
        if result_equal.fits && result_graded.fits
            dCL3(iTR,iR) = result_graded.CL_blown - result_equal.CL_blown;
            dArea3(iTR,iR) = result_graded.blown_area_frac - result_equal.blown_area_frac;
            MomentReduction3(iTR,iR) = 100*(1 - result_graded.thrust_moment_norm/result_equal.thrust_moment_norm);
        end
    end
end
figure('Name','Trade 3 - Wing Taper vs Inboard Prop Bias','Color','w')
tiledlayout(1,3)
nexttile
h = imagesc(root_tip_taper_vec,TR_vec,dCL3);
set(h,'AlphaData',~isnan(dCL3))
set(gca,'YDir','normal')
colorbar
xlabel('D_1 / D_4')
ylabel('Wing Taper Ratio')
title('\Delta C_{L,max}: Graded - Equal')
nexttile
h = imagesc(root_tip_taper_vec,TR_vec,dArea3);
set(h,'AlphaData',~isnan(dArea3))
set(gca,'YDir','normal')
colorbar
xlabel('D_1 / D_4')
ylabel('Wing Taper Ratio')
title('\Delta Blown Wing Area Fraction')
nexttile
h = imagesc(root_tip_taper_vec,TR_vec,MomentReduction3);
set(h,'AlphaData',~isnan(MomentReduction3))
set(gca,'YDir','normal')
colorbar
xlabel('D_1 / D_4')
ylabel('Wing Taper Ratio')
title('Spanwise Thrust Moment Reduction, %')
sgtitle(sprintf('TRADE 3: Taper vs Graded Inboard Bias, A_{disc} = %.1f ft^2, N = %d, AR = %.1f',Adisc2,NPROP2,AR2))
%% trade 4: optional free four-diameter sweep
if RUN_FREE_SWEEP
    r1_vec = 1.00:0.05:1.60;
    r2_vec = 1.00:0.05:1.40;
    r3_vec = 1.00:0.05:1.20;
    max_cases = length(r1_vec)*length(r2_vec)*length(r3_vec);
    Rall = nan(max_cases,4);
    Dall = nan(max_cases,4);
    CLall = nan(max_cases,1);
    Pblownall = nan(max_cases,1);
    Momentall = nan(max_cases,1);
    TipClearall = nan(max_cases,1);
    case_count = 0;
    for i1 = 1:length(r1_vec)
        for i2 = 1:length(r2_vec)
            for i3 = 1:length(r3_vec)
                ratios = [r1_vec(i1) r2_vec(i2) r3_vec(i3) 1];
                if any(diff(ratios) > 0)
                    continue
                end
                D_side = scale_ratios_to_disk_area(ratios,Adisc2);
                result = evaluate_blown_layout(msn,DG,CD0,SW2,AR2,TR2,D_side,'approach',[]);
                if ~result.fits
                    continue
                end
                case_count = case_count + 1;
                Rall(case_count,:) = ratios;
                Dall(case_count,:) = D_side;
                CLall(case_count) = result.CL_blown;
                Pblownall(case_count) = result.blown_area_frac;
                Momentall(case_count) = result.thrust_moment_norm;
                TipClearall(case_count) = result.tip_clearance;
            end
        end
    end
    Rall = Rall(1:case_count,:);
    Dall = Dall(1:case_count,:);
    CLall = CLall(1:case_count);
    Pblownall = Pblownall(1:case_count);
    Momentall = Momentall(1:case_count);
    TipClearall = TipClearall(1:case_count);
    pareto = pareto_mask(CLall,Momentall);
    trade4 = table(Rall(:,1),Rall(:,2),Rall(:,3),Rall(:,4),Dall(:,1),Dall(:,2),Dall(:,3),Dall(:,4),CLall,Pblownall,Momentall,TipClearall,pareto,'VariableNames',{'R1','R2','R3','R4','D1_ft','D2_ft','D3_ft','D4_ft','CLmax','BlownAreaFrac','SpanwiseThrustMoment','TipClearance_ft','Pareto'});
    [~,iBestCL] = max(CLall);
    [~,iBestMoment] = min(Momentall);
    best_CL_case = trade4(iBestCL,:)
    lowest_moment_case = trade4(iBestMoment,:)
    pareto_table = sortrows(trade4(pareto,:),{'SpanwiseThrustMoment','CLmax'},{'ascend','descend'})
    figure('Name','Trade 4 - Free Graded Sweep','Color','w')
    scatter(Momentall,CLall,45,Rall(:,1),'filled')
    hold on
    scatter(Momentall(pareto),CLall(pareto),90,'Marker','o','LineWidth',1.5)
    xlabel('Normalized Spanwise Thrust Moment')
    ylabel('Blown Landing C_{L,max}')
    cb = colorbar;
    cb.Label.String = 'D_1 / D_4';
    grid on
    title('Optional Free Four-Diameter Sweep and Pareto Set')
end
%% local function: evaluate one blown-wing layout
function out = evaluate_blown_layout(msn,DG,CD0,SW,AR,TR,D_side,mode,value)
KT2FPS = 1.688;
KW_TO_FTLBS = 1/0.00135581795;
rho = msn.rho_SL;
u0 = msn.VS0*KT2FPS;
Nside = length(D_side);
N = 2*Nside;
span = sqrt(AR*SW);
semi = span/2;
c_root = 2*SW/(span*(1 + TR));
c_tip = TR*c_root;
[y_prop,gap,fits,tip_clearance] = pack_propellers(msn,span,D_side);
out.fits = fits;
if ~fits
    out.CL_blown = NaN;
    out.blown_area_frac = NaN;
    out.thrust_moment_norm = NaN;
    out.tip_clearance = tip_clearance;
    out.Ttotal = NaN;
    return
end
A_side = pi*(D_side/2).^2;
A_tot = 2*sum(A_side);
if A_tot <= 0
    error('total propeller disk area must be positive.')
end
if strcmp(mode,'approach')
    T_tot = approach_thrust_required(msn,DG,CD0,SW,AR,TR);
elseif strcmp(mode,'power')
    Pshaft_kW = value;
    Pair = msn.etap_cl*Pshaft_kW*KW_TO_FTLBS;
    if Pair <= 0
        ue_common = u0;
        T_tot = 0;
    else
        power_fun = @(ue) 0.25*rho*A_tot*(ue^2 - u0^2)*(u0 + ue) - Pair;
        ue_hi = max(1.05*u0,u0 + 10);
        while power_fun(ue_hi) < 0
            ue_hi = u0 + 2*(ue_hi - u0);
        end
        ue_common = fzero(power_fun,[u0 ue_hi]);
        T_tot = 0.5*rho*A_tot*(ue_common^2 - u0^2);
    end
else
    error('mode must be approach or power.')
end
T_side = (T_tot/2)*(A_side/sum(A_side));
y_root_available = msn.WFus/2;
[CL_base,~] = landing_flap_model(msn,SW,AR,TR);
delta_CL = 0;
S_blown_half = 0;
M_half = 0;
for j = 1:Nside
    Aprop = A_side(j);
    Tprop = T_side(j);
    if Tprop > 0
        ue = u0*sqrt(1 + Tprop/(0.5*rho*Aprop*u0^2));
        q_ratio = (ue/u0)^2;
        prop_factor = sqrt((u0 + ue)/(2*ue));
    else
        q_ratio = 1;
        prop_factor = 1;
    end
    wake_width = prop_factor*D_side(j);
    y1 = max(y_prop(j) - wake_width/2,y_root_available);
    y2 = min(y_prop(j) + wake_width/2,semi);
    Sstrip_half = trapezoid_wing_area(y1,y2,c_root,c_tip,semi);
    lift_weight_half = local_cl_area(msn,y1,y2,c_root,c_tip,semi,y_root_available);
    delta_CL = delta_CL + 2*lift_weight_half/SW*(q_ratio - 1);
    S_blown_half = S_blown_half + Sstrip_half;
    M_half = M_half + Tprop*y_prop(j);
end
CL_blown = CL_base + delta_CL;
if isfield(msn,'CLmax_cap')
    CL_blown = min(CL_blown,msn.CLmax_cap);
end
blown_area_frac = min(2*S_blown_half/SW,1);
if T_tot > 0
    thrust_moment_norm = M_half/((T_tot/2)*semi);
else
    thrust_moment_norm = 0;
end
out.CL_blown = CL_blown;
out.blown_area_frac = blown_area_frac;
out.thrust_moment_norm = thrust_moment_norm;
out.span = span;
out.c_root = c_root;
out.c_tip = c_tip;
out.y_prop = y_prop;
out.gap = gap;
out.tip_clearance = tip_clearance;
out.Adisc = A_tot;
out.Ttotal = T_tot;
out.NPROP = N;
end
%% local function: approach thrust required by the current landing model
function Treq = approach_thrust_required(msn,DG,CD0,SW,AR,TR)
rho = msn.rho_SL;
u0 = msn.VS0*1.688;
[CL,dCD_flap] = landing_flap_model(msn,SW,AR,TR);
CDi = CL^2/(pi*AR*msn.e_osw);
CD_land = CD0 + CDi + dCD_flap;
q0 = 0.5*rho*u0^2;
D_land = q0*SW*CD_land;
Treq = max(D_land - DG*sind(msn.approach_angle),0);
end
%% local function: pack props from the fuselage outward
function [y_prop,gap,fits,tip_clearance] = pack_propellers(msn,span,D_side)
Nside = length(D_side);
semi = span/2;
y_root = msn.WFus/2;
usable_half_span = semi - y_root;
pitch_ref = usable_half_span/Nside;
if isfield(msn,'prop_gap')
    gap = msn.prop_gap;
else
    gap = (1 - msn.fill)*pitch_ref;
end
edge_gap = gap/2;
y_prop = zeros(1,Nside);
y_prop(1) = y_root + edge_gap + D_side(1)/2;
for j = 2:Nside
    y_prop(j) = y_prop(j - 1) + D_side(j - 1)/2 + gap + D_side(j)/2;
end
outer_edge = y_prop(end) + D_side(end)/2;
tip_clearance = semi - outer_edge;
fits = tip_clearance >= edge_gap - 1e-10;
end
%% local function: scale a diameter ratio vector to fixed total disk area
function D_side = scale_ratios_to_disk_area(ratios,Adisc_total)
ratios = ratios(:).';
scale = sqrt(2*Adisc_total/(pi*sum(ratios.^2)));
D_side = scale*ratios;
end
%% local function: trapezoidal wing strip area
function A = trapezoid_wing_area(y1,y2,c_root,c_tip,semi)
if y2 <= y1
    A = 0;
    return
end
slope = (c_tip - c_root)/semi;
A = c_root*(y2 - y1) + 0.5*slope*(y2^2 - y1^2);
end
%% local function: local cl-weighted area inside a slipstream strip
function CLA = local_cl_area(msn,y1,y2,c_root,c_tip,semi,y_root)
Astrip = trapezoid_wing_area(y1,y2,c_root,c_tip,semi);
CLclean = msn.CLmax_clean;
y_flap_end = flap_end(msn,semi);
yf1 = max(y1,y_root);
yf2 = min(y2,y_flap_end);
Aflap = trapezoid_wing_area(yf1,yf2,c_root,c_tip,semi);
dcl_flap_local = 0;
if isfield(msn,'dclmax_flap_L') && isfield(msn,'K_flap_sweep')
    dcl_flap_local = msn.dclmax_flap_L*msn.K_flap_sweep;
end
CLA = CLclean*Astrip + dcl_flap_local*Aflap;
end
%% local function: maximize cl while minimizing spanwise thrust moment
function mask = pareto_mask(CL,M)
n = length(CL);
mask = true(n,1);
for i = 1:n
    if isnan(CL(i)) || isnan(M(i))
        mask(i) = false;
        continue
    end
    dominates_i = (CL >= CL(i) & M <= M(i)) & (CL > CL(i) | M < M(i));
    if any(dominates_i)
        mask(i) = false;
    end
end
end


function y_end = flap_end(msn,semi)
if isfield(msn,'flap_span_frac') && ~isempty(msn.flap_span_frac)
    frac = msn.flap_span_frac;
else
    frac = 0.80;
end
y_end = min(frac*semi,semi);
end

function [CL_base,dCD_flap] = landing_flap_model(msn,SW,AR,TR)
% Match the tapered-wing flap treatment in AEGAsize.
span = sqrt(AR*SW);
semi = span/2;
c_root = 2*SW/(span*(1 + TR));
c_tip = TR*c_root;
Aflap_half = trapezoid_wing_area(msn.WFus/2,flap_end(msn,semi), ...
    c_root,c_tip,semi);
flap_area_frac = 2*Aflap_half/SW;
CL_base = msn.CLmax_clean ...
    + msn.dclmax_flap_L*msn.K_flap_sweep*flap_area_frac;
dCD_flap = msn.CD_flap_factor*msn.flap_chord_frac ...
    *flap_area_frac*sind(msn.flap_def_L)^2;
end