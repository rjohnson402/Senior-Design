function m=AEGAreversecase2035(m,targetTW)
% Conditional reversing-pitch concept on BOTH cruise props; analyst targets.
if nargin<1, m=AEGAinputs(); end
if nargin<2, targetTW=m.reverse_TW; end
validateattributes(targetTW,{'numeric'},{'scalar','finite','>=',0,'<=',.15});
m.reverse_TW=targetTW; m.reverse_model='delayed-target';
m.reverse_delay_s=2; m.reverse_ramp_s=1;
m.reverse_engage_below_kt=55; % brake first; 1-second ramp starts after eligibility
m.reverse_fade_start_kt=15; m.reverse_off_kt=5;
m.reverse_shaft_request_kW=15;
if targetTW>.05, m.reverse_shaft_request_kW=18; end
if targetTW>.06, m.reverse_shaft_request_kW=25; end
m.reverse_rating_fraction=.50; % half of assigned cruise-pair peak rating
m.reverse_static_merit=.50; % static momentum screen, NOT a reverse prop map
m.reverse_pair_available=true; % cancel both if the matched pair is unavailable
% Increment over generic hubs/mounts in dWinst; no blade mass duplication.
m.reverse_hardware_lb=2.20462*(2*4+1); % two 4-kg pitch increments +1-kg controls
if targetTW==0, m.reverse_hardware_lb=0; end
end
