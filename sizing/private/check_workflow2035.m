function check_workflow2035()
% Check public entry points, shared physics, archive isolation and exports.
root=AEGAroot();
figuresBefore=findall(groot,'Type','figure');
before=load(fullfile(root,'archive','workflow_before_20261011','workflow_validation_before.mat'));
current=AEGAsize(before.m);
assert(current.msn.AR==before.m.AR,'Live reference AR was overwritten.');
fields={'MTOW','SW','span','PTO_kW','Ebat','CD0','CLmax','CLmax_TO'};
for field=fields
    assert(abs(current.(field{1})-before.live.(field{1}))<1e-8, ...
        ['Refactor changed reference ' field{1}]);
end
reference=before.m; reference.AR=18;
r18=AEGAsize(reference);
assert(abs(r18.MTOW-before.before.MTOW)<1e-8);
legacy=AEGAsize(AEGAlegacyinputs2035(),32,struct());
assert(abs(legacy.MTOW-before.legacy.MTOW)<.01);
printed=evalc('con=AEGAconstraint(current,false);');
assert(isempty(strtrim(printed)) && con.WS_design==current.WSR);
assert(abs(con.S_land_ft-current.con.S_land_ft)<1e-10);
assert(isequal(findall(groot,'Type','figure'),figuresBefore));
assert(isempty(which('AEGAtrade_size')) && isempty(which('run_currenttrades2035')));
check_polarinputs2035();
check_structuralassumptions2035();
check_wingtipprop2035();
check_residualpower2035();
check_reverse2035();
% Perturbed-input checks ensure callers do not silently reload defaults.
check_currenttrades2035();
% Small all-study run exercises actual relocated exporters and review links.
% It never overwrites the presentation's full-grid CURRENT_TRADE_REVIEW.
m=AEGAinputs(); profiles=AEGAwingcomparisonprofiles(m);
o=struct('plot',true,'save',true,'visible',false,'publish_review',false);
stamp=char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
o.review_folder=fullfile(root,'midterm_review',['workflow_check_' stamp]);
o.wing=struct('WS',[20 24],'AR_values',[16 18],'AR_refine_step',0);
o.wings=struct('profiles',profiles(1),'WS_bounds',[20 24],'WS_grid',[20 24], ...
    'fixed_AR_bounds',[16 18],'fixed_AR_grid',[16 18], ...
    'taper_bounds',[.2 .5],'taper_grid',[.2 .5],'refine',false,'speed_grid',m.Vkt);
o.props=struct('WS',[20 24],'cruise_diameter_ft',4.5, ...
    'high_lift_diameter_ft',[2.4 2.8],'refine',false,'verbose',false);
reviewPath=fullfile(root,'CURRENT_TRADE_REVIEW.md'); oldReview=fileread(reviewPath);
s=AEGAtrades('all',m,o);
assert(strcmp(oldReview,fileread(reviewPath)),'Validation overwrote the full-grid review.');
assert(s.props.inputs.AR==m.AR && s.wing.inputs.AR==m.AR);
for stem={'01_wing_loading_and_AR','02_fixed_vs_telescoping','03_cruise_prop_trade'}
    assert(isfile(fullfile(s.review_folder,[stem{1} '.png'])));
    assert(isfile(fullfile(s.review_folder,[stem{1} '.fig'])));
end
assert(isfile(fullfile(s.review_folder,'README.md')));
newFigures=setdiff(findall(groot,'Type','figure'),figuresBefore); close(newFigures);
fprintf('PASS: public sizing/constraints, exact pre-refactor results, live AR, relocated data/helpers, three-study exports and reverse physics.\n');
end
