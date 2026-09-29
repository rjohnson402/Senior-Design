% Engine-out lift, approach, and climb study.
% Uses AEGAengineout.m and AEGAengineout_trade.m from the same update.
msn = AEGAinputs();
msn.enforce_VS1 = false; % user's proposed 2035 powered-lift requirement
out = AEGAsize(msn);
opt = struct();
opt.ratio = 1.30; % compare Equal, [r r 1 1], and linspace(r,1,4)
opt.VS_kt = 60;
opt.approach_factor = 1.30; % approach at 78 kt
opt.approach_deg = 3;
opt.rating_mode = 'disk-area'; % use 'equal' to compare identical motor ratings
opt.failed_disk_CD = 0; % ideal feathered/folded incremental drag; replace with data
% Proposed climb requirement and sensitivity cases, at sea level.
opt.include_climb = true;
opt.climb_gradients = [0 0.01 0.02 0.03];
opt.selected_climb_gradient = 0.02; % applies to both 2-out and 4-out
opt.climb_speed_kt = 78;
opt.takeoff_dCD = 0.03; % assumed takeoff flap drag increment; replace with data
study = AEGAengineout(msn,out,opt);
trade = AEGAengineout_trade(msn,out,opt);

% Example: enforce two-size geometry in a separate NORMAL sizing run:
% msn.prop_Dratio_side = [1.3 1.3 1 1];
% out_two = AEGAsize(msn);
% study_two = AEGAengineout(msn,out_two,opt);
% This still does not close the MTOW loop on the engine-out constraints.
