function p = AEGAresidualpower2035(m,W,S,b,layout,CD0,cruiseRequired,opt)
% Independent cruise-pair rating; high-lift group closes all residual screens.
settings=m.prop_power; high=[1:3 5:7]; tips=[4 8];
validateattributes(settings.cruise_rating_margin,{'numeric'},{'scalar','finite','>=',1});
C=cruiseRequired*settings.cruise_rating_margin;
if ~isempty(settings.cruise_pair_rating_kW)
    validateattributes(settings.cruise_pair_rating_kW,{'numeric'},{'scalar','finite','positive'});
    C=settings.cruise_pair_rating_kW;
    assert(C>=cruiseRequired,'AEGAresidualpower2035:cruiseRating', ...
        'Selected cruise pair cannot provide the required cruise/reserve shaft power.');
end
e=struct('VS_kt',m.VS0,'approach_factor',1.3,'approach_deg',m.approach_angle, ...
    'WS_margin',.98,'power_margin',1.02,'max_hp_lb',.60,'failed_disk_CD',0, ...
    'selected_climb_gradient',.02,'climb_speed_kt',1.3*m.VS0,'takeoff_dCD',.03);
for field=fieldnames(opt.eo).', e.(field{1})=opt.eo.(field{1}); end
assert(e.WS_margin>0 && e.WS_margin<=1 && e.power_margin>=1);
alive=true(5,8); pairs=AEGAbatterypairs2035(m);
for k=1:4, alive(k+1,pairs(k,:))=false; end
ceiling=e.max_hp_lb*W*.745699872;
assert(ceiling>C,'AEGAresidualpower2035:ceiling','Cruise rating exceeds the power search ceiling.');
labels={'60 kt lift','approach thrust/lift','takeoff climb','landing-flap go-around'};
Hcase=zeros(5,4); appCL=nan(5,1);
for k=1:5
    for j=1:4
        required=root(@(H) screen(H,k,j));
        Hcase(k,j)=required;
    end
    if isfinite(Hcase(k,2))
        [~,appCL(k)]=screen(Hcase(k,2),k,2);
    end
end
selected=1; if opt.enforce_battery_out, selected=1:5; end
[worst,linear]=max(Hcase(selected,:),[],'all','linear');
[casePosition,column]=ind2sub(size(Hcase(selected,:)),linear); critical=selected(casePosition);
assert(isfinite(worst),'AEGAresidualpower2035:failureScreen', ...
    'Independent ratings cannot satisfy case %d: %s within the power ceiling.',critical-1,labels{column});
H=max(worst*e.power_margin,0); H=min(ceiling-C,H);
% Total-power correlations and explicit normal flight phases are additional
% constraints, not permission to scale up the already-sized cruise motors.
for it=1:18
    [margin,context]=normal(H);
    if margin>=-1e-7, break; end
    needed=root(@normal);
    assert(isfinite(needed),'AEGAresidualpower2035:normalScreen', ...
        'Normal flight/approach requirements cannot close independent ratings.');
    H=max(H,needed*e.power_margin);
end
assert(margin>=-1e-7,'AEGAresidualpower2035:convergence','Independent group ratings did not converge.');
ratings=zeros(1,8); ratings(tips)=C/2; ratings(high)=H/6;
Hrequired=max(Hcase,[],2); totalRequired=C+Hrequired*e.power_margin;
[~,worstBattery]=max(totalRequired(2:5));
[~,worstColumn]=max(Hcase(worstBattery+1,:));
eo=struct('options',e,'pairs',pairs,'alive',alive,'rating_share',ratings/(C+H), ...
    'retained_power_fraction',alive*ratings(:)/(C+H), ...
    'bounds_hp_lb',(C+Hcase*e.power_margin)/(W*.745699872), ...
    'bound_names',{labels},'required_kW',totalRequired, ...
    'required_hp_lb',totalRequired/(W*.745699872), ...
    'worst_battery',worstBattery,'worst_driver',labels{worstColumn}, ...
    'status',{repmat({'ok'},5,1)},'approach_CL_available',appCL, ...
    'approach_lift_ok',isfinite(Hcase(:,2)),'rating_each_kW',ratings, ...
    'high_lift_required_kW',Hrequired*e.power_margin);
eo.options.rating_mode='independent-groups';
for k=1:5
    if ~isfinite(totalRequired(k)), eo.status{k}='independent group lift/thrust screen exceeds search ceiling'; end
end
eo.all_operating_hp_lb=eo.required_hp_lb(1);
eo.worst_battery_hp_lb=eo.required_hp_lb(worstBattery+1);
eo.worst_pair=pairs(worstBattery,:);
p=struct('ratings',ratings,'cruise_pair_kW',C,'high_lift_total_kW',H, ...
    'total_kW',C+H,'eo',eo,'normal_required_kW',context.con.PW_hp_lb*W*.745699872, ...
    'CL_L',context.CL_L,'bw_L',context.bw_L,'CL_TO',context.CL_TO,'bw_TO',context.bw_TO, ...
    'con',context.con,'driver',sprintf('residual high-lift: case %d %s',critical-1,labels{column}));
if H>worst*e.power_margin+1e-6, p.driver='residual high-lift: normal flight/field constraints'; end
p.constraints=table((0:4)',C+Hcase(:,1)*e.power_margin,C+Hcase(:,2)*e.power_margin, ...
    C+Hcase(:,3)*e.power_margin,C+Hcase(:,4)*e.power_margin, ...
    'VariableNames',{'FailedBatteryBank','LiftTarget_TotalInstalled_kW', ...
    'Approach_TotalInstalled_kW','TakeoffClimb_TotalInstalled_kW','GoAround_TotalInstalled_kW'});
p.critical_case=critical-1; p.critical_constraint=labels{column};
    function P=root(fun)
        if fun(0)>=0, P=0; return; end
        upper=ceiling-C;
        if fun(upper)<0, P=Inf; return; end
        low=0;
        for t=1:29
            mid=(low+upper)/2;
            if fun(mid)>=0, upper=mid; else, low=mid; end
        end
        P=upper;
    end
    function [margin,CL]=screen(H,k,j)
        rating=zeros(1,8); rating(tips)=C/2; rating(high)=H/6; rating=rating.*alive(k,:);
        V=e.VS_kt*1.688; rho=m.rho_SL; q=.5*rho*V^2;
        if j==1
            state=AEGAblownstate2035(m,S,b,layout,V,rho,rating,'landing',opt.retract_fraction,1);
            CL=state.CL_blown; margin=CL-W/(q*S*e.WS_margin); return
        elseif j==2
            V=e.approach_factor*e.VS_kt*1.688; gamma=-e.approach_deg*pi/180; cfg='landing';
        else
            V=e.climb_speed_kt*1.688; gamma=atan(e.selected_climb_gradient); cfg='landing';
            if j==3, cfg='takeoff'; end
        end
        q=.5*rho*V^2; CLreq=W*cos(gamma)/(q*S);
        zero=AEGAblownstate2035(m,S,b,layout,V,rho,zeros(1,8),cfg,opt.retract_fraction,1);
        drag=q*S*(CD0+zero.dCD_flap+CLreq^2/(pi*m.AR*m.e_osw));
        A=[layout.A_side layout.A_side]; drag=drag+q*e.failed_disk_CD*sum(A(~alive(k,:)));
        Treq=drag+W*sin(gamma);
        if Treq<0, margin=-1; CL=zero.CL_blown; return; end
        [~,state,control]=AEGAallocatepower2035(m,S,b,layout,V,rho,rating,cfg, ...
            opt.retract_fraction,1,Treq,CLreq/e.WS_margin,j==2);
        CL=state.CL_blown;
        margin=min((CL-CLreq/e.WS_margin)/max(CLreq,eps),control.thrust_margin_lb/W+1e-9);
        if j==2, margin=min(margin,-abs(control.thrust_margin_lb)/W+1e-9); end
    end
    function [margin,cx]=normal(H)
        rating=zeros(1,8); rating(tips)=C/2; rating(high)=H/6;
        total=C+H; mm=m; mm.prop_rating_each_kW=rating;
        % Landing lift credit comes from a force-balanced 60-kt allocation,
        % using the maximum attainable capacity rather than full-power lift.
        V=m.VS0*1.688; q=.5*m.rho_SL*V^2;
        zero=AEGAblownstate2035(m,S,b,layout,V,m.rho_SL,zeros(1,8),'landing',opt.retract_fraction,1);
        D=q*S*(CD0+zero.dCD_flap+zero.CL_unblown^2/(pi*m.AR*m.e_osw));
        T=max(0,D-W*sind(m.approach_angle));
        [~,land]=AEGAallocatepower2035(m,S,b,layout,V,m.rho_SL,rating,'landing', ...
            opt.retract_fraction,1,T,0,true,true);
        CL_L=land.CL_blown;
        Vto=1.1*sqrt(2*(W/S)/(m.rho_SL*m.CLmax_TO));
        take=AEGAblownstate2035(m,S,b,layout,Vto,m.rho_SL,rating,'takeoff',opt.retract_fraction,1);
        mm.landing_CL_for_roll=CL_L; fraction=.5;
        if isfield(mm,'reverse_rating_fraction'), fraction=mm.reverse_rating_fraction; end
        mm.reverse_available_shaft_kW=fraction*C; mm.reverse_cruise_rating_fraction=C/max(total,eps);
        con=AEGAconstraint(mm,CD0,false,W/S,CL_L,take.CL_blown);
        rows=AEGAflightphases2035(mm,W,S,b,layout,CD0,total,struct(),[],opt);
        rows=rows(rows.RequiredForSizing,:);
        clMargin=min(rows.CLmaxCredited-rows.CLrequired.*rows.RequiredLiftFactor.^2);
        forceMargin=min(rows.Thrust_lb-rows.RequiredThrust_lb)/W+1e-9;
        app=rows.Phase=="Approach";
        if any(app), forceMargin=min(forceMargin,1e-9-max(abs(rows.ThrustSurplus_lb(app)))/W); end
        margin=min([(total-con.PW_hp_lb*W*.745699872)/W clMargin forceMargin]);
        cx=struct('CL_L',CL_L,'bw_L',land,'CL_TO',take.CL_blown,'bw_TO',take,'con',con);
    end
end
