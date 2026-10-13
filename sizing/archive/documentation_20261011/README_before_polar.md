# AEGA sizing and trade studies

For the **October 13 midterm**, start with the
[updated three-study review](CURRENT_TRADE_REVIEW.md). Run
`run_currenttrades2035` to regenerate wing loading/AR, fixed versus telescoping,
and cruise/high-lift prop sizing from current inputs, with expanded bounds,
coupled phases and landing enforced. Shared ranges/layout are in
`AEGAstudysettings2035.m`; mission and propulsion technology come from
`AEGAinputs.m`. The original input file is not changed by the studies.

[The earlier trade-study review](MIDTERM_TRADE_REVIEW.md) and root files in
`midterm_review/` retain the October 10 snapshots, including the battery/range
backup. `prepare_midterm_review2035` regenerates that historical curation;
use `run_currenttrades2035` for the three updated main studies.
The legacy fixed-weight prop-family study has moved into
[the midterm archive](archive/midterm_retired_20261010/README.md).

## Start here

For **cruise-prop diameter versus constraint-sized high-lift props**, run
`run_cruiseproptrades2035`. It compares 2–6-ft cruise props while shrinking
six high-lift props, re-closing MTOW and checking the normal constraints,
actual-throttle phases, modeled landing distance and battery-bank failures.
Constraint calls stay quiet; only three study summary figures open. High-lift
diameters now cover 1–3.2 ft, with common hubs spaced for the upper envelope.
Latest numerical selections and boundary flags are in the updated review.
Motor ratings remain proportional to disk area; this is not
an independent power-allocation optimization. See
[Cruise-prop trade controls, results and limitations](CRUISE_PROP_TRADE.md).

For the **independently optimized fixed-versus-adaptive wing comparison**, run
`run_optimizedwingcomparison2035`. It minimizes MTOW for each shared mission,
optimizes one fixed geometry, and compares it with a telescoping wing held at
AR18 when fully extended. Both can choose wing loading and taper; the fixed
wing can choose its constant AR, while the adaptive wing chooses retractable
stroke from cruise lift, drag, fixed-prop clearance and panel nesting. Both
now include actual-throttle blown lift, operating phase screens and explicit
phase energy. The adaptive wing has at least 20% retractable-span capability,
with cruise deployment selected for lowest drag. Cruise motors are sized for the actual
mission speeds. The initial profiles are the current 120-knot mission and a
labeled 100/160-knot example. See
[Optimization objective, missions and assumptions](OPTIMIZED_WING_COMPARISON.md).
See [Current coupled flight model](COUPLED_FLIGHT_MODEL.md) for the revised
physics, throttle definition, retraction limits and energy accounting.

The historical October 8 coupled run found **2,245.4 lb fixed versus 2,260.6 lb adaptive**
on the 120-knot mission, with 20% adaptive stroke capability and full span
selected in cruise. The mixed-speed example gives 2,592.9/2,614.5 lb. Actual
phase throttle and powered lift are in
[the flight-phase table](trade_results/optimized_wings_20261007_190112_237/08_all_flight_phases.csv)
and [phase plots](trade_results/optimized_wings_20261007_190112_237/09_throttle_and_blown_lift.png).
All four check suites passed; the selected geometries were re-evaluated with
unchanged MTOW and energy. The current mission selections still slightly miss
the optional landing-field check; see the coupled-model notes.

The earlier optimization, before explicit phase coupling, found 2,233.8 lb for the fixed wing and
2,246.4 lb for the adaptive wing on the current 250-nm, 120-knot mission with
45-minute reserve. Both select approximately AR18 and .20 taper; adaptive
cruise remains fully extended. The adaptive wing is 0.56% heavier and chooses
the 2.5% lower bound on retractable span. These are bounded conceptual minima;
the optional 1,500-ft landing constraint is currently not enforced and these
primary selections miss it. Results, landing-passing sampled alternatives,
and inspected plots are in the
[completed optimization package](trade_results/optimized_wings_20261007_183708_373/02_best_designs.csv).
All three MATLAB check suites passed on 2026-10-07.

The main design trade is **wing loading**, in `AEGAwingtrades.m`.
Run `run_wingtrades2035.m` from this folder in MATLAB to generate the active
study package. Run `check_wingtrades2035` first for physics and export checks.
`Hub.m` remains the entry point for the original baseline sizing calculation.

For the fixed-motor telescoping-wing concept, run **`run_telescopingtrades2035`**.
It holds maximum AR at 18, varies how much span can retract, and uses
power-adaptive cruise with extended takeoff, climb and landing. It compares
MTOW at fixed range with range at fixed MTOW. Seven explicit lightweight
2035 component builds replace the former 0/1/2 penalty multipliers, with
independent extra-hardware-weight and seal-quality sensitivities.
See [Telescoping trade assumptions and controls](TELESCOPING_TRADE.md).
`check_telescopingtrades2035` checks geometry, component mass/loads, energy/weight
closure, adaptive cruise, fixed hardware, the flight-phase schedule and exports.
Both it and the existing wing-trade checks passed
in MATLAB R2026a on 2026-10-07.

The researched 2035 case uses 400 Wh/kg at pack level and an optimistic 20%
wing-weight reduction relative to the already-composite FLOPS wing estimate.
Its fixed-wing reference is 2,263.7 lb. At 20% retractable span, the lightweight
target adds about 10.5 lb of hardware: fixed-range MTOW is 2,280.4 lb and
fixed-MTOW range is 245.8 nm, with 45-minute reserve retained. Full span remains
the minimum-power choice at 120 KTAS. Partial retraction begins at higher
speeds that exceed the current assigned cruise-motor ratings; those speed
points are explicitly flagged. These are conceptual targets, not validated
mechanism weights or joint drag measurements.

The current input case is **W/S = 32 lb/ft², AR = 13**. Run `Hub` in MATLAB
to size it. `AEGAsize` holds `msn.WS_design` fixed while resizing weight,
wing area, tails and propellers. Set `msn.WS_design = []` to return to
automatic wing-loading selection. Trade studies use their own W/S grids.

The saved wing-loading study is already available:

- [Aircraft weight, wing size and battery plots](wingtrade_results/02_size_and_battery.png)
- [Installed power and governing constraints](wingtrade_results/01_power.png)
- [Wing-loading data](wingtrade_results/01_wing_loading.csv)
- [Original numerical preview note](wingtrade_results/NUMERICAL_PREVIEW.md)

These existing results are a historical numerical preview. The original note
identifies an independent Python calculation; its implementation is absent from
this checkout. MATLAB reproduction of this snapshot has not been verified.
The `.fig` and `.mat` files are retained with the CSVs and PNGs.

The preview's lowest-MTOW sampled passing battery-out point is:

| Quantity | Value |
|---|---:|
| Wing loading | 34 lb/ft² |
| MTOW | 2,401 lb |
| Wing area | 70.63 ft² |
| Span | 29.11 ft |
| Installed shaft power | 138.79 kW |
| Installed battery capacity | 169.33 kWh |

This is the best sampled point on the 18:2:46 grid, not a proven optimum.
Refine the grid near 30–36 lb/ft² before selecting a final W/S.

## Studies to use

| Study | Default range | Status / purpose |
|---|---|---|
| Wing loading | 12–48 lb/ft² in steps of 2, including current input W/S | Primary trade. Re-sizes aircraft at every W/S; two-cruise-prop coupled model with landing enforced. |
| Aspect ratio | 8, 10, 12, 14, 16, 18 plus input AR within bounds | Primary refinement. Adds 0.25 lb/ft² W/S samples near mass, battery, power and landing-passing minima. Fixed prop hardware and physical high-lift hubs isolate the wing change. |
| Parasite drag | CD0 multipliers 1.00, .95, .90, .85 | Supporting sensitivity. Preview best sampled MTOW drops from 2,401 to 2,240 lb. Assumed reductions require separate aerodynamic evidence. |
| Pack energy density | 300, 350, 400, 450 Wh/kg, each across W/S | Optional (`opt.do_battery = true`). Tests pack technology's effect on MTOW, battery mass and required capacity. Prior MATLAB exports are in trade_results. |
| Mission requirements | 150, 200, 250, 300 nm × 30, 45, 60 min reserve, each across W/S | Optional (`opt.do_mission = true`). Tests the weight/energy cost of range and reserve; includes the assigned 300 nm case noted in AEGAinputs. Prior MATLAB exports are in trade_results. |
| Battery-out climb target | 0%, 1%, 2%, 3% at selected baseline W/S | Optional (`opt.do_climb = true`). Preview changes MTOW by only 12.34 lb (0.51%); useful for explaining which constraint governs. The selected 2% climb screen remains active in every battery-out design even when this separate sensitivity is disabled. |

The range/reserve plot selects the lowest-MTOW passing sampled W/S for each
mission. The CSV preserves every sampled W/S and the governing mission.
The existing cross-country mission stays enforced, so reducing project range
can eventually stop reducing required battery energy.

The new pack sweep changes pack specific energy in the existing mass model.
It does not add pack-volume, cooling, aging or discharge-rate models. Its
values are sensitivity assumptions, not verified battery-product capability.

## Inputs and result saving

`AEGAinputs.m` supplies the current case: W/S 32 lb/ft², AR 13, 400 Wh/kg pack, 250 nm range,
45 min reserve, 120 kt cruise, 400 lb payload, 28 ft fuselage and 18/19 ft tail
arms. The saved comparisons below retain their original inputs. For one-off
experiments, override fields in a copy of the input struct or in the runner.

The current trade runner reloads AEGAinputs for mission, technology and airframe
values, then applies the explicit shared study layout and landing-enforcement
policy in AEGAstudysettings2035. Reference AR is 18; reference taper follows
the input file. The saved preview instead used `[1 1 1 1.30]`
diameters from root to tip and `prop_bank_frac = .90`, an outer-large-prop
layout. That differs from the current inboard-large graded baseline. Do not
attribute differences between a new run and the preview solely to the study
variable. `AEGAtrade_prop.m` is a geometry helper supporting both layouts;
it is not a diameter trade study.

Each runner execution creates `trade_results/<timestamp>/` beside the source,
preserving the old preview. Enabled studies export CSV tables, a
`wingtrade_results.mat` containing `study`, PNG plots and editable MATLAB FIG
plots. `trade2035` is the returned workspace result. Tables include pack
specific energy, range, reserve, convergence, screening status and drivers.
The saved struct includes exact inputs, options and execution provenance.

For a fast wing-loading-only run, set `opt.do_AR`, `opt.do_drag`,
`opt.do_battery`, `opt.do_mission` and `opt.do_climb` to `false`.
Direct calls to `AEGAwingtrades(msn,opt)` save only when `opt.output_dir`
is nonempty; `opt.save_plots` also requires `opt.doplot = true`.

## Aspect-ratio review and refinement (2026-10-05)

The user's latest plots match the MATLAB exports in
`trade_results/20261005_124616_226`. The saved input struct confirms the current
inboard-large prop layout, 400 Wh/kg pack, 250 nm plus 45 min reserve, and
15 kW/kg motor specific power. These are different inputs from the historical
independent preview above. Use this newer data for the following comparisons:

| AR | W/S at minimum sampled MTOW, lb/ft² | MTOW, lb | Pack, kWh | Installed shaft power, kW | Span, ft | Wing mass, lb | Landing distance, ft |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 9 | 28 | 2,544.7 | 193.86 | 153.18 | 28.60 | 148.43 | 1,324 |
| 10.5 | 32 | 2,433.5 | 179.10 | 135.56 | 28.26 | 143.56 | 1,425 |
| 12 | 32 | 2,371.4 | 165.35 | 133.13 | 29.82 | 153.25 | 1,452 |
| 13.5 | 34 | 2,336.6 | 157.11 | 141.87 | 30.46 | 159.55 | 1,510 |

The AR 13.5 point misses the 1,500 ft landing target by about 10 ft. It still
passes the package's enabled screens because `enforce_land` is false. The
refinement reports a separate landing-passing selection instead of silently
changing the enforcement flag or the field-length requirement.

From AR 12 to 13.5 at each AR's minimum sampled MTOW, gross weight falls
34.88 lb (1.47%), required pack capacity falls 8.23 kWh (4.98%), modeled wing
mass rises 6.30 lb and installed shaft power rises 8.74 kW. These are complete
design comparisons at different W/S, not isolated aerodynamic comparisons.
At the same W/S = 32, AR 13.5 saves 28.52 lb MTOW but adds 12.39 lb wing mass.
Higher AR is not beneficial everywhere: at W/S = 18 it increases MTOW.

For AR 12, W/S = 30 is also worth retaining: MTOW 2,377.18 lb, installed shaft
power 126.08 kW, pack 164.04 kWh and predicted landing distance 1,415 ft.
Compared with the minimum-weight W/S = 32 sample, that is only 5.75 lb heavier
but requires 7.05 kW less installed power. The objectives have different minima.

The drag sensitivity is also useful. The best sampled design with a hypothetical
10% CD0 reduction is 2,265.7 lb / 150.79 kWh versus 2,371.4 lb / 165.35 kWh
at baseline drag. It quantifies the value of a drag target; it does not establish
that a particular fairing, winglet or fuselage change achieves it.

NASA confirms that X-57's redesigned Mod III/IV wing had AR 15. Its propulsion
configuration used two wingtip cruise propellers and twelve high-lift propellers
that folded in cruise, while this model operates all eight props in cruise.
That makes AR 15 a useful comparison point, not a transferable optimum.
[NASA flight-performance estimates](https://ntrs.nasa.gov/api/citations/20240010807/downloads/x57_performance_manuscript-v4.pdf)
describe the configuration and note that the project ended before Mod II/III/IV
flight testing. NASA also performed detailed structural analysis and ground
proof tests of the composite wing.
[NASA structural requirements and testing](https://ntrs.nasa.gov/api/citations/20240006690/downloads/20240006690FINAL.pdf)

The refined runner brackets AR 15 with AR 13.5, 16.5 and 18, preserving lower-AR
comparisons. If the best result remains at AR 18 or a W/S endpoint, report it
as the best sampled boundary case and expand the appropriate range before
claiming an optimum. With no specified wingspan or propeller limit, those
dimensions are reported rather than constrained.

The AR sweep re-packs propellers as span changes, changing disk area, blade
mass and ideal propulsive efficiency. It therefore measures the complete
configuration. New outputs include smallest/largest prop diameter, total disk
area, prop and tail mass, non-battery mass, MAC, clean stall speed and motor
specific power. `07_AR_design_summary.csv` reports four selections per AR:
minimum MTOW, minimum MTOW plus landing check, minimum battery capacity and
minimum installed power. `08_AR_design_choices.png/.fig` plots wing mass,
span, prop size, landing distance, pack capacity and gross weight, marking
the minimum-weight points that miss the landing-distance check.

The mass model includes an AR-dependent FLOPS wing-weight penalty, but does
not size spar stiffness, twist, buckling, gust response, flutter, prop-mount
loads, root attachment or a detailed high-AR wing box. Oswald efficiency and
wing/tail friction/form factors remain fixed. A structural and propeller
integration review should follow the extended sweep before adopting a higher
AR. A useful next controlled comparison is to hold prop hardware/disk area
fixed; that would separate the wing change from automatic prop resizing.

This refinement changes the active trade grids and reporting, not the baseline
AR in AEGAinputs. Standalone MATLAB Code Analyzer checks passed. Refined MATLAB
results including AR 15–18 and finer W/S samples are saved in
`trade_results/20261006_125740_775`. These use the earlier all-eight-cruise
architecture. For the current preferred prop configuration, use the coupled
study and the midterm curation above.

## Active files

| File(s) | Role |
|---|---|
| `run_currenttrades2035.m`, `AEGAstudysettings2035.m`, `AEGAstudycase2035.m` | Current three-study runner; shared bounds/layout and live mission/technology inputs |
| `check_currenttrades2035.m`, `AEGAexportreview2035.m`, `CURRENT_TRADE_REVIEW.md` | Input propagation and physical checks; refreshed main presentation assets and review |
| `AEGAinputs.m` | Shared design assumptions |
| `Hub.m`, `AEGAsize.m` | Original baseline sizing and constraint plot |
| `AEGAweight.m`, `AEGAmission.m`, `AEGAconstraint.m` | Common mass, mission and normal-performance models |
| `AEGAprop.m`, `blow_wind.m` | Baseline geometry and standalone blown-wing calculation |
| `run_wingtrades2035.m`, `AEGAwingtrades.m` | Active trade runner, sweeps, plots and export |
| `run_cruiseproptrades2035.m`, `AEGAcruiseproptrades2035.m` | Cruise-prop diameter, constraint-sized high-lift props, MTOW/power/thrust split and quiet constraint checks |
| `check_cruiseproptrades2035.m`, `CRUISE_PROP_TRADE.md` | Cruise-prop validation, controls and interpretation |
| `run_telescopingtrades2035.m`, `AEGAtelescopingtrades.m` | Maximum AR 18; variable retractable span; retracted cruise and extended climb/landing; MTOW/range comparisons |
| `check_telescopingtrades2035.m`, `TELESCOPING_TRADE.md` | Telescoping physics checks and interpretation |
| `AEGAtrade_size.m`, `AEGAtrade_prop.m`, `AEGAbatteryout.m` | Prescribed-W/S sizing, trade-layout geometry and mirrored-bank failure screening |
| `check_wingtrades2035.m` | Coupled model physics and export checks |
| `prepare_midterm_review2035.m`, `MIDTERM_TRADE_REVIEW.md`, `midterm_review/` | Midterm review, checked presentation curation and matched battery/range sensitivity |
| `AEGAplot_climb.m` | Explains a saved climb sensitivity without re-running sizing |
| `wingtrade_results/` | Historical saved results and their original preview note |
| `archive/` | Retired propeller sweeps, legacy prop-family failure study, duplicate check and unused helper |

The archived files retain their original contents with `.m.txt` extensions so
MATLAB cannot accidentally execute them. See [archive/README.md](archive/README.md).

## Model boundaries and verification

### Propeller disk area and wingtip interaction (2026-10-06)

The user-reported `Hub` run at W/S 32 and AR 13 converged in four iterations:
MTOW 2,349.7 lb, wing area 73.4285 ft², span 30.8961 ft, total disk area
58.0697 ft², L/D 17.0268 and cruise battery power 48.4908 kW.
`Adisc` is the sum of all eight disks, not one propeller or one wing.
The equivalent diameter `Dprop = 3.0401 ft` satisfies
`Adisc = 8*pi*Dprop^2/4`. Reconstructing the current packing rule gives
root-to-tip diameters about `[3.4205 3.1574 2.8943 2.6311] ft` on each wing.
The largest propeller is currently inboard.

The original `AEGAprop` rejects ratios increasing toward the tip; the trade
helper supports them. Both currently keep the entire outer disk within the
wing semispan. The current outer axis is at about 90.4% semispan. Simply
changing to `[1 1 1 1.3]` at the same wing geometry gives 58.3659 ft² total
area and a 3.6591-ft outer prop, but moves its axis to 87.1% semispan.
A true wingtip-propeller study therefore needs explicit hub placement and
allowance for the outer disk to extend beyond the aerodynamic wingtip.

[NASA's X-57 overview](https://www.nasa.gov/centers-and-facilities/armstrong/x-57-maxwell/)
lists two 5-ft cruise props and twelve 1.9-ft high-lift props. Their geometric
disk areas are approximately 39.3 ft² for the cruise pair and 73.3 ft² for
all fourteen. The high-lift props stow in cruise, so cruise-active area must
be distinguished from total installed disk area.

[NASA's 2017 aero-propulsive comparison, section IV.B](https://ntrs.nasa.gov/api/citations/20170001218/downloads/20170001218.pdf)
reports reductions of 2–18% of **wing drag** among its computational models,
including 7% in the design-order calculation. These are not percentages of
whole-aircraft drag or a universal function of propeller diameter.
[NASA's 2025 cruise-power analysis](https://ntrs.nasa.gov/citations/20250001494)
confirms the dependence on thrust, airspeed and rotation opposing the wingtip
vortex. These findings support an interaction sensitivity, not an automatic
credit for a larger outboard diameter.

For the reported aircraft, induced drag is about 39.7% of total cruise drag.
A useful preliminary sensitivity is
`CD = CD0 + (1 - f_tip)*CL^2/(pi*AR*e_osw)`, with `f_tip` sampled at
0, .05, .10 and .15. These are analyst-selected hypotheses, not NASA-derived
predictions for this aircraft. At fixed aircraft geometry, weight and speed,
using the current disk-efficiency model:

| Assumed induced-drag reduction | Total drag reduction | L/D | Cruise battery power, kW |
|---:|---:|---:|---:|
| 0% | 0% | 17.03 | 48.49 |
| 5% | 1.98% | 17.37 | 47.52 |
| 10% | 3.97% | 17.73 | 46.54 |
| 15% | 5.95% | 18.10 | 45.57 |

These calculations do not re-close MTOW, resize props or predict takeoff
power. Preserve the zero-credit baseline. A future coupled study should
define tip diameter, hub position, rotation and tip thrust share, distinguish
all-props cruise from two-tip-props cruise, and recheck the loss of a tip
propeller or its battery bank. Any swirl benefit must be counted once,
through drag or installed propulsion efficiency. The existing larger-disk
efficiency benefit alone does not model swirl recovery. No wingtip credit
or architecture change has been activated in the sizing inputs.

The selected design direction is **two wingtip props in cruise**, with the
six inboard high-lift props stowed. Keep separate installed and cruise-active
disk areas. As provisional diameter cases, a pair of 4, 4.5 and 5 ft props
has 25.13, 31.81 and 39.27 ft² of cruise disk area, respectively.
Using the same fixed aircraft and current ideal-disk/profile-loss model:

| Tip-prop diameter, ft | Cruise disk area, ft² | Cruise battery kW, no interaction credit | Cruise battery kW, assumed 10% induced-drag reduction |
|---:|---:|---:|---:|
| 4.0 | 25.13 | 49.34 | 47.32 |
| 4.5 | 31.81 | 49.03 | 47.04 |
| 5.0 | 39.27 | 48.80 | 46.83 |

The existing all-eight-props result is 48.49 kW. Reducing cruise-active area
alone slightly increases power in this model; the wingtip interaction can
offset that penalty. This comparison leaves airframe CD0, aircraft mass,
profile efficiency, folding hardware and nacelle drag unchanged. It is not
a final architecture sizing result or a selected propeller diameter.
Before implementing this architecture, the sizing and failure models need
separate cruise/high-lift geometry and power allocation, folded-prop drag and
mass assumptions, and screening with the tip cruise props unavailable.

### Landing check and reverse thrust

The landing model already includes reverse thrust: the baseline
`reverse_TW = .08` credits constant reverse force equal to 8% of aircraft
weight immediately after touchdown, together with wheel braking and drag.
It is an assumed capability, not a prediction from propeller pitch, motor
rating or available battery power. Deployment delay and a speed-dependent
reverse-thrust schedule are not included.

The AR plot now labels its markers **Above target at assumed reverse thrust**
and states the reverse assumption in its title. These are advisory whenever
`enforce_land = false`; the primary minimum-MTOW selection remains available.
The landing-passing selection provides an alternative under the same stated
assumptions. New CSV columns `LandingReverseTW`, `LandingAir_ft` and
`LandingGround_ft` expose the reverse level and distance breakdown.

At the baseline 3-degree approach, the 50-ft-obstacle airborne segment alone
is about 954 ft, leaving about 546 ft of ground roll within the 1,500-ft
target. Reverse thrust shortens the ground segment in this model. Increasing
it cannot shorten the modeled airborne segment.

The newer refined run `trade_results/20261006_125740_775` reports minimum-MTOW
points at AR 13.5 / W/S 35 with 1,530 ft landing distance, AR 15 / W/S 37.5
with 1,597 ft, and AR 18 / W/S 42 with 1,715 ft. These predictions already
include the 8%-of-weight reverse assumption. Keep these designs as candidates;
the useful next sensitivity is reverse-force level and deployment delay at
fixed candidate geometry, followed by a propeller-based reverse model. Do not
credit an additional improvement without changing and identifying the assumption.

Each battery bank feeds a mirrored pair `[L1 R1]` through `[L4 R4]`, numbered
root to tip. Four separate bank failures are screened with surviving motor
ratings retained, disk-area allocation, no crossfeed and no overload. Default
targets are 60 kt powered lift capacity, 78 kt / 3° approach and 2% climb in
takeoff-flap and landing-flap go-around configurations, with existing 2%
margins. These are project screening assumptions. Trim, control authority,
transients and post-failure battery endurance remain outside this model.

The original Hub baseline uses all eight props in cruise; the current three
study runners use two cruise props. No wingtip swirl credit is added.
Failed-prop incremental disk drag is assumed zero and takeoff
flap CD increment is .03. Landing distance and clean stall are reported checks
unless their enforcement flags are enabled; the current baseline has both
flags disabled, while the current study policy explicitly enforces landing.
Keep those limits visible when
interpreting a passing screening result. Failed samples remain in the tables
and appear as plot gaps.

On 2026-10-05, MATLAB R2026a's standalone Code Analyzer checked the updated
study files. Full MATLAB startup failed with `System Error: File system
inconsistency`; execution was unverified at that historical point. Later
checked runs and the current three-study review supersede that status.
The earlier export options were unused; this review connected
them to actual CSV/MAT/PNG/FIG saving. Run the MATLAB checks before relying on
new results. The old references to missing `independent-check/` and
`TRADE_STUDY_PLAN.md` were removed from this index.
