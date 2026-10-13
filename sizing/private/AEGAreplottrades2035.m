function s=AEGAreplottrades2035(folder,opt,stamp)
% Refresh one saved numerical package; preserve its original physical inputs.
files={'wingtrade_results.mat','optimized_wing_comparison.mat','cruise_prop_trade.mat'};
engines={@AEGAwingtrades,@AEGAoptimizewings2035,@AEGAcruiseproptrades2035};
found=find(cellfun(@(f) isfile(fullfile(folder,f)),files));
assert(isscalar(found),'Source folder must contain exactly one recognized study MAT file.');
k=found; loaded=load(fullfile(folder,files{k}));
if k==1, s=loaded.study; else, s=loaded.saved; end
originalOptions=s.options;
s.options.output_dir='';
if opt.save
    s.options.output_dir=fullfile(opt.output_root,['replot_' stamp]);
    mkdir(s.options.output_dir);
    copies=[dir(fullfile(folder,'*.csv'));dir(fullfile(folder,'*.txt'))];
    for j=1:numel(copies)
        copyfile(fullfile(folder,copies(j).name),fullfile(s.options.output_dir,copies(j).name));
    end
end
s.options.doplot=logical(opt.plot); s.options.save_plots=logical(opt.save && opt.plot);
s.options.figure_visible='off'; if opt.visible, s.options.figure_visible='on'; end
s.replot_provenance=struct('source_folder',folder,'source_options',originalOptions, ...
    'refreshed_at',char(datetime('now')),'note','Original numerical results and physical assumptions; no new sizing.');
s=engines{k}(s.inputs,struct('replot_data',s));
if opt.save
    AEGAtradeassumptions2035(s);
    saved=s;
    if isfield(saved,'figures'), saved.figures=[]; end
    if isfield(saved,'figure_handles'), saved.figure_handles=[]; end
    if k==1
        study=saved; save(fullfile(s.options.output_dir,files{k}),'study');
    else
        save(fullfile(s.options.output_dir,files{k}),'saved','-v7.3');
    end
    fid=fopen(fullfile(s.options.output_dir,'REFRESH_PROVENANCE.txt'),'w'); assert(fid>=0);
    guard=onCleanup(@() fclose(fid));
    fprintf(fid,'Figures refreshed %s from %s. No aircraft re-sizing. Source assumptions retained.\n', ...
        s.replot_provenance.refreshed_at,folder);
end
fprintf('Figures refreshed from saved numerical results: %s\n',s.options.output_dir);
end
