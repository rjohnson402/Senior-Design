function [pe,state,info] = AEGAallocatepower2035(m,S,b,layout,V,rho,ratings,cfg,r,f,Treq,CLneed,exact,maximumLift)
% Cruise-first thrust allocation, reserving high-lift power for needed blowing.
% Equal ratings within each group, mirrored failures; no borrowing or overload.
% For descent, enforce exact thrust. For climb, surplus thrust is permitted.
if nargin<14, maximumLift=false; end
high=[1:3 5:7]; cruise=[4 8]; A=[layout.A_side layout.A_side];
validateattributes(ratings,{'numeric'},{'vector','numel',8,'nonnegative','finite'});
ratings=ratings(:).';
ah=high(ratings(high)>0); ac=cruise(ratings(cruise)>0);
PH=sum(ratings(ah)); PC=sum(ratings(ac));
Ah=sum(A(ah)); Ac=sum(A(ac));
Tc=thrust(PC,Ac); Th=thrust(PH,Ah);
lo=power(max(0,Treq-Tc),Ah);
hi=PH;
if exact, hi=min(hi,power(Treq,Ah)); end
lo=min(PH,lo);
grid=linspace(min(lo,hi),hi,9);
values=zeros(size(grid));
for k=1:numel(grid), [~,s]=at(grid(k)); values(k)=s.CL_blown; end
if maximumLift
    [~,k]=max(values); selected=grid(k);
else
    k=find(values>=CLneed-1e-9,1);
    if isempty(k), [~,k]=max(values); selected=grid(k);
    elseif k==1, selected=grid(1);
    else
        low=grid(k-1); upper=grid(k);
        for liftIteration=1:25
            mid=(low+upper)/2; [~,s]=at(mid);
            if s.CL_blown>=CLneed, upper=mid; else, low=mid; end
        end
        selected=upper;
    end
end
[pe,state]=at(selected);
info=struct('high_lift_kW',sum(pe(high)),'cruise_kW',sum(pe(cruise)), ...
    'cruise_capacity_thrust_lb',Tc,'high_lift_capacity_thrust_lb',Th, ...
    'residual_thrust_lb',max(0,Treq-Tc), ...
    'lift_margin',state.CL_blown-CLneed,'thrust_margin_lb',state.thrust_lb-Treq, ...
    'lift_pass',state.CL_blown>=CLneed-1e-7, ...
    'thrust_pass',state.thrust_lb>=Treq-max(1e-6,1e-8*Treq));
if exact, info.thrust_pass=abs(state.thrust_lb-Treq)<max(1e-6,1e-8*Treq); end
    function [p,s]=at(ph)
        p=zeros(1,8);
        if ~isempty(ah), p(ah)=ph*ratings(ah)/PH; end
        pc=min(PC,power(max(0,Treq-thrust(ph,Ah)),Ac));
        if ~isempty(ac), p(ac)=pc*ratings(ac)/PC; end
        s=AEGAblownstate2035(m,S,b,layout,V,rho,p,cfg,r,f);
    end
    function T=thrust(P,area)
        if P==0 || area==0, T=0; return; end
        Q=m.prof*P*737.56/(2*rho*area);
        vi=min(Q/V^2,nthroot(Q,3));
        for diskIteration=1:24, vi=max(0,vi-(vi*(V+vi)^2-Q)/((V+vi)*(V+3*vi))); end
        T=2*rho*area*vi*(V+vi);
    end
    function P=power(T,area)
        if T==0, P=0; return; end
        if area==0, P=Inf; return; end
        vi=T/(rho*area*(sqrt(V^2+2*T/(rho*area))+V));
        P=T*(V+vi)/(m.prof*737.56);
    end
end
