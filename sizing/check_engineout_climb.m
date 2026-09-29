function check_engineout_climb()
% Uses the unchanged baseline inputs and the user's rounded reference result.
m = AEGAinputs();
r = struct('MTOW',2789.7,'WSR',38.9584,'PTO_kW',175.2248, ...
    'CD0',0.0257,'CLmax',3.2616,'CLmax_TO',3.2420);
o = struct('WS',r.WSR,'doplot',false,'print',false,'ratio',1.3);
s = AEGAengineout(m,r,o);
for f = 1:3
    d = s.family(f).reference;
    p = d.climb_hp_lb;
    assert(all(isfinite(p(:))));
    delta = diff(p,1,2);
    assert(all(delta(:)>=-1e-8),'Climb gradient should increase required power.');
    assert(all(d.required_hp_lb>=d.approach_only_required_hp_lb-1e-8));
    selected = max(p(:,3,:),[],3);
    assert(max(abs(d.required_hp_lb-max(d.approach_only_required_hp_lb,selected)))<1e-8);
end
o.include_climb = false;
old = AEGAengineout(m,r,o);
assert(abs(old.family(2).reference.required_hp_lb(30)*r.MTOW*.745699872-183.168)<0.1);
fprintf('Engine-out climb checks passed.\n');
end
