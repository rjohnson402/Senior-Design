function review = AEGAinputreview2035(m)
% Updated reference geometry and one-at-a-time assumption sensitivity.
root=AEGAroot();
folder=fullfile(root,'input_review'); if ~isfolder(folder), mkdir(folder); end
if nargin<1, m=AEGAinputs(); end
cfg=AEGAstudysettings2035(m); [a,o]=AEGAstudycase2035(m,cfg);
reference=AEGAsize(a,m.WS_design,o);
assert(reference.feasible,'Updated reference must pass the enabled screens.');
cases={ 'Current reference','',NaN; 'Prior drag, same current geometry policy','legacy_drag',1; ...
    'Pack 350 Wh/kg','whkg',350; 'Pack 450 Wh/kg','whkg',450; ...
    'No fuselage composite reduction','fuselage_mass_factor',1; ...
    'Motor 10 kW/kg','kWkg_m',10; 'Thermal system 0.12 kg/kW','kgkW_th',.12; ...
    'Installation hardware 160 lb','dWinst',160; ...
    'Assigned 300 nm mission','range',300; ...
    'Clean CLmax 1.4','CLmax_clean',1.4; ...
    'Flap section lift increment 1.2','dclmax_flap_L',1.2; ...
    'Lower flap drag factor 0.8','CD_flap_factor',.8; ...
    'Clean parasite drag +10 percent','CD0_scale',1.1; ...
    'Clean parasite drag -10 percent','CD0_scale',.9; ...
    'Conditional reverse 5 percent, with hardware','reverse_concept',.05; ...
    'Failed disk drag coefficient 0.02','failed_disk_CD',.02; ...
    '3-ft cruise / 2-ft high-lift comparison','smaller_props',3};
rows=cell(size(cases,1),1); details=cell(size(cases,1),1);
for j=1:size(cases,1)
    mm=m; cc=cfg; override=cases{j,2}; value=cases{j,3};
    if ~isempty(override) && isfield(mm,override), mm.(override)=value; end
    if strcmp(override,'legacy_drag'), mm.e_osw=.8; mm.drag_buildup_scale=1; end
    if strcmp(override,'reverse_concept'), mm=AEGAreversecase2035(mm,value); end
    if strcmp(override,'smaller_props'), cc.cruise_diameter_ft=3; cc.high_lift_diameter_ft=2; end
    mm.dCLmax_L_flap=mm.dclmax_flap_L*mm.flap_area_frac*mm.K_flap_sweep;
    mm.CLmax_L=mm.CLmax_clean+mm.dCLmax_L_flap;
    if isfield(mm,'dCLmax_TO_flap'), mm.CLmax_TO=mm.CLmax_clean+mm.dCLmax_TO_flap; end
    mm.dCD_flap_L=mm.CD_flap_factor*mm.flap_chord_frac*mm.flap_area_frac*sind(mm.flap_def_L)^2;
    cc.technology.wing_mass_factor=mm.wing_mass_factor;
    [aa,oo]=AEGAstudycase2035(mm,cc);
    if strcmp(override,'CD0_scale'), oo.CD0_scale=value; end
    if strcmp(override,'failed_disk_CD'), oo.eo=struct('failed_disk_CD',value); end
    r=AEGAsize(aa,mm.WS_design,oo); details{j}=r;
    rows{j}=struct('Case',string(cases{j,1}),'MTOW_lb',r.MTOW, ...
        'DeltaMTOW_lb',r.MTOW-reference.MTOW,'Wing_ft2',r.SW,'Span_ft',r.span, ...
        'Landing_ft',r.con.S_land_ft,'InstalledShaft_kW',r.PTO_kW, ...
        'Pack_kWh',r.pack_kWh,'PassesScreen',r.feasible,'Status',string(r.status));
end
sensitivity=struct2table(vertcat(rows{:})); writetable(sensitivity,fullfile(folder,'assumption_sensitivity.csv'));
writetable(m.polar.table,fullfile(folder,'teammate_polar_summary.csv'));
writetable(reference.operating_phases,fullfile(folder,'reference_flight_phases.csv'));
review=struct('inputs',m,'reference',reference,'sensitivity',sensitivity,'details',{details});
save(fullfile(folder,'input_review.mat'),'review');
geometry=handoff(reference,m,cfg,root);
fid=fopen(fullfile(folder,'geometry.json'),'w'); guard=onCleanup(@() fclose(fid));
fprintf(fid,'%s',jsonencode(geometry,PrettyPrint=true)); clear guard
plot_polar(m,folder); plot_geometry(geometry,folder);
fprintf('Updated input review and geometry handoff: %s\n',folder);
disp(sensitivity(:,{'Case','MTOW_lb','DeltaMTOW_lb','Landing_ft','PassesScreen'}));
end

function g=handoff(r,m,c,root)
g=struct('status','Provisional analysis reference; not a structural or trimmed design', ...
    'units','ft, ft^2, degrees, lb','MTOW_lb',r.MTOW,'wing_area_ft2',r.SW, ...
    'span_ft',r.span,'AR',m.AR,'taper',m.TR, ...
    'root_chord_ft',2*r.SW/(r.span*(1+m.TR)), 'MAC_ft',r.MAC, ...
    'sweep_quarter_chord_deg',m.SWEEP,'thickness_chord',m.TCA, ...
    'incidence_deg',1,'twist_deg',0,'dihedral_deg',3, ...
    'fuselage_length_ft',m.XL,'fuselage_width_ft',m.WFus,'fuselage_depth_ft',m.DFus, ...
    'horizontal_tail_area_ft2',r.SHT,'horizontal_tail_arm_ft',m.Lh, ...
    'vertical_tail_area_ft2',r.SVT,'vertical_tail_arm_ft',m.Lv, ...
    'cruise_prop_diameter_ft',c.cruise_diameter_ft,'high_lift_prop_diameter_ft',c.high_lift_diameter_ft, ...
    'prop_hub_y_each_side_ft',r.prop_layout.y_side, ...
    'flap_chord_fraction',m.flap_chord_frac,'flap_y_start_ft',m.WFus/2, ...
    'flap_y_end_ft',m.flap_span_frac*r.span/2, ...
    'horizontal_tail_AR',4,'horizontal_tail_taper',.5, ...
    'vertical_tail_AR',m.ARVT,'vertical_tail_taper',.5, ...
    'tail_layout','T-tail retained as an unverified layout assumption');
g.tip_chord_ft=m.TR*g.root_chord_ft;
g.sweep_LE_deg=atand(tand(m.SWEEP)+(g.root_chord_ft-g.tip_chord_ft)/(2*r.span));
g.horizontal_tail_span_ft=sqrt(g.horizontal_tail_AR*r.SHT);
g.vertical_tail_height_ft=sqrt(g.vertical_tail_AR*r.SVT);
g.vertical_tail_thickness_chord=m.TCVT;
g.cruise_CL=r.cruise_CL; g.cruise_Re_MAC=m.Vkt*1.688*r.MAC/m.nu_cr;
% ISA temperature at the stated 5000-ft analysis altitude, for solver Mach.
g.cruise_Mach=m.Vkt*.514444/sqrt(1.4*287.05287*(288.15-.0065*m.h_cr*.3048));
g.reference_Sref_ft2=r.SW; g.reference_Bref_ft=r.span; g.reference_Cref_ft=r.MAC;
g.coordinate_notes='Wing root LE may be origin for aerodynamic model; absolute fuselage wing station and CG are not established. Tail arms are AC-to-AC distances.';
g.airfoil_name=m.airfoil.name;
g.max_thickness_xc=m.airfoil.max_thickness_xc;
g.airfoil_coordinate_file=m.airfoil.coordinate_file;
g.section_clmax_2d=m.airfoil.clmax_2d; g.clean_wing_CLmax=m.CLmax_clean;
g.airfoil_notes='LS(1)-0417MOD coordinates supplied; 2D clmax is a team analysis input, with provisional finite-wing allowance. Validate Reynolds number, transition, roughness and wing stall. Tail sections/sweep require confirmation.';
fid=fopen(fullfile(root,'GEOMETRY_HANDOFF.md'),'w'); guard=onCleanup(@() fclose(fid));
fprintf(fid,'# Geometry for the next aerodynamic model\n\n');
fprintf(fid,'This fixed reference uses live input AR %.2f, taper %.2f and W/S %.2f lb/ft². Modeled reverse credit is %.0f%% of weight. It is an analysis configuration, not a validated structural or trimmed design. The optimizer''s taper endpoint remains a sensitivity until tip stall, spar depth and control layout are checked.\n\n',m.AR,m.TR,m.WS_design,100*m.reverse_TW);
fprintf(fid,'| Item | Value | Basis |\n|---|---:|---|\n');
fprintf(fid,'| Sizing mass | %.0f lb | Closed %.0f-nm / %.0f-KTAS / %.0f-minute-reserve reference |\n',r.MTOW,m.range,m.Vkt,m.reserve);
fprintf(fid,'| Wing reference area, including buried area | %.2f ft² | Gross planform |\n| Full span | %.2f ft | AR %.2f |\n',r.SW,r.span,m.AR);
fprintf(fid,'| Root chord at centerline | %.3f ft | Trapezoid |\n| Tip chord | %.3f ft | Taper %.2f |\n| Mean aerodynamic chord | %.3f ft | Use as Cref |\n',g.root_chord_ft,g.tip_chord_ft,m.TR,r.MAC);
fprintf(fid,'| Quarter-chord / leading-edge sweep | %.2f° / %.2f° | FLOPS uses quarter chord |\n| Wing airfoil | %s | Published coordinate file |\n| Wing thickness/chord | %.1f%% at %.0f%% chord | Selected section geometry |\n', ...
    g.sweep_quarter_chord_deg,g.sweep_LE_deg,g.airfoil_name,100*g.thickness_chord,100*g.max_thickness_xc);
fprintf(fid,'| Wing incidence / twist / dihedral | 1° / 0° / 3° | Analysis placeholders; incidence retained from teammate note |\n');
fprintf(fid,'| Fuselage length × width × depth | %.1f × %.2f × %.2f ft | Retained packaging placeholders, not optimized |\n',m.XL,m.WFus,m.DFus);
fprintf(fid,'| Horizontal tail area / arm | %.2f ft² / %.1f ft | Vh = .60; arm between aerodynamic centers |\n',r.SHT,m.Lh);
fprintf(fid,'| Horizontal tail AR / span / taper | 4 / %.2f ft / .50 | AR and taper are new geometry placeholders |\n',g.horizontal_tail_span_ft);
fprintf(fid,'| Vertical tail area / arm | %.2f ft² / %.1f ft | Vv = .040; AC-to-AC arm |\n',r.SVT,m.Lv);
fprintf(fid,'| Vertical tail AR / height / taper | %.2f / %.2f ft / .50 | Provisional T-tail; taper placeholder |\n',m.ARVT,g.vertical_tail_height_ft);
fprintf(fid,'| Cruise prop diameter | 2 × %.1f ft | Retained large-prop reference; compare 3.0 ft separately |\n',c.cruise_diameter_ft);
fprintf(fid,'| High-lift prop diameter | 6 × %.1f ft | Retained common reference |\n',c.high_lift_diameter_ft);
fprintf(fid,'| Prop hub distances from centerline, each side | %.2f, %.2f, %.2f, %.2f ft | Cruise hubs at wing tips; disks extend beyond span |\n',g.prop_hub_y_each_side_ft);
fprintf(fid,'| Flaps, each side | y = %.2f–%.2f ft; 32%% local chord | 40° landing deflection; verify hinge/control allocation |\n',g.flap_y_start_ft,g.flap_y_end_ft);
fprintf(fid,'\nModeled landing distance: %.0f ft; clean stall: %.1f kt. This is a powered-lift aircraft sizing screen; it does not establish an idle-power certification stall result. The separate 59-kt clean-stall target remains disabled.\n\n',r.con.S_land_ft,r.VS1);
fprintf(fid,'## Request to the aerodynamic teammate\n\n');
fprintf(fid,'Use Sref = %.3f ft², Bref = %.3f ft, Cref = %.3f ft for all aircraft coefficients. At %.0f KTAS / %.0f ft, Mach is about %.3f and Reynolds number based on MAC is %.2f million. The previous export used Mach .001, Re 3.5 million and Vinf 100 in unspecified units; explicitly set dimensional units for the next run.\n\n',r.SW,r.span,r.MAC,m.Vkt,m.h_cr,g.cruise_Mach,g.cruise_Re_MAC/1e6);
fprintf(fid,'Use %s with coordinates from `%s`. Run alpha -4° to 10° in 1° steps, refining around cruise CL %.3f. A separate viscous analysis is needed for stall; a panel sweep does not establish CLmax. Check wake/mesh convergence and report near-field and wake coefficients separately. Return the native model, geometry references, analysis units, mesh/wake settings, and a parasite-drag component buildup identifying fuselage, wing, tails, gear, nacelles and folded props. Confirm whether the previous summary Cd0 .0202 covers the whole aircraft and whether tail trim is included.\n\n', ...
    g.airfoil_name,g.airfoil_coordinate_file,r.cruise_CL);
fprintf(fid,'Run the clean unpowered polar first, with the six high-lift propellers folded/stowed. Then run cruise prop-on cases at representative thrust and separate flap/blowing cases. Apply any prop-on drag benefit only after subtracting a matched prop-off case with a consistent thrust/drag convention. Do not infer CLmax from the existing 0–8° panel sweep.\n\n');
fprintf(fid,'For the telescoping comparison, use AR18 at full extension, fixed motors at the core ends, and full-span climb/landing. Let the optimizer provide a separate complete geometry; cutting 20%% off this fixed reference without resizing or checking prop clearance is not an equivalent candidate.\n\n');
fprintf(fid,'Absolute wing position, CG, tail incidence, prop axial offset, cooling openings and landing-gear clearances still need layout/trim decisions. Do not treat old concept_variable_span models as this updated geometry.\n\n');
fprintf(fid,'[Planform sketch](input_review/reference_planform.png) · [Geometry values](input_review/geometry.json) · [Assumption review](docs/INPUT_ASSUMPTIONS.md) · [Updated trades](CURRENT_TRADE_REVIEW.md)\n');
clear guard
end

function plot_polar(m,folder)
p=m.polar; t=p.table; cl=linspace(0,1.3,150);
f=figure('Visible','off','Color','w','Position',[100 100 1050 440]); cleanup=onCleanup(@() close(f));
tiledlayout(1,2,'TileSpacing','compact');
nexttile; plot(t.CL_wake,t.CD_total_summary,'o','MarkerFaceColor',[0 .4 .7]); hold on;
plot(cl,p.CD0_fit+p.k_fit*cl.^2,'LineWidth',1.8);
plot(cl,p.summary_CD0+p.k_fit*cl.^2,'--','LineWidth',1.2,'Color',[.4 .4 .4]); grid on;
xlabel('C_L (summary CLwtot)'); ylabel('C_D');
legend('Teammate summary','Fitted complete polar','Cd0 = 0.0202 alone + same k','Location','northwest');
title('Reference AR = 13.008; fit only to supplied points');
nexttile; plot(t.CL_wake,t.LD_summary,'o','MarkerFaceColor',[0 .4 .7]); hold on;
plot(cl,cl./(p.CD0_fit+p.k_fit*cl.^2),'LineWidth',1.8); grid on;
xlabel('C_L'); ylabel('L/D'); title(sprintf('CD = %.5f + %.5f CL^2; e = %.3f',p.CD0_fit,p.k_fit,p.e_effective));
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k');
set(findall(f,'Type','text'),'Color','k'); set(findall(f,'Type','legend'),'Color','w','TextColor','k');
exportgraphics(f,fullfile(folder,'polar_fit.png'),'Resolution',180);
end

function plot_geometry(g,folder)
f=figure('Visible','off','Color','w','Position',[100 100 1100 300]); cleanup=onCleanup(@() close(f));
hold on; semi=g.span_ft/2; dx=tand(g.sweep_LE_deg)*semi;
patch([-semi 0 semi semi 0 -semi],[dx 0 dx dx+g.tip_chord_ft g.root_chord_ft dx+g.tip_chord_ft], ...
    [.78 .88 .96],'EdgeColor',[0 .25 .4],'LineWidth',1.5);
for sign=[-1 1]
    for j=1:4
        y=sign*g.prop_hub_y_each_side_ft(j); x=abs(y)*tand(g.sweep_LE_deg)-.6;
        diameter=g.high_lift_prop_diameter_ft; if j==4, diameter=g.cruise_prop_diameter_ft; end
        plot(y+[-1 1]*diameter/2,[x x],'Color',[.1 .55 .3],'LineWidth',4);
        plot(y,x,'ko','MarkerFaceColor','k');
    end
end
set(gca,'YDir','reverse'); axis equal; grid on;
xlim([-1 1]*(semi+g.cruise_prop_diameter_ft/2+1)); ylim([-2 6]);
xlabel('Spanwise y, ft'); ylabel('Aft of root LE, ft');
title(sprintf('Analysis reference: %.1f ft span, %.1f ft^2, AR%.2f, taper %.2f',g.span_ft,g.wing_area_ft2,g.AR,g.taper));
subtitle('Prop lines show swept diameter; axial offset is illustrative. Tail/fuselage placement awaits CG and trim.');
set(findall(f,'Type','axes'),'Color','w','XColor','k','YColor','k'); set(findall(f,'Type','text'),'Color','k');
exportgraphics(f,fullfile(folder,'reference_planform.png'),'Resolution',180);
end
