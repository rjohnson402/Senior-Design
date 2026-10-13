**Workflow update (October 11):** Use [the three-study guide](THREE_MAIN_TRADES.md) and [the current commands](../README.md). Numerical examples below are dated snapshots and may use older inputs, AR18 or instantaneous reverse credit. The active concept is AR15.5, W/S27 with a conditional 6% ground-reverse target; see [the October12 configuration](REVERSE_CONFIGURATION.md). Adaptive full-span AR remains18. Old runners and standalone check commands are archived/private; use `AEGAtrades('check')`.

The older fixed-geometry telescoping sweep described below is archived. The active replacement is `AEGAtrades('wings')`, which independently optimizes both families.

# 2035 fixed-motor telescoping-wing trade

**Current inputs:** The polar-calibrated, no-reverse landing baseline and geometry handoff are documented in [INPUT_ASSUMPTIONS.md](INPUT_ASSUMPTIONS.md). Historical numerical sections below retain their original assumptions.

Run `run_telescopingtrades2035` in MATLAB from the sizing folder. Run
`check_telescopingtrades2035` for the physics and export checks. The returned
workspace variable is `telescoping2035`; each execution preserves previous
results in `trade_results/telescoping_<timestamp>/`.

The maximum aspect ratio is **18**. Takeoff, climb, landing and go-around use
full span. Cruise chooses the lowest-power deployment at the specified speed.
The design mission stays **250 nm plus 45 minutes reserve at 120 KTAS**;
300 nm remains the original assigned requirement. The separate three-stop,
150-nm mission stays enabled. Faster speed points are a cruise sensitivity
on the same aircraft, not a new mission-sizing speed or validated envelope.

## What replaced the old penalties

The former 0/1/2 values multiplied both an assumed mechanism mass and a
constant joint drag area: 0 meant a free mechanism, 1 the original estimate,
and 2 double the estimate. They did not denote extension positions or pounds.
That sensitivity was too coarse and coupled two separate uncertainties.
`penalty_scales` now produces an explicit obsolete-option error.

The new study compares **seven explicit component target sets**, all with
positive hardware mass when there is a moving panel. It also tests an
independent **0:2:30 lb additional hardware allowance**, on top of the
lightweight target, and three independent surface/seal-quality cases.
Additional mass reduces the fixed-MTOW battery budget including the normal
5% aircraft margin. It does not also increase drag.

## Research and the 2035 assumptions

| Topic | Evidence | Applied assumption and qualification |
|---|---|---|
| Battery pack | NASA's notional roadmap gives 350-400 Wh/kg for 2035. | 400 Wh/kg **pack**, 90% usable: optimistic end of that roadmap. This is not a cell value or a qualified product. |
| Wing structure | FLOPS includes explicit composite utilization terms. | Keep `FCOMP=.9` and apply a whole-wing factor of 1.00 for every design. The prior additional .80 factor has been removed to avoid stacking composite credits. |
| Fuselage structure | NASA transport fuselage studies reported 16.4–21.8% composite savings. | Apply a single .80 factor to raw FLOPS general-aviation fuselage weight for the carbon monocoque concept. This is a team target, not a measured trainer saving. |
| Telescopic actuation | A tested wing-box prototype separates a 0.270-kg actuation assembly from 1.780 kg of structure; 2.05 kg total for one box. | Separate actuators, bearings/guides and lap structure. Do not transfer the prototype's total mass directly to a full-size occupied aircraft. |
| Lightweight structure | Published span-morphing topology studies reduce particular spars/ribs substantially. | Use thin CFRP sleeve targets and local reinforcement rather than adding 10% of the entire wing. Component reductions are not applied as a second blanket wing credit. |
| Carbon material | Hexcel M21 UD laminate data give density about 1.58 g/cm3 and distinguish unnotched, open-hole and damaged strength. | Use 1,600 kg/m3. Cap and web allowables below are analyst targets with knockdowns; they are not joint certification allowables. |
| Joint drag | NASA experiments show strong sensitivity to steps; gaps alone do not determine the penalty. | Explicit step height, leakage, seam orientation and added fairing area. No measured trainer-scale telescopic-joint correlation was found. |

Sources supporting the battery roadmap and its limitations:
[NASA battery workshop introduction, slide 17](https://www1.grc.nasa.gov/wp-content/uploads/1.-NASA-Intro.pdf).
NASA's wing benefit is a transport research target, not a demonstrated trainer
reduction: [Fixed Wing Project, slide 12](https://ntrs.nasa.gov/api/citations/20150009967/downloads/20150009967.pdf).

The tested mass breakdown is in Santos's thesis, printed page 135, Table 4.10:
[University of Beira Interior thesis](https://ubibliorum.ubi.pt/bitstream/10400.6/4827/3/PhD_Thesis-PDRSantos.pdf).
It uses lightweight composite boxes, rack/pinion drive and PTFE guides.
The published wing-box work also tested repeated movement under loading;
this informs the architecture, not the reliability of the proposed trainer.

The topology study supports careful local optimization, rather than a whole
wing percentage copied from optimized individual parts:
[Structural sizing and topology optimization of a span-morphing wing](https://pmc.ncbi.nlm.nih.gov/articles/PMC8544218/).
Material density and the importance of strength knockdowns are supported by
[Hexcel M21 data sheet](https://www.hexcel.com/wp-content/uploads/2025/12/HexPly_M21_global_DataSheet.pdf).

Motor and inverter specific power remain the team's aggressive targets:
15 and 14 kW/kg, with efficiencies .95 and .97. No extra future discount is
applied to the motor installation, cooling or wiring. NASA's HEMM 16-kW/kg
metric is an **electromagnetic** metric for a megawatt machine; it does not
validate a complete small-aircraft installed motor at that figure:
[NASA HEMM overview](https://ntrs.nasa.gov/citations/20210018170).

## Incremental mechanism weight

`AEGAtelescopingassumptions2035.m` contains all seven editable bills of
materials. `AEGAtelescopingmechanism.m` evaluates them as span, chord, stroke,
overlap and aircraft weight change. The moving tip's normal structure is
already in the full-span wing estimate; only additional telescoping hardware
and overlap are added. Actuators move the panel; guides and locks carry flight
loads. The motor/propeller mounting stays on the stationary core.

| Component target | Lightest build | Lightweight target (default) | Upper lightweight allowance |
|---|---:|---:|---:|
| Actuator base per side, kg | .35 | .517 | .85 |
| Additional actuator kg/m of stroke, per side | .08 | .133 | .24 |
| Complete guide assembly kg/m, per side | .12 | .20 | .36 |
| Locks/bearing blocks per side, kg | .45 | .70 | 1.20 |
| Controls/wiring, total kg | .25 | .367 | .60 |
| Seal kg/m of seam | .035 | .057 | .10 |
| Additional sleeve laminate, mm | .25 | .45 | .85 |
| Cap target allowable, MPa | 600 | 520 | 360 |
| Web target allowable, MPa | 35 | 30 | 20 |
| Minimum overlap per side, m | .25 | .283 | .35 |
| Overlap/stroke ratio | .35 | .417 | .55 |
| Local fittings, fraction of calculated overlap structure | .15 | .233 | .40 |
| Torsion/buckling/stiffness reserve, fraction of overlap structure | .20 | .333 | .60 |

There are four additional intermediate builds. These are deliberately
optimistic design targets, not catalog actuator selections or measured
full-scale mechanism weights. Minimum-gauge manufacturability, lock contact
pressure and stiffness can require much more material than strength alone.

For each stationary joint, an elliptic lift distribution is integrated from
that joint to the extended tip at the input **3.8 ultimate load factor**, applied directly.
The resulting outboard shear V and bending moment M determine an incremental
lap-cap area `2*M/(cap_separation*cap_allowable)` and web area
`V/web_allowable`. These areas are multiplied by overlap length, CFRP density
and two wings. A minimum-gauge rectangular box sleeve, local fittings and a
stiffness/torsion reserve are added. Overlap is the larger of its minimum
length and the chosen fraction of stroke.

No active gust-load-alleviation credit, motor inertia relief or retracted-only
structural sizing is used. The sleeve model is a preliminary strength-based
mass estimate with allowance for other requirements; it is not a complete
joint stress, buckling, torsion or deflection solution. The code checks that
panel length plus overlap can fit longitudinally inside the core. It does
not solve the tapered cross-section nesting or internal systems clearance.

## Incremental joint drag

`AEGAtelescopingjointdrag.m` computes total added equivalent drag area for
both joints. With joint chord c, approximate upper/lower seam length is 4c.
The incremental area includes:

- Step area: seam length x residual step height x .25 orientation factor x
  .5 effective step coefficient.
- Leakage area: seam length x gap width x unsealed fraction x .6 coefficient.
- Additional lip/fairing wetted area: seam length x strip width x .0033 skin
  friction x 1.3 form factor.

The orientation and effective coefficients are explicit **analyst estimates**.
They describe a largely chordwise seam and are not NASA or ESDU empirical
coefficients. Fairing area is an additional lip/overlap allowance; the wing's
baseline wetted area remains accounted for separately. All three terms are
incremental to the existing generic `excr` factor.

| Surface/seal case | Closed/extended step, mm | Gap, mm | Unsealed fraction | Added strip width, mm |
|---|---:|---:|---:|---:|
| Flush sealed target (default) | .10 / .25 | .25 | .01 | 15 |
| Small step / good seal | .20 / .50 | .50 | .05 | 25 |
| Visible step / imperfect seal | .50 / 1.00 | 1.00 | .15 | 40 |

Step height interpolates with deployment; joint chord changes with the
retractable fraction and sized geometry. The independent seal study holds
mechanism mass targets fixed while changing these drag parameters.
No laminar-flow benefit is assumed: the baseline wing friction model is
already turbulent. Wind-tunnel testing or CFD should replace the effective
coefficients before using these small drag values as a design prediction.

NASA's [subsonic tile/step experiments](https://ntrs.nasa.gov/citations/19770042019)
show why steps need separate treatment from gaps. Their tile drag magnitudes
are not transferred to this wing. NASA's [forward-facing step study](https://ntrs.nasa.gov/citations/20205003053)
likewise establishes sensitivity to surface imperfections, not a coefficient
for the proposed mechanism.

## Geometry and flight-phase schedule

The fully extended wing is a common trapezoid with the input taper ratio .35.
The earlier OpenVSP sketch used a tapered core and constant-chord extension;
these trades do not regenerate that sketch or claim the planforms match.

Retractable fraction r is a fraction of **maximum total span**:
`b_min=(1-r)*b_max`, and each side's stroke is `r*b_max/2`. The default grid
is 0:2.5:20%. Zero is a fixed full-span wing, without moving hardware.

At deployment f, visible area is integrated from the outer tapered panel:
`S(f)/Smax = 1-(2*lambda*r+(1-lambda)*r^2)/(1+lambda)`
`+ (2*lambda*r*f+(1-lambda)*r^2*f^2)/(1+lambda)`.
Actual AR is `b(f)^2/S(f)`. Hidden area does not produce lift in this model.
This geometry approximation does not establish mechanical feasibility of
nesting a tapered airfoil inside another tapered airfoil.

At fixed range, close weight with `Smax=MTOW/WSmax` and
`bmax=sqrt(18*Smax)`. At fixed MTOW, maximum geometry stays identical across
all retractable fractions and all mechanism cases. Remaining weight after
payload and dry mass becomes battery, and the existing mission energy
expression is inverted for range with reserve and overhead retained.

Six 2.8-ft high-lift propellers are stowed in cruise; two 4.5-ft cruise
propellers remain active. Cruise motor hubs sit at the fixed core tips, at
`(1-r)*bmax/2`. Changing r changes the mounting station between designs;
changing deployment does not move the motors on any one design. High-lift
hubs remain at .21/.39/.57 of full semispan. Disk clearances are screened.
Ratings use the inherited disk-area power allocation. Oswald efficiency
stays .8, with no wingtip-prop/vortex drag credit.

`AEGAtelescopingcruise.m` minimizes drag, hence battery power at fixed speed,
disk area and efficiency model. It compares both endpoints and an interior
optimum, restricted by clean CLmax where a feasible state exists. Full span
can remain optimal in cruise; the optimizer does not force retraction.
`opt.cruise_deployment=0` or `1` still allows a forced schedule for the main
mission comparison. The speed sweep always reports the adaptive optimum.

The speed sweep defaults to 80:5:200 KTAS on the **same aircraft and installed
motors**, without resizing structure or power at every speed. Low-speed
points failing clean lift, points exceeding assigned cruise-motor shaft
rating, and speeds above the inherited 170-KTAS model ceiling are flagged.
That ceiling is not a validated Vne or a flutter result. Required and
assigned shaft rating per cruise motor are exported. The simple propeller
model does not establish blade Mach, tip clearance under deflection or noise.

## Verified run and implications

MATLAB R2026a passed `check_telescopingtrades2035` and the existing
`check_wingtrades2035` on 2026-10-07. The full updated run is
`trade_results/telescoping_20261007_145631_278`.

At 20% retractable span:

| Quantity | Updated result |
|---|---:|
| Fixed extended reference MTOW | 2,263.67 lb |
| Added hardware across seven builds, at fixed MTOW | 6.48-20.51 lb |
| Lightweight target added hardware, at fixed MTOW | 10.51 lb |
| Lightweight target MTOW at 250 nm | 2,280.38 lb (+16.71 lb) |
| Lightweight target range at 2,263.67 lb | 245.80 nm (-4.20 nm) |
| Total nominal cruise joint drag area | .00180 ft2 |
| Good-seal / imperfect-seal joint areas | .00342 / .00715 ft2 |

All those mission comparisons retain 45 minutes reserve. The optimized
deployment is fully extended at 120 and 160 KTAS. At 170 KTAS it is about
88% of available stroke, but the required shaft power is 42.2 kW per cruise
motor versus the current assigned 31.4 kW per motor. At 200 KTAS the optimum
is about 21% deployed, requiring about 64.5 kW per motor; this also exceeds
the model speed ceiling. Those are numerical sensitivity points, not
proposed operations on the current hardware. At sampled speeds through
150 KTAS the selected cruise-motor rating passes for this design.

The small weight and drag penalties follow deliberately light component and
flush-seal assumptions. They are not evidence that a complete trainer-scale
telescoping mechanism will weigh 10.5 lb. The component mass and added-weight
plots let the team replace these targets or add a stiffness/durability
allowance without hiding it inside a multiplier.

## Screens and result files

The normal and mirrored-pair battery-out power screens remain enabled.
Landing and clean-stall enforcement retain the team's input flags (currently
disabled). Maximum-span clean stall is still about 76.9 KCAS at W/S 32;
these studies do not meet the disabled 59-KCAS clean-stall target.

A finite single-trip range can fail the separate repeated-departure mission.
Such values remain in the table with `PassesScreen=false`. At fixed MTOW,
`AvailableBattery/Pack/Usable` fields are actual budgets; `Battery/Pack/Usable`
fields are what all enforced missions require. Battery discharge does not
reduce aircraft weight. Deployment energy is not explicitly modeled; the
existing mission overhead remains in place.

| Output | Contents |
|---|---|
| 01 / 02 CSV | Fixed-range MTOW and fixed-MTOW range, component weights, joint drag, geometry, flags and drivers |
| 03 PNG/FIG | Seven component-build MTOW and range curves |
| 04 PNG/FIG | Design-speed deployment, AR, mechanism mass and battery budget |
| 05 / 06 CSV | Exact component and seal assumptions |
| 07 CSV; 09 PNG/FIG | Adaptive cruise speed schedule and power/rating flags |
| 08 CSV | Independent seal-quality sensitivity |
| 10 PNG/FIG | Component breakdown and weight sensitivity in actual pounds |
| 11 CSV | Extra-hardware allowance sweep in 2-lb steps |
| MAT / RUN_NOTES | Inputs, detailed sizing records, tables, model version and execution notes |

The seven build names express component targets, not alternate certified
mechanisms. A fully detailed sleeve/rail/lock design, stiffness and flutter
checks, asymmetric-jam handling, control integration and packaging remain
necessary before selecting hardware. The range advantage of adaptability
must be compared against a fixed extended wing across a specified speed
mission; at 120 knots the fixed extended reference can still be lighter and
have more range.
