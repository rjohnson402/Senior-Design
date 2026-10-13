function s = AEGAblownstate2035(msn,S,b,layout,V,rho,P_each,cfg,r,f)
% Actuator-disk slipstream lift CAPACITY at actual per-motor shaft power.
% Dynamic-pressure integration with contracted, disjoint wakes; not CFD.
% Preserve area of the existing nested trapezoid at every deployment.
if nargin<9, r=0; f=1; end
assert(V>0 && rho>0 && all(P_each>=0) && numel(P_each)==8);
semi = b/2; core = (1-r)*semi; visible = core+r*f*semi;
cr = 2*S/(b*(1+msn.TR)); ct = msn.TR*cr; slope = (ct-cr)/semi;
area = 2*strip(0,visible);
yroot = msn.WFus/2;
yflap = min([msn.flap_span_frac*semi core visible]);
flap_frac = 2*strip(yroot,yflap)/area;
switch cfg
    case 'landing'
        dcl = msn.dclmax_flap_L*msn.K_flap_sweep;
        clean = msn.CLmax_clean; base = clean+dcl*flap_frac;
        dCD = msn.CD_flap_factor*msn.flap_chord_frac*flap_frac*sind(msn.flap_def_L)^2;
    case 'takeoff'
        dcl=0; clean=msn.CLmax_TO; base=clean; dCD=.03;
    otherwise
        dcl=0; clean=msn.CLmax_clean; base=clean; dCD=0;
end
A = [layout.A_side layout.A_side]; y = [layout.y_side layout.y_side];
D = [layout.D_side layout.D_side];
Q = msn.prof*P_each(:).'*737.56./(2*rho*A);
vi = min(Q/V^2,nthroot(Q,3));
for it=1:32
    next=max(0,vi-(vi.*(V+vi).^2-Q)./((V+vi).*(V+3*vi)));
    done=max(abs(next-vi))<1e-10*(1+max(next)); vi=next;
    if done, break; end
end
ue=V+2*vi; width=D.*sqrt((V+ue)./(2*ue));
increment=0; blown_area=0;
for j=1:8
    if P_each(j)<=0, continue; end
    y1=max(y(j)-width(j)/2,yroot); y2=min(y(j)+width(j)/2,visible);
    a=strip(y1,y2); af=strip(max(y1,yroot),min(y2,yflap));
    increment=increment+(clean*a+dcl*af)*((ue(j)/V)^2-1)/area;
    blown_area=blown_area+a;
end
capacity=min(base+increment,msn.CLmax_cap);
s=struct('CL_unblown',base,'CL_blown',capacity,'DeltaCL',capacity-base, ...
    'CL_uncapped',base+increment,'thrust_lb',sum(2*rho*A.*vi.*(V+vi)), ...
    'thrust_each_lb',2*rho*A.*vi.*(V+vi), ...
    'blown_area_fraction',min(1,blown_area/area),'dCD_flap',dCD, ...
    'visible_area_ft2',area,'shaft_each_kW',P_each(:).');
    function a=strip(y1,y2)
        if y2<=y1, a=0; return; end
        y1=max(0,y1); y2=min(visible,y2); a=0;
        if y1<core
            x2=min(y2,core); a=cr*(x2-y1)+.5*slope*(x2^2-y1^2);
        end
        if y2>core
            x1=max(y1,core)-core; x2=y2-core;
            cjoint=ct-slope*r*f*semi;
            a=a+cjoint*(x2-x1)+.5*slope*(x2^2-x1^2);
        end
    end
end
