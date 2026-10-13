function check_structuralassumptions2035()
% Material credit must affect fuselage totals once and survive sizing/studies.
m=AEGAinputs(); m.ULF=3.8; m.FCOMP=.9;
m.wing_mass_factor=1; m.fuselage_mass_factor=.8;
st=struct('DG',2200,'SW',80,'SHT',20,'SVT',15);
carbon=AEGAweight(m,st);
plain=m; plain.fuselage_mass_factor=1; raw=AEGAweight(plain,st);
delta=carbon.fuse-raw.fuse;
assert(abs(carbon.fuse-.8*raw.fuse)<1e-10);
assert(abs(carbon.fuse_before_material-raw.fuse)<1e-10);
assert(abs(carbon.wing-raw.wing)<1e-10,'Fuselage credit changed wing weight.');
assert(abs(carbon.structure-raw.structure-delta)<1e-10);
assert(abs(carbon.margin-raw.margin-m.fmarg*delta)<1e-10);
assert(abs(carbon.empty-raw.empty-(1+m.fmarg)*delta)<1e-10);
old=rmfield(plain,'fuselage_mass_factor'); archived=AEGAweight(old,st);
assert(abs(archived.empty-raw.empty)<1e-10,'Old input structs changed.');
stronger=m; stronger.ULF=6; high=AEGAweight(stronger,st);
assert(high.wing>carbon.wing && high.fuse>carbon.fuse);
assert(abs(carbon.fuse/high.fuse-(3.8/6)^.177)<1e-10);
% VSP area must affect both weight and drag while retaining old-struct fallback.
estimated=m; estimated.fuselage_wetted_ft2=[];
estimate=AEGAweight(estimated,st);
vsp=estimated; vsp.fuselage_wetted_ft2=300;
measured=AEGAweight(vsp,st);
assert(measured.SWFUS==300);
assert(abs(measured.fuse/estimate.fuse-(300/estimate.SWFUS)^1.086)<1e-10);
de=AEGAparasiticdrag(estimated,st.SW,st.SHT,st.SVT);
dv=AEGAparasiticdrag(vsp,st.SW,st.SHT,st.SVT);
assert(dv.fuselage_wetted_ft2==measured.SWFUS);
assert(abs(dv.fuselage_ft2/de.fuselage_ft2-300/estimate.SWFUS)<1e-10);
missing=rmfield(estimated,'fuselage_wetted_ft2');
assert(AEGAfuselagewettedarea(missing)==estimate.SWFUS);
out=AEGAsize(m); uncredited=AEGAsize(plain);
assert(out.converged && out.feasible);
assert(out.options.wing_mass_factor==1);
assert(abs(out.W.wing-out.W.wing_before_technology)<1e-10);
assert(abs(out.W.fuse-.8*out.W.fuse_before_material)<1e-10);
assert(abs(out.W.empty+m.payload-out.MTOW)<out.options.weight_tolerance);
assert(uncredited.MTOW>out.MTOW,'Removing fuselage savings must increase sized mass.');
fprintf('PASS: single fuselage material credit, margin/empty closure, historical fallback, ultimate-load response, and sized wing/fuselage factors.\n');
end
