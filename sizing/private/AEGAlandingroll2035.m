function r=AEGAlandingroll2035(m,CD0,CLland,WS,n)
% Brakes + aero drag + conditional powered reverse after touchdown.
% TW is an ASSUMED reverse-map target, capped by a static momentum screen.
% Negative-pitch maps must still establish thrust at touchdown advance ratio.
if nargin<5, n=200; end
validateattributes(n,{'numeric'},{'scalar','integer','>=',50});
validateattributes(WS,{'numeric'},{'scalar','finite','positive'});
VTD=m.VTD_factor*sqrt(2*WS/(m.rho_SL*CLland));
v=linspace(0,VTD,n); q=.5*m.rho_SL*v.^2;
CL=m.CL_ground_frac*m.CLmax_L;
CD=CD0+m.dCD_flap_L+CL^2/(pi*m.AR*m.e_osw);
base=m.g0*(m.mu_brake*max(1-q*CL/WS,0)+q*CD/WS);
noReverse=trapz(v,v./base);
model='legacy-immediate'; if isfield(m,'reverse_model'), model=m.reverse_model; end
engageKt=Inf; if isfield(m,'reverse_engage_below_kt'), engageKt=m.reverse_engage_below_kt; end
validateattributes(engageKt,{'numeric'},{'scalar','real','nonnegative','nonnan'});
activation_s=Inf;
available=0; area=0; weight=NaN; shaft=0; peakTW=m.reverse_TW;
if isfield(m,'reverse_available_shaft_kW'), available=m.reverse_available_shaft_kW; end
if isfield(m,'reverse_active_area_ft2'), area=m.reverse_active_area_ft2; end
if isfield(m,'DG'), weight=m.DG; end
if strcmp(model,'delayed-target') && m.reverse_TW>0
    shaft=min(m.reverse_shaft_request_kW,max(0,available));
    if isfield(m,'reverse_pair_available') && ~m.reverse_pair_available, shaft=0; end
    if isfinite(weight) && weight>0 && area>0
        staticLimit=(shaft*737.56*m.reverse_static_merit*sqrt(2*m.rho_SL*area))^(2/3);
        peakTW=min(m.reverse_TW,staticLimit/weight);
    else
        peakTW=0; shaft=0;
    end
end
% Sizing repeatedly requests identical rollouts during power iteration and
% landing-limit root searches. Cache only the effective physical inputs;
% available rating metadata is refreshed on return. No interpolation is used.
persistent rolloutCache
cacheKey='';
if strcmp(model,'delayed-target') && m.reverse_TW>0 && peakTW>0
    physical=[m.rho_SL WS CL CD m.g0 m.mu_brake VTD n peakTW shaft ...
        m.reverse_TW engageKt m.reverse_delay_s m.reverse_ramp_s ...
        m.reverse_fade_start_kt m.reverse_off_kt m.eta_m m.eta_pe];
    cacheKey=sprintf('%.17g,',physical);
    if isempty(rolloutCache), rolloutCache=containers.Map('KeyType','char','ValueType','any'); end
    if isKey(rolloutCache,cacheKey)
        r=rolloutCache(cacheKey); r.available_shaft_kW=available;
        return
    end
end
if m.reverse_TW==0 || strcmp(model,'legacy-immediate') || peakTW==0
    tw=peakTW; if strcmp(model,'delayed-target'), tw=0; end
    decel=base+m.g0*tw; distance=trapz(v,v./decel);
    speed=fliplr(v); elapsed=cumtrapz(-speed,1./fliplr(decel));
    profileTW=repmat(tw,size(speed)); p=zeros(size(speed));
    energy=0; impulse=tw*elapsed(end); duration=elapsed(end);
else
    % Split a velocity interval exactly at the eligibility threshold. Before
    % this crossing wheel brakes/aero drag act alone, so the trigger time is
    % known independently of the reverse command. Start the ramp only after
    % BOTH the speed crossing and the minimum time since touchdown.
    if isfinite(engageKt)
        v=unique([v min(VTD,engageKt*1.688)]);
        q=.5*m.rho_SL*v.^2;
        base=m.g0*(m.mu_brake*max(1-q*CL/WS,0)+q*CD/WS);
    end
    n=numel(v);
    speed=fliplr(v); accel=fliplr(base); elapsed=zeros(size(speed));
    stepTime=-diff(speed)./((accel(1:end-1)+accel(2:end))/2);
    beforeThreshold=(speed(1:end-1)+speed(2:end))/2>engageKt*1.688;
    activation_s=max(m.reverse_delay_s,sum(stepTime(beforeThreshold)));
    profileTW=zeros(size(speed)); p=zeros(size(speed)); distance=0; energy=0; impulse=0;
    for j=1:n-1
        dv=speed(j)-speed(j+1); vm=(speed(j)+speed(j+1))/2;
        fade=min(1,max(0,(vm/1.688-m.reverse_off_kt)/(m.reverse_fade_start_kt-m.reverse_off_kt)));
        dt=dv/((accel(j)+accel(j+1))/2); command=0;
        for k=1:4
            tm=elapsed(j)+dt/2;
            ramp=min(1,max(0,(tm-activation_s)/max(m.reverse_ramp_s,eps)));
            command=ramp*fade*double(vm<=engageKt*1.688);
            dt=dv/((accel(j)+accel(j+1))/2+m.g0*peakTW*command);
        end
        elapsed(j+1)=elapsed(j)+dt; distance=distance+vm*dt;
        energy=energy+shaft*command*dt/3600;
        impulse=impulse+peakTW*command*dt;
        profileTW(j+1)=peakTW*command; p(j+1)=shaft*command;
    end
    duration=elapsed(end);
end
r=struct('distance_ft',distance,'no_reverse_distance_ft',noReverse, ...
    'duration_s',duration,'touchdown_kt',VTD/1.688,'peak_reverse_TW',peakTW, ...
    'average_reverse_TW',impulse/max(duration,eps),'requested_reverse_TW',m.reverse_TW, ...
    'shaft_energy_kWh',energy,'battery_energy_kWh',energy/(m.eta_m*m.eta_pe), ...
    'available_shaft_kW',available,'model',model, ...
    'engage_below_kt',engageKt,'activation_time_s',activation_s, ...
    'trace',table(elapsed',speed'/1.688,profileTW',p', ...
    'VariableNames',{'Time_s','Speed_kt','ReverseTW','ReverseShaft_kW'}));
if ~isempty(cacheKey)
    if rolloutCache.Count>=4096
        rolloutCache=containers.Map('KeyType','char','ValueType','any');
    end
    rolloutCache(cacheKey)=r;
end
end
