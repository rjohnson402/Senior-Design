function AEGAtradeassumptions2035(s)
% Save actual run assumptions beside the figures, including screening limits.
o=s.options; m=s.inputs;
if isempty(o.output_dir), return; end
if ~isfolder(o.output_dir), mkdir(o.output_dir); end
fid=fopen(fullfile(o.output_dir,'MAJOR_ASSUMPTIONS.txt'),'w'); assert(fid>=0);
guard=onCleanup(@() fclose(fid));
fprintf(fid,'CONCEPTUAL DESIGN TRADE STUDY: MAJOR ASSUMPTIONS\n');
if isfield(o,'search_mode'), fprintf(fid,'Search mode: %s; user grid overrides take precedence.\n',o.search_mode); end
fprintf(fid,'Mission: %.0f nm at reference %.0f KTAS, %.0f min reserve, %.0f lb payload.\n',m.range,m.Vkt,m.reserve,m.payload);
if isfield(m,'assigned_range_nm')
    fprintf(fid,'Assigned range requirement: %.0f nm; the modeled mission above is the run basis.\n',m.assigned_range_nm);
end
fprintf(fid,'Pack: %.0f Wh/kg, %.0f%% usable. Motor/inverter: %.1f/%.1f kW/kg; efficiencies %.3f/%.3f.\n', ...
    m.whkg,100*m.fusable,m.kWkg_m,m.kWkg_pe,m.eta_m,m.eta_pe);
fprintf(fid,'Structure: ultimate load factor %.2f, FCOMP %.2f, wing/fuselage mass factors %.2f/%.2f.\n', ...
    m.ULF,m.FCOMP,m.wing_mass_factor,m.fuselage_mass_factor);
fprintf(fid,'Dry-empty weight-growth allowance %.1f%%; fuselage wetted area %.2f ft^2 shared by weight and drag.\n', ...
    100*m.fmarg,AEGAfuselagewettedarea(m));
if isfield(m,'CD0_override') && ~isempty(m.CD0_override)
    fprintf(fid,'Team-supplied clean-aircraft CD0 held at %.6f for the full wing; overrides older polar intercept. Geometry-dependent clean CD0 sensitivity is suppressed. Effective e %.4f retained from older polar.\n',m.CD0_override,m.e_osw);
else
    fprintf(fid,'Teammate polar interpreted provisionally as whole-aircraft; calibrated drag model and geometry-dependent corrections.\n');
end
fprintf(fid,'Landing screen: %.0f ft over 50 ft obstacle; enforced %d; %.1f-degree approach, brake friction %.2f.\n', ...
    m.S_field,m.enforce_land,m.approach_angle,m.mu_brake);
fprintf(fid,'Ground reverse: target %.1f%% W, only below %.0f kt and after %.1f s; ramp %.1f s; hardware %.1f lb.\n', ...
    100*m.reverse_TW,m.reverse_engage_below_kt,m.reverse_delay_s,m.reverse_ramp_s,m.reverse_hardware_lb);
fprintf(fid,'Reverse is power-limited with low-speed fade, not constant force at touchdown; no airborne credit.\n');
fprintf(fid,'Clean CLmax %.2f; blown CLmax cap %.2f; powered lift uses scheduled group thrust.\n',m.CLmax_clean,m.CLmax_cap);
if isfield(m,'airfoil') && isstruct(m.airfoil)
    fprintf(fid,'Airfoil: %s; t/c %.3f at x/c %.2f; team 2D clmax %.2f; assumed wing factor %.2f.\n', ...
        m.airfoil.name,m.TCA,m.airfoil.max_thickness_xc,m.airfoil.clmax_2d,m.airfoil.wing_clmax_factor);
    fprintf(fid,'2D analysis Re/Mach and transition/roughness are unconfirmed. Drag inputs have not been independently revalidated for the new section.\n');
end
fprintf(fid,'Two cruise and six high-lift propellers; battery-bank motor pairs %s, numbering L1..L4,R1..R4. Power/lift screens do not establish asymmetric trim.\n',mat2str(AEGAbatterypairs2035(m)));
if isfield(m,'prop_power') && isfield(m.prop_power,'mode')
    fprintf(fid,'Propulsion rating allocation model: %s.\n',m.prop_power.mode);
end
if isfield(m,'prop_D_side_ft')
    fprintf(fid,'Reference prop diameters, one side (ft): %s. Study diameter grids override these where specified.\n',mat2str(m.prop_D_side_ft));
end
if isfield(o,'profiles')
    for p=o.profiles
        fprintf(fid,'Wing-comparison profile: %s; route speeds %s KTAS; distances %s nm; reserve %.0f KTAS.\n', ...
            p.name,mat2str(p.route_speed_ktas),mat2str(p.route_distance_nm),p.reserve_speed_ktas);
    end
    fprintf(fid,'Adaptive AR18 fully extended for climb/landing; cruise span minimizes power within lift/packing limits. Motors remain on fixed core.\n');
    fprintf(fid,'Mechanism build: optimistic conceptual bill of materials; joint drag and mass are estimates.\n');
end
if isfield(o,'include_all_operating')
    fprintf(fid,'All-operating-only comparison included: %d. Required battery-out design always included.\n',o.include_all_operating);
end
fprintf(fid,'Best found within sampled bounds and any local refinement; not a proven global optimum.\n');
fprintf(fid,'Search grids/options and selected constraint results are preserved in the MAT/CSV files.\n');
fprintf(fid,'Propeller maps, trim, aeroelasticity and battery failure energy access are not validated by this study.\n');
end
