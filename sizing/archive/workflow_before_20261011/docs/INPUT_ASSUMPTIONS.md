# Input and aerodynamic assumption review — October 11, 2026

**Reverse option added:** [the quantified reverse study](../REVERSE_THRUST_REVIEW.md) now models ground-only reversing pitch, 3/5/8% thrust targets, delay/ramp, static power screening, added hub/control weight and per-landing energy. The ordinary trainer reference stays at zero credit; selecting `AEGAreversecase2035` enables the conditional option. The earlier instantaneous .08 credit is retained only in the explicit historical fixture.

Use [the geometry handoff](../GEOMETRY_HANDOFF.md) for the next aerodynamic model, [the latest trade review](../CURRENT_TRADE_REVIEW.md) for study selections, and [the quantified sensitivity table](../input_review/assumption_sensitivity.csv) for uncertain inputs. Run `run_inputreview2035` to regenerate the reference and sensitivities; run `run_currenttrades2035` for the complete three-study search.

## Changes made

| Input or behavior | Previous | Revised | Reason |
|---|---|---|---|
| Clean drag | Uncalibrated component buildup | Same geometry-dependent buildup × 0.902173 | Matches the supplied whole-polar fit at its reference geometry |
| Effective span efficiency | .80 | .762593 | Fitted slope and source AR13.0083; extrapolation to other AR remains a modeling assumption |
| Reverse thrust | .08 × weight, immediate | Zero baseline | No prop pitch, RPM, power or transition model establishes the credit |
| Landing enforcement in shared inputs | Disabled | Enabled | Consistent with the team's 1500-ft field target and active studies |
| Working reference | W/S32, AR13 | W/S24, AR18, taper .35 | AR18 follows the prior bounded trades; W/S24 provides some modeled landing margin without reverse |
| Sweep definition | Ambiguous comments | 2° quarter chord | FLOPS definition used by the weight equations; handoff also gives equivalent leading-edge sweep |
| Wing mass target | Hidden in study defaults | Explicit `msn.wing_mass_factor = .80` | Keep the requested optimistic 2035 assumption visible and test 1.0 |
| Historical tests | Used changing live defaults | Explicit dated input fixture | Preserves the original 2349.7-lb regression while testing current inputs separately |

The original inputs are retained in [the dated archive](../archive/inputs_before_polar_20261011/AEGAinputs.m.txt). The latest fixed-wing reference remains two large 4.5-ft cruise props and six 2.8-ft high-lift props at the common physical hubs. This is a controlled comparison geometry, not the prop sweep's minimum-MTOW selection. A 3.0-ft / 2.0-ft alternative is included in the sensitivity table.

## What the teammate's file establishes

The [unaltered source](../data/aerodynamics/Panel_drag_polar.csv) contains five histories, a solver polar, load tables, and a separately prepared summary in cells J6:Q11. Only its five summary points are fitted. The summary's `Cdtot = Cd0 + Cdiw`, and its listed L/D matches `Clwtot / Cdtot` within rounding. Using `Cl` from the adjacent near-field column would mix coefficient conventions.

At Sref = 73.4 ft² and Bref = 30.9 ft, AR = 13.0083. The two-term least-squares fit is:

**CD = 0.02434295 + 0.03208755 CL²**, using summary CLwtot, over CL = .2996–1.150 and alpha = 0–8°. R² = .99864. The effective fitted e is .76259. This is a reduced whole-polar parameter, not an independently measured inviscid span efficiency.

The summary lists Cd0 = .0202, but its wake-drag points contain an offset. Using .0202 with the fitted slope would underpredict the supplied total drag. The fit intercept retains that offset without adding it twice. Neither the raw solver CDo near .007 nor the hand-entered .0202 is added to the fitted intercept. The uncalibrated reference buildup was CD0 = .02698258. The resulting scale is applied once to the geometry-dependent parasite components and to the exposed-wing friction removed during retraction. At other AR, the lift-dependent term follows `1/(pi*AR*e)`; only a new geometry-specific polar can validate that transfer.

![Supplied polar and fit](../input_review/polar_fit.png)

**Provisional scope:** component coverage of .0202 and tail trim were not confirmed. The whole-aircraft interpretation is an explicit working assumption, not new evidence. The source has Mach .001, ReCref 3.5 million, Cref 2.35, and Vinf 100 with unspecified dimensional units. These do not establish a matched 120-KTAS/5000-ft analysis. The updated handoff supplies appropriate reference dimensions, Mach and Reynolds number. No stall rollover appears in the five points; StallFactor is 1 throughout. Therefore this file does not justify changing clean CLmax, flap gains or blown CLmax. The difference between near-field and wake results also warrants mesh/wake convergence checks before treating the fit as high-confidence data.

NASA describes [VSPAERO as a potential-flow tool](https://www.nasa.gov/reference/openvsp-vspaero-basics/) and provides a separate [Parasite Drag tool](https://www.nasa.gov/reference/openvsp-parasite-drag-tool/) for component drag buildup. Request both outputs, with the same reference area and explicit prop-on/off conditions.

## Assumptions retained and how to use them

| Item | Working value | Assessment and next evidence |
|---|---|---|
| Mission | 250 nm + 45 minutes at 120 KTAS; 400 lb payload | Team study, not the original 300-nm assignment; 300-nm sensitivity is included |
| Battery | 400 Wh/kg at pack level, .90 usable | Optimistic 2035 target. Pack housing, cooling and safety must be included in the claimed pack metric. 350/450 sensitivities included; ageing, temperature and end-of-life retention need a separate requirement |
| Motor/inverter | 15/14 kW/kg, .95/.97 efficiency | Project targets. Motor mass metric is not a complete installed propulsion system; no RPM/torque/thermal-continuous map yet. 10-kW/kg motor sensitivity included |
| Wing mass | .80 × already-composite FLOPS estimate | Additional 20% reduction is optimistic and unvalidated; 1.0 sensitivity included. AR18 still needs loads, stiffness and flutter work |
| Clean CLmax | 1.6 | Airfoil/finite-wing target, not established by this polar. At 1.4 the reference misses the landing screen; a high-priority aero task |
| Flaps | Section increment1.4, sweep factor .92, chord32%, span80%, deflection40° | Preliminary flap model, not measured. The .92 factor is a retained aggregate derate; at 2° sweep it should not be presented as a pure sweep correction. A 1.2 lift-increment sensitivity nearly exhausts landing margin |
| Flap drag | Factor1.10 in the plate-like estimate | Strong interaction with approach power, blowing and ground roll. Lower .8 factor tested; obtain actual flap polar |
| Blown CLmax cap | 4.0 | Numerical ceiling, not demonstrated capability. Actual-power phase checks remain enabled |
| Landing | 3° approach, touchdown1.15Vs, dry braking .35, ground CL = .5 unblown landing CLmax | Simplified field estimate; no flare trajectory, brake delay, wet runway or reverse credit. Passing the model does not establish flight-test field performance |
| Fuselage and tails | 28 × 4 × 4.167 ft; arms18/19 ft; Vh .60, Vv .040; T-tail | Retained to avoid inventing a packaging redesign from a drag table. Need station layout, CG, tail trim/control sizing and deep-stall review |
| Buried area / miscellaneous wetted area | 6.78 / 48.4 ft² | Legacy aggregate estimates. The drag calibration constrains their combined reference effect, not each component; replace from the new geometric model |
| Nacelles, hubs, installation, harness | 120 lb aggregate | Not a parts list. 160-lb sensitivity included; avoid double-counting wiring in the electrical weight correlation |
| Cooling | .06 kg/kW shaft rating | Optimistic aggregate; .12 sensitivity included. Need loss heat, ambient temperature, radiator/duct mass and drag |
| Blade mass and ratings | Five blades, empirical D³ mass; disk-area-proportional motor ratings | Can materially bias the prop optimum. Sweep results are candidate regions until real blade, hub, pitch, torque and RPM data exist |
| Failed prop drag | Zero, ideal fold/feather | Explicit assumption; CD .02 sensitivity included. Bank failures are instantaneous performance screens, not proof of energy accessibility, controllability or redundancy |
| Margins | 5% empty-weight margin, 2% coupled-phase energy allowance | Conceptual allowances; neither substitutes for missing subsystems or design reserves |

The [NASA battery-development roadmap](https://ntrs.nasa.gov/api/citations/20180001539/downloads/20180001539.pdf) distinguishes cell from pack specific energy and discusses 400–500 Wh/kg pack development; it does not guarantee a certified 2035 pack. [NASA HEMM](https://www.nasa.gov/eap-technology/electric-machines/hemm/) is a 1.4-MW technology effort, so its high specific-power targets do not validate our small motors. The [FLOPS weight method, Eq.14](https://ntrs.nasa.gov/api/citations/20170005851/downloads/20170005851.pdf) explicitly defines SWEEP as quarter-chord sweep.

## Quantified priorities at the reference W/S24 and AR18

Each case re-closes mass and geometry at the same prescribed W/S. Changes below are one at a time, not additive and not a new global optimization.

- Reference: **2303.9 lb**, **96.00 ft²**, **41.57 ft span**; modeled landing **1462 ft** without reverse.
- Battery350 Wh/kg: **+216.5 lb**. Assigned300 nm: **+215.3 lb**. These deserve more presentation attention than tiny prop-diameter differences.
- Remove the additional20% wing reduction: **+102.2 lb**. Parasite drag+10%: **+107.0 lb**.
- Increase installation hardware120→160 lb: **+79.3 lb** after resizing. Double cooling allowance: **+42.3 lb**.
- Clean CLmax1.4: landing becomes **1511 ft**, failing the1500-ft screen even though weight barely changes. Feasibility matters as much as MTOW.
- Retaining the old uncalibrated drag at this same reference policy adds **95.6 lb**. That comparison isolates the aerodynamic update, not the independent change to landing assumptions.

The rounded reference is convenient for the teammate's next aerodynamic iteration. The optimizer may find lighter points close to the landing boundary; do not replace a margin with numerical precision.
