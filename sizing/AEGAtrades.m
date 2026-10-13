function results = AEGAtrades(study,msn,opt)
%AEGATRADES One entry point for the three presentation trade studies.
%   results = AEGAtrades()             run, check and export all three
%   wing = AEGAtrades('wing')          W/S versus aspect ratio
%   wings = AEGAtrades('wings')        independently optimized fixed/adaptive
%   props = AEGAtrades('props')        cruise diameter / high-lift sizing
%   AEGAtrades('reverse')              optional reverse-thrust sensitivity
%   AEGAtrades('inputs')               input sensitivities / geometry handoff
%   AEGAtrades('battery')              mirrored versus cross-paired bank study
%   AEGAtrades('energy')               battery pack specific energy, 350:25:500 Wh/kg
%   AEGAtrades('check')                compact physics and workflow checks
%   AEGAtrades('replot',[],struct('source_folder',savedFolder))
%                                     refresh figures without re-sizing
%
% All studies read AEGAinputs once per call; every aircraft uses AEGAsize
% and quiet AEGAconstraint calls. Helpers in private/ are found automatically.
% AR18 remains the adaptive full-span AR and fixed-wing search ceiling.
% The wing/prop reference AR and taper come from the supplied live inputs.
%
% Optional third argument: opt.search_mode ('review' default or 'thorough'),
% opt.plot, opt.save, opt.visible, opt.output_root;
% opt.wing, opt.wings and opt.props override each study's grid/options.
% Example, a small diagnostic sweep (not an optimization result):
%   o = struct('plot',false,'save',false);
%   o.wing = struct('WS',[20 24],'AR_values',[16 18],'AR_refine_step',0);
%   s = AEGAtrades('wing',AEGAinputs(),o);
if nargin < 1 || isempty(study), study = 'all'; end
if nargin < 2 || isempty(msn), msn = AEGAinputs(); end
if nargin < 3, opt = struct(); end
study = validatestring(study,{'all','wing','wings','props','reverse','inputs','check','replot','battery','energy'});
if strcmp(study,'battery')
    results=AEGAbatterymappingtrade2035(msn,opt); return
end
if strcmp(study,'check')
    check_workflow2035();
    results = struct('passed',true);
    return
end
if strcmp(study,'inputs')
    results = AEGAinputreview2035(msn);
    return
end
d = struct('plot',true,'save',true,'visible',usejava('desktop'), ...
    'search_mode','review', ...
    'output_root',fullfile(AEGAroot(),'trade_results'), ...
    'review_folder','','publish_review',true, ...
    'wing',struct(),'wings',struct(),'props',struct(),'reverse',struct(),'energy',struct());
opt = merge_options(d,opt);
opt.search_mode = validatestring(opt.search_mode,{'review','thorough'});
reviewMode = strcmp(opt.search_mode,'review');
for field = {'plot','save','visible'}
    validateattributes(opt.(field{1}),{'logical','numeric'},{'scalar','binary'});
end
priorVisibility = get(groot,'defaultFigureVisible');
graphicsGuard = onCleanup(@() set(groot,'defaultFigureVisible',priorVisibility));
visible = 'off'; if opt.visible, visible = 'on'; end
set(groot,'defaultFigureVisible',visible);
cfg = AEGAstudysettings2035(msn);
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
if strcmp(study,'replot')
    assert(isfield(opt,'source_folder'),'Supply opt.source_folder containing a saved study MAT file.');
    results = AEGAreplottrades2035(opt.source_folder,opt,stamp);
    return
end
results = struct('source_inputs',msn);
if strcmp(study,'energy')
    o=configure_output(merge_options(struct('pack_Whkg',350:25:500,'figure_visible',visible),opt.energy),'battery_energy');
    results=AEGAenergytrades2035(msn,o);
    return
end

if any(strcmp(study,{'all','wing'}))
    o = struct('current_configuration',true,'enforce_landing',cfg.enforce_landing, ...
        'WS',20:2:38,'AR_values',unique([12:2:18 msn.AR]),'AR_refine_step',0,'AR_refine_half_width',2, ...
        'do_AR',true,'do_drag',false,'do_climb',false,'do_battery',false,'do_mission',false, ...
        'eo',struct('selected_climb_gradient',.02,'climb_speed_kt',1.30*msn.VS0, ...
            'VS_kt',msn.VS0,'approach_factor',1.30,'approach_deg',msn.approach_angle, ...
            'failed_disk_CD',0,'takeoff_dCD',.03,'max_hp_lb',.60));
    o = configure_output(merge_options(o,opt.wing),'wing');
    results.wing = AEGAwingtrades(msn,o);
end
if any(strcmp(study,{'all','wings'}))
    o = struct('profiles',AEGAwingcomparisonprofiles(msn),'extended_AR',18, ...
        'WS_bounds',[min(cfg.WS) max(cfg.WS)],'WS_grid',unique([12:4:48 msn.WS_design]), ...
        'fixed_AR_bounds',[8 cfg.AR_max],'fixed_AR_grid',cfg.AR, ...
        'taper_bounds',cfg.taper_bounds,'taper_grid',cfg.taper_grid, ...
        'retraction_bounds',cfg.retraction_bounds,'retraction_grid',.20:.05:.45, ...
        'enforce_landing',cfg.enforce_landing,'refine',true,'refine_seeds',3, ...
        'refine_max_evals',140,'cruise_stall_speed_factor',1.2, ...
        'size_options',struct('weight_tolerance',.01),'figure_visible',visible);
    if reviewMode
        o.profiles = o.profiles(1); % mixed-speed sensitivity is in thorough mode
        o.WS_grid = unique([12 20 28 36 48 msn.WS_design]);
        o.fixed_AR_grid = unique([8 12 18 msn.AR]);
        o.taper_grid = unique([cfg.taper_bounds msn.TR]);
        o.refine_seeds = 1; o.refine_max_evals = 60;
        o.speed_grid = unique([80:10:200 msn.Vkt]);
    end
    o = configure_output(merge_options(o,opt.wings),'optimized_wings');
    results.wings = AEGAoptimizewings2035(msn,o);
end
if any(strcmp(study,{'all','props'}))
    o = struct('cruise_diameter_ft',cfg.cruise_diameters_ft, ...
        'high_lift_diameter_ft',cfg.high_lift_diameters_ft,'WS',cfg.prop_WS, ...
        'AR',cfg.reference_AR,'taper',cfg.reference_taper, ...
        'anchor_high_lift_diameter_ft',cfg.anchor_high_lift_diameter_ft, ...
        'enforce_landing',cfg.enforce_landing,'include_all_operating',true, ...
        'refine',true,'refine_step_ft',.05,'max_installed_shaft_kW',Inf, ...
        'plot_constraints',false,'figure_visible',visible);
    if reviewMode
        o.cruise_diameter_ft = unique([2 2.5 2.75 3 3.5 4.5 6 cfg.cruise_diameter_ft]);
        o.high_lift_diameter_ft = cfg.high_lift_diameters_ft;
        o.WS = cfg.prop_WS;
        o.include_all_operating = false; % required battery-out design is the decision case
        o.refine_diameter = false; % keep a small joint refinement near each best design
        o.refine_step_ft = .1; o.refine_WS_step = 1; o.refine_WS_half_width = 1;
        o.downsize_plot_diameter_ft = o.high_lift_diameter_ft;
    end
    % An explicit diameter-grid override also defines the review plot grid.
    if reviewMode && isfield(opt.props,'high_lift_diameter_ft') && ...
            ~isfield(opt.props,'downsize_plot_diameter_ft')
        o.downsize_plot_diameter_ft = opt.props.high_lift_diameter_ft;
    end
    o = configure_output(merge_options(o,opt.props),'cruise_props');
    results.props = AEGAcruiseproptrades2035(msn,o);
    check_cruiseproptrades2035(results.props);
end
if strcmp(study,'reverse')
    o = configure_output(opt.reverse,'reverse');
    o.publish_review = opt.publish_review;
    results = AEGAreversetrades2035(msn,o);
    check_reverse2035(results);
    return
end
if strcmp(study,'all')
    check_currenttrades2035(results.wing,results.wings,results.props);
    results.review_folder = '';
    % The presentation exporter needs the summary figures from all studies.
    if opt.save && opt.plot
        results.review_folder = AEGAexportreview2035(results.wing,results.wings, ...
            results.props,opt.review_folder,opt.publish_review);
        fprintf('Three-study review: %s\n',results.review_folder);
    end
    fprintf('Three main studies complete. Optional reverse study: AEGAtrades(''reverse'').\n');
else
    results = results.(study);
end

    function o = configure_output(o,prefix)
        o.search_mode = opt.search_mode;
        o.doplot = logical(opt.plot);
        o.save_plots = logical(opt.save && opt.plot);
        o.output_dir = '';
        if opt.save, o.output_dir = fullfile(opt.output_root,[prefix '_' stamp]); end
    end
end

function out = merge_options(defaults,overrides)
assert(isstruct(overrides) && isscalar(overrides),'Options must be a scalar struct.');
out = defaults;
for field = fieldnames(overrides).'
    out.(field{1}) = overrides.(field{1});
end
end
