**Workflow update (October 11):** Use [the three-study guide](THREE_MAIN_TRADES.md) and [the current commands](../README.md). Numerical examples below are dated snapshots and may use older inputs, AR18 or instantaneous reverse credit. The active concept is AR15.5, W/S27 with a conditional 6% ground-reverse target; see [the October12 configuration](REVERSE_CONFIGURATION.md). Adaptive full-span AR remains18. Old runners and standalone check commands are archived/private; use `AEGAtrades('check')`.

# Coupled wing retraction, throttle and blown lift

**Current inputs:** The polar-calibrated, no-reverse landing baseline and geometry handoff are documented in [INPUT_ASSUMPTIONS.md](INPUT_ASSUMPTIONS.md). Historical numerical sections below retain their original assumptions.

**October 11:** [current three-study results](../CURRENT_TRADE_REVIEW.md) use
expanded bounds, common 3.2-ft-envelope hub spacing and enforced landing.
The phase physics described here remains in use; the October 8 numerical
snapshot below retains its original geometry and enforcement settings.

Run `AEGAtrades('wings')` in MATLAB. The current runner uses the
coupled phase model for both aircraft and a derived adaptive stroke capability.
The earlier results in OPTIMIZED_WING_COMPARISON.md retain their original
accounting and should not be compared as if only the mechanism changed.

## Checked results

The completed run and selected-design re-evaluation are in
[`optimized_wings_20261007_190112_237`](../trade_results/optimized_wings_20261007_190112_237/02_best_designs.csv).
The run finished on 2026-10-08; its directory retains the start timestamp.
The coupled checks and the three existing MATLAB check suites passed.
Both the static phase plots and the interactive explorer were inspected;
the explorer's phase/speed interactions and narrow layout were checked in a browser.

| Shared mission | Fixed MTOW (lb) | Adaptive MTOW (lb) | Adaptive penalty | Mechanism (lb) |
|---|---:|---:|---:|---:|
| 250 nm at 120 knots + 45-minute reserve | 2,245.36 | 2,260.60 | 15.23 lb / 0.678% | 10.36 |
| 50 nm at 100, 200 nm at 160 + 45 minutes at 120 | 2,592.90 | 2,614.54 | 21.63 lb / 0.834% | 11.00 |

All selected route/reserve phases still choose full span. The current adaptive
wing has AR18, .20 taper, 68.48 ft2 full area and 35.11 ft full span. Its 20%
capability permits 28.09 ft retracted span (3.51 ft stroke per side). At 120
knots the clean lift-only area floor is 48.42 ft2, but induced drag favors more
span. The fixed prop layout also limits stroke to 24.52% at this geometry;
the nominal 40% upper bound is not physically reachable on this candidate.
In the faster mission, fixed-prop clearance limits capability to 30.45%.

For the current adaptive wing, the checked schedule is:

| Phase | High-lift motor throttle | Cruise motor throttle | CLmax unblown -> at actual power |
|---|---:|---:|---:|
| Takeoff | 100% | 100% | 2.10 -> 3.065 |
| Initial climb | 58.4% | 58.4% | 2.10 -> 2.482 |
| Clean climb | 54.6% | 54.6% | 1.60 -> 1.729 |
| Route / reserve | 0% | 60.7% | 1.60 -> 1.622 (clean 1.60 credited) |
| Idle descent | 0% | 0% | 1.60 -> 1.60 |
| Approach | 22.9% | 22.9% | 2.534 -> 2.742 |
| Landing / flare proxy | 34.6% | 34.6% | 2.534 -> 2.970 |
| Go-around | 76.4% | 76.4% | 2.534 -> 3.178 |

The current fixed/adaptive selections give modeled landing distances of
1,522/1,519 ft and miss the optional 1,500-ft check. The faster fixed/adaptive
selections give 1,507/1,497 ft. Landing enforcement is still disabled; the
separate landing-passing sampled table retains alternatives. Both families
reach the .20 taper boundary and fixed AR approaches the AR18 ceiling.
These are bounded conceptual minima, not validated aerodynamic optima.

Explicit phase/distance accounting also changes the mission energy comparison:
project energy governs all four selections. Required usable energy is
125.77/126.37 kWh for the current fixed/adaptive pair and 161.51/162.42 kWh for
the mixed pair. The mixed result should not be read as a 20%-mechanism saving
relative to the earlier model, which used different three-stop and reserve
accounting. The fixed/adaptive pairs within this run share the same accounting.

Partial retraction first appears at approximately 175-180 knots in the
selected-aircraft speed sweep. These points exceed the selected cruise-motor
ratings (and some exceed the current mission's model-speed ceiling) and are
flagged. At 200 knots the modeled reduction from full-span drag is only
0.39-0.49% for these selected geometries; that sweep is not an accepted
operating schedule or an independently sized 200-knot aircraft.

## Retraction and wing sizing

The fixed wing still optimizes one W/S, AR and taper for the whole mission.
The adaptive wing optimizes full-span W/S and taper, with full-span AR18.
Its mechanism stroke is now calculated inside every mass iteration, rather
than being a freely optimized third variable that can collapse to 2.5%.

The requested substantial capability is **at least 20% of full span**.
The analyst upper bound is 40%, subject to more restrictive physical limits:

- At the fastest route/reserve speed, minimum clean cruise area is
  `S_min = W / (q * CL_limit)`, with `CL_limit = CLmax_clean / 1.2^2`.
  Inverting the nested-trapezoid area relation gives a maximum allowable
  span reduction. Slower phases can deploy more wing.
- The fixed core must fit all three high-lift props per wing plus the
  stationary cruise prop at its end, including the common .15-ft gap.
- The sliding panel and its overlap must fit inside the stationary core.
- Retracted area must exceed the fuselage-covered wing area.

Within that stroke ceiling, the mechanism's desired maximum stroke minimizes
drag at the fastest mission speed. Installed capability is the larger of this
drag-selected stroke and the requested 20% minimum. If 20% cannot fit, that
candidate fails; the model does not silently reduce the requested capability.
Both the drag-selected value and each physical ceiling are exported.

**Capability is different from commanded retraction.** At each cruise/reserve
speed, the existing inner optimizer independently minimizes total drag between
the fully retracted and fully extended states, while meeting the clean lift
margin. A larger mechanism does not force cruise to retract when full span
has lower total drag. The minimum-area wing is a feasibility limit, not an
automatic command. Induced drag, visible wing friction and joint drag are
counted together. Full wing area is selected by the aircraft MTOW objective
and the common flight-phase constraints, not by assuming low-speed blowing
provides free wing-area reduction.

Cruise motors stay at the fixed core ends. High-lift motor stations remain
3.55, 6.50 and 9.45 ft from centerline. Flaps are confined to the fixed core;
the model does not put a flap linkage through the nested panels.

## Flight-phase schedule

`08_all_flight_phases.csv` reports takeoff, initial climb, clean climb, every
route leg, reserve, idle descent, approach, landing/flare and go-around.
It includes actual shaft/battery power, high-lift and cruise-group throttle,
wing state, lift capacity, lift requirement, margins, thrust and energy.

**Throttle means required shaft power divided by assigned shaft rating**.
It is not a throttle-lever angle, RPM schedule or measured propeller map.
Low-speed phases use all eight motors at a common fraction of their existing
disk-area-proportional ratings. Cruise/reserve use only the two large motors;
the six high-lift motors have zero power. Thus 60% cruise-motor throttle
does not mean 60% of the total eight-motor installed rating.

The current analyst phase assumptions are:

| Phase | Speed / condition | Lift-speed margin | Power treatment |
|---|---|---|---|
| Takeoff | 1.1 x 60 kt, sea level | 1.1 | Full installed shaft power; accelerating |
| Initial climb | 1.3 x 60 kt, first minute at 730 ft/min | 1.2 | Thrust and lift requirement |
| Clean climb | 1.3 x clean stall, remaining climb to 5,000 ft at 730 ft/min | 1.2 | Thrust and lift requirement |
| Route / reserve | Shared mission speeds at 5,000 ft | 1.2 clean | Two motors, drag-selected span |
| Descent | Reserve speed, idle, natural clean glide | 1.2 | Zero shaft power |
| Approach | 1.3 x 60 kt on the specified 3-degree glide | 1.3 | Thrust-balanced descent; lift checked at that power |
| Landing / flare | 1.15 x 60 kt, 10-second low-speed power proxy | 1.15 | Transient estimate, excluded from steady sizing screen |
| Go-around | 1.3 x 60 kt, landing flaps, 730 ft/min | 1.2 | Thrust and lift requirement; contingency, not nominal energy |

Cruise is at the specified cruise density; other powered phases use sea-level
density as a conceptual approximation. Climb duration uses the 5,000-ft target
and 730-ft/min climb rate. This is not an altitude-resolved flight simulation.
Descent finishes at a nominal 500-ft approach height; the one-minute approach
and ten-second flare are duration estimates, not a fully integrated trajectory.

## Blown lift at actual power

Each disk solves `P * profile_eff = T * (V + vi)` and
`T = 2 * rho * A_disk * vi * (V + vi)`. The far-wake speed is `V + 2*vi`.
Contracted wake footprints are integrated over the actual visible tapered
wing and the stationary flap region. Their local dynamic-pressure increase
raises available CLmax, with the existing CLmax cap of 4.0.

The reported increase is **lift capacity at scheduled power**. Operating lift
still balances aircraft weight; the aircraft is not credited with a perpetual
upward force equal to the CLmax increase. Cruise prop blowing is reported as
a diagnostic, while cruise sizing retains clean CLmax and gives no high-lift
power or wingtip-drag credit.

For a steady approach, the model first solves the shaft power needed to balance
drag and weight's downhill component. It then checks lift capacity at that
power. If the power needed for lift creates excessive forward thrust, the
candidate fails the stabilized-approach screen. It does not claim an approach
with an unexplained brake or drag device. Positive climb thrust surplus can
represent a climb rate above the requested minimum. Takeoff acceleration and
flare dynamics remain simplified.

This coupling follows the engineering concern in NASA's
[X-57 high-lift propeller control-schedule study](https://ntrs.nasa.gov/citations/20205010303):
high-lift thrust and the ability to maintain a stabilized approach must be
considered together. NASA's
[X-57 computational high-lift study](https://ntrs.nasa.gov/citations/20230004198)
supports modeling powered lift and aero-propulsive interaction, but its
numerical gains are not copied onto this aircraft. Our actuator-disk and
strip-integration model needs airfoil/propeller maps or higher-fidelity
validation before treating its lift increase as established performance.

## Energy and mass closure

The route's specified total distance now includes climb, descent and approach
travel. Their distances are deducted from cruise legs, preserving the same
250-nm route and the full 45-minute reserve. Go-around is reported but not
added to nominal energy. Explicit phase energy replaces the original blanket
4% non-cruise allowance, with a separately labeled 2% auxiliary/uncertainty
allowance applied to the phase energy sum. This allowance is an assumption.

The three-stop, 150-nm mission repeats the low-speed phases at each stop,
uses peak-profile speed for its cruise portions, and uses the shared profile's
reserve speed. Required battery energy is the larger of project and three-stop
mission energy. Wing, tails, installed power, battery, mechanism and MTOW all
close together. If operating phases need a larger rating, power and weight
are resized before accepting the candidate.

Landing-field and separate 59-KCAS clean-stall enforcement retain the project
settings (currently disabled). Their numerical results remain visible. The
existing battery-out model remains a separate instantaneous screen; it does
not prove post-failure battery energy accessibility or flight controllability.

## Controls, files and validation

- `opt.retraction_bounds = [.20 .40]`: requested capability and analyst ceiling.
- `opt.retraction_policy = 'lift-drag'`: derived capability; `'manual'` restores
  the earlier independent retractable-fraction search.
- `opt.coupled_flight_phases = true`: actual-throttle phase constraints and energy.
  `false` retains the original mission accounting for historical comparisons.
- `opt.phase_energy_margin = .02`: explicit allowance on the phase energy sum.
- `AEGAretractionlimits2035.m`: area, packing, overlap and drag capacity rule.
- `AEGAblownstate2035.m`: actual-power slipstream and visible-wing lift integration.
- `AEGAflightphases2035.m`: phase operating schedule and consistency screens.
- `AEGAcoupledmission2035.m`: distance, phase energy and three-stop accounting.
- `check_coupledflight2035(study)`: independent power/thrust balances, area,
  actual throttle, clean cruise margin, route distance and energy closure.
- `refresh_coupledflight_exports(folder)`: re-evaluates selected geometries,
  requires unchanged MTOW/energy, checks them, and exports phase/visual data.
- `08_all_flight_phases.csv`: actual phase power, throttle, lift capacity and screens.
- `09_throttle_and_blown_lift.png/.fig`: inspected phase plots.
- `10_visual_preview.json`: checked data behind the wing explorer.

The original sizing default remains unchanged: the new phase model is opt-in
in `AEGAsize` and enabled in the revised optimization runner. Mechanism
weights and joint drag retain the optimistic targets in TELESCOPING_TRADE.md.
Rotor RPM/pitch, transition loads, jams, airfoil polars, control authority,
stiffness, flutter, motor thermal limits and altitude-dependent propeller
performance remain unresolved. A numerical best point is not a flight-ready
design or a demonstrated global optimum.
