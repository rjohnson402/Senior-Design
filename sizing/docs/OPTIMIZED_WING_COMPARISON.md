**Workflow update (October 11):** Use [the three-study guide](THREE_MAIN_TRADES.md) and [the current commands](../README.md). Numerical examples below are dated snapshots and may use older inputs, AR18 or instantaneous reverse credit. The active concept is AR15.5, W/S27 with a conditional 6% ground-reverse target; see [the October12 configuration](REVERSE_CONFIGURATION.md). Adaptive full-span AR remains18. Old runners and standalone check commands are archived/private; use `AEGAtrades('check')`.

# Independently optimized fixed and adaptive wings

**Current inputs:** The polar-calibrated, no-reverse landing baseline and geometry handoff are documented in [INPUT_ASSUMPTIONS.md](INPUT_ASSUMPTIONS.md). Historical numerical sections below retain their original assumptions.

**October 11 revision:** use [the current review](../CURRENT_TRADE_REVIEW.md) for
new results. The search now uses W/S12–48, fixed AR8–18, taper .15–.70, and
20–45% allowed adaptive capability (still limited by lift, packing and nesting).
Landing is explicitly enforced. Mission speeds, reserve and propulsion/battery
technology follow current inputs. The common high-lift hubs accommodate a
3.2-ft prop envelope. Numerical tables farther below are historical.

**Current revision:** the runner now derives a substantial (at least 20%)
stroke capability from cruise lift, drag, hardware clearance and nesting, and
couples actual throttle, blown lift and flight-phase energy. See
[Coupled model, controls and limitations](COUPLED_FLIGHT_MODEL.md).
The initial numerical results and manual-retraction search described below
are retained as a historical comparison, before that revision.

Run `AEGAtrades('wings')` in MATLAB from this folder. The result
is `optimizedWings2035`, with a timestamped package in
`trade_results/optimized_wings_<timestamp>/`. Run
`check_optimizedwingcomparison2035` for mission, mass, geometry and export
checks. The original wing and telescoping check suites also remain applicable.

## Objective and shared requirements

Minimize **converged aircraft MTOW** for the same route, reserve, 400-lb
payload, atmosphere, fuselage, propulsion architecture and 2035 assumptions.
Every candidate closes wing size, tails, required power, battery and empty
weight together. A different wing shape is not compared at an arbitrarily
unchanged mass or undersized cruise-motor rating.

The fixed wing chooses **one geometry**, which stays unchanged in takeoff,
climb, each cruise leg, reserve and landing. The adaptive wing has **AR18 at
full extension**, uses full span for takeoff/climb/landing, and chooses its
lowest-power deployment separately for every cruise and reserve speed.
Different mission profiles represent alternative design requirements; each
profile has its own pair of independently optimized aircraft.

## Missions used in the initial comparison

| Profile | Route | Reserve |
|---|---|---|
| Current mission | 250 nm at 120 KTAS | 45 min at 120 KTAS |
| Illustrative mixed-speed mission | 50 nm at 100 KTAS, then 200 nm at 160 KTAS | 45 min at 120 KTAS |

The slower leg is 30 minutes and **counts toward** the same 250-nm route.
This is not an additional half-hour of circling on top of a 250-nm cruise.
The mixed case is an analyst example, not a newly agreed project requirement.
The assigned 300-nm requirement remains separate; the current negotiated
250-nm value comes from AEGAinputs.

## Verified initial results

The completed MATLAB R2026a run on 2026-10-07 is saved in
[`trade_results/optimized_wings_20261007_183708_373`](../trade_results/optimized_wings_20261007_183708_373/02_best_designs.csv).
It includes the widened wing-loading bounds and the common 1.2 x clean-stall
cruise-speed margin described below. Earlier exploratory runs use different
search bounds or operating margins; use this package for the comparison.

| Shared mission | Wing | MTOW (lb) | Full-span AR | W/S (lb/ft2) | Full span (ft) | Retractable span fraction | Added mechanism (lb) |
|---|---|---:|---:|---:|---:|---:|---:|
| 120-knot route | Fixed | 2,233.83 | 18.00 | 33.619 | 34.583 | 0 | 0 |
| 120-knot route | Adaptive | 2,246.38 | 18.00 | 33.673 | 34.652 | 2.502% | 7.045 |
| 100/160-knot example | Fixed | 2,709.26 | 17.98 | 32.419 | 38.764 | 0 | 0 |
| 100/160-knot example | Adaptive | 2,723.99 | 18.00 | 32.419 | 38.890 | 2.501% | 7.123 |

**All four selected wings use full span in every route and reserve phase.**
The adaptive search chooses essentially its smallest allowed mechanism,
2.5% retractable span, and adds 12.55 lb (0.562%) or 14.73 lb (0.544%) to MTOW.
These small differences do not establish a general conclusion about morphing
wings: they reflect the specified missions and the current aerodynamic model.
The fixed wing already receives the induced-drag benefit of a long span.

For the current mission, the best fixed geometry is approximately 66.45 ft2
area, 34.58 ft span, AR18 and .20 taper. Both families reach the .20 taper
boundary; fixed AR reaches or approaches the AR18 ceiling. These are bounded
numerical candidates. Local tip stall, real-airfoil polars and structure need
refinement before selecting that taper as a physical design.

The current mission's usable energy requirement is 124.44 kWh fixed versus
124.93 kWh adaptive. In the mixed example, the retained three-stop mission
sets the larger usable energy requirement: 176.70 versus 177.37 kWh, rather
than the mixed route's 167.10 versus 167.69 kWh.

The primary selections do **not** pass the optional 1,500-ft landing check:
the current mission gives approximately 1,541 ft and the mixed mission gives
1,504/1,503 ft. Landing enforcement remains disabled in the project inputs.
The separate landing-passing table reports examined alternatives (current
mission: 2,249.03 lb fixed and 2,262.48 lb adaptive); those alternatives have
not undergone their own landing-constrained optimization.

The optimized-wing, telescoping-wing and original wing-trade checks passed.
The full-run checks also confirmed that each selected MTOW is the lowest
passing evaluated value for that family/profile, mass residuals are below
.01 lb, and every mission phase meets its cruise stall margin and assigned
motor ratings. Both exported figures were visually inspected.

Edit `AEGAwingcomparisonprofiles.m`, or pass `opt.profiles`, to set speeds,
leg distances and reserve speed. Leg distances must sum to the range.
Selecting only `opt.profiles(1)` runs the current mission alone. A faster
example can be defined explicitly, without changing the project's inputs:

```matlab
msn = AEGAinputs();
opt = struct();
opt.profiles = struct('name',"Illustrative 90/180-knot route", ...
    'route_speed_ktas',[90 180],'route_distance_nm',[45 msn.range-45], ...
    'reserve_speed_ktas',120);
opt.doplot = false;  % direct call without output_dir does not save files
opt.save_plots = false;
study = AEGAoptimizewings2035(msn,opt);
```

No result for that optional 180-knot example is implied by the initial run.

## Design variables and bounds

| Variable | Fixed wing | Adaptive wing |
|---|---|---|
| Full-wing loading | 18-48 lb/ft2 | 18-48 lb/ft2 |
| Aspect ratio | 8-18, one value for all phases | 18 at full extension |
| Taper ratio | .20-.65 | .20-.65 |
| Fraction of maximum span retractable | 0 | .025-.30 |
| Cruise / reserve deployment | Always full span | Independently optimized at each speed |

Wing area is MTOW divided by full-wing loading. Span is
sqrt(AR x wing area). These are related sizing outputs, not separately free
variables. The fully extended shape remains the common trapezoid used by
the telescoping study. Hidden panel area is removed from aerodynamic area.

The search first covers a coarse grid, then runs two local refinements from
the lowest-weight passing grid points. Normalized variables and explicit
bound penalties keep refinement inside the domain. The exported result is
the **best found within these bounds**, not a proven global optimum. A design
at a boundary is marked; expanding that boundary may change the result.
Low taper ratios particularly need local stall, airfoil and control checks
before treating a numerical minimum as a recommended physical wing.

The wing-loading bound was widened from 40 to 48 lb/ft2 after the initial
fast-mission minimum reached 40. Powered-lift, cruise/reserve operating lift
margin and hardware-fit checks reject infeasible candidates inside that
wider search. A common **1.2 x clean-stall-speed minimum** is imposed on route
and reserve: the phase CL limit is `CLmax_clean/1.2^2`. This is an explicit
analyst operating margin, not a claimed regulatory minimum. The exported
stall-speed factor shows the actual margin at each phase.

The objective is MTOW, rather than minimum drag at one speed. Required usable
energy, project energy, battery mass and installed power are also exported
to show why a geometry wins. The phase optimizer minimizes battery power at
fixed speed and geometry, which also minimizes energy for that fixed leg.

## Propulsion and low-speed constraints

Both aircraft have six 2.8-ft high-lift propellers and two 4.5-ft cruise
propellers. Diameters are held common; they are not search variables. Only
the cruise propellers operate during cruise and reserve.

For this independent wing comparison, the six high-lift hubs use common
physical stations measured from the aircraft centerline: 3.55, 6.50 and
9.45 ft per side, including a .15-ft root/disc gap allowance. The cruise hub
is at the fixed wingtip for the fixed design and the stationary core tip
for the telescoping design. Hubs do not move with deployment. Clearances
and disjoint propeller disks are checked, and candidates that cannot fit
the hardware at their converged geometry fail the screen.

This common physical-station layout differs from the earlier telescoping
study's .21/.39/.57 full-semispan layout. Differences between the two studies
cannot be attributed solely to optimization or mechanism mass.

Cruise motors are **sized for the largest required shaft power across all
mission speeds**, rather than failing a faster mission against the old
120-knot aircraft's ratings. The existing disk-area allocation gives their
share of total installed power. Consequently, raising cruise power also
raises the other motors' allocated ratings, with the motor/inverter/cooling
mass penalties included. Independent optimization of cruise versus high-lift
ratings would require a revised low-speed failure/blowing model.

The same existing takeoff, climb, turn and four mirrored-pair battery-out
power screens apply to both families. The normal constraint model evaluates
its legacy cruise bound on the full-span wing; the explicit two-motor phase
power bound is also applied. This is conservative if that legacy bound
governs a retracted high-speed state. Clean-stall and landing-distance
enforcement preserve AEGAinputs (currently disabled); the numerical landing
check is still reported. Cruise/reserve clean CLmax is screened at every
phase, with the 1.2 x operating margin, even when the separate 59-KCAS
operational clean-stall target is off. A separate table identifies the best
examined candidates also passing the modeled 1,500-ft landing check; it is
not a separate fully refined landing-constrained optimization. The landing
model still assumes the team's unverified 8% reverse-thrust capability.

## Mission and technology accounting

`AEGAmultispeedmission.m` evaluates each route leg and reserve on the same
airframe. Full-aircraft parasite area is referenced to the profile's peak
speed and held constant between phases; visible wing friction, joint drag,
span and induced drag change with deployment. Phase energy uses the same
force-distance and energy-unit constants as AEGAmission. It retains the
existing 4% overhead allowance, including reserve. A single-speed profile
reproduces the original sizing result.

The separate 150-nm, three-stop mission remains enabled, evaluated using
the profile's peak cruise speed. Its takeoffs and climbs use full span.
Required battery energy is the larger of the project profile energy and
that mission floor. This choice is identical for both families and is
visible in `MissionDriver`; it may govern a nominally economical mixed route.

For structure and control mass, the design cruise speed is the highest
route/reserve speed, with the inherited +50-knot dive-speed margin. A faster
profile therefore changes structural dynamic-pressure sizing for both
families. This is a conceptual speed assumption, not a validated flight
envelope or flutter check.

Both use 400 Wh/kg **pack**, 90% usable capacity, and the optimistic .80
wing-mass factor relative to the already-composite FLOPS estimate. Only the
adaptive wing adds the researched lightweight-target mechanism and flush
sealed joint drag. The seven component sets and independent mass/drag
uncertainties remain available in the original telescoping trade; the main
optimizer uses the lightweight target, not the minimum-mass target.
See [Research, component mass and drag qualifications](TELESCOPING_TRADE.md).

## Outputs

- `01_evaluated_designs.csv`: every unique evaluated geometry, including
  failed cases, stage, drivers, mass/power/energy and clearance failure status.
- `02_best_designs.csv`: one selected fixed and one selected adaptive wing
  per profile, with MTOW differences and search-boundary flags.
- `03_selected_mission_phases.csv`: actual route/reserve deployments, areas,
  spans, ARs, power, energy and assigned cruise-motor ratings.
- `04_selected_speed_sweep.csv`: unchanged selected aircraft across speeds,
  with clean-lift, motor-power and model-speed screening.
- `07_best_sampled_with_landing_check.csv`: best examined points also passing
  the optional modeled landing-distance check, retained alongside the main
  selections when that requirement is not enforced.
- `05_optimized_comparison.png/.fig`: coarse weight envelopes and selected
  refined results.
- `06_selected_span_and_power.png/.fig`: selected wingspan and power versus
  speed for each mission alternative.
- `optimized_wing_comparison.mat`: portable tables, inputs, options and full
  selected sizing records in variable `saved`.
- `RUN_NOTES.txt`: executed settings, accounting choices and limitations.

The model does not resolve real-airfoil drag polars, trim, local tip stall,
load-dependent Oswald efficiency, aeroelasticity, detailed nesting, locks,
asymmetric jams, flutter, blade Mach or battery-bank energy accessibility.
These limitations can change the size of the adaptive advantage. The
optimizer supplies candidates for a higher-fidelity comparison; it does not
establish a flight-ready optimum.
