# Trade-study review for Tuesday, October 13, 2026

**Current inputs:** The polar-calibrated, no-reverse landing baseline and geometry handoff are documented in [INPUT_ASSUMPTIONS.md](INPUT_ASSUMPTIONS.md). Historical numerical sections below retain their original assumptions.

**October 11 update:** the three selected main studies have been aligned with
current inputs and expanded search bounds. Use
[the updated review and figures](../CURRENT_TRADE_REVIEW.md) for wing loading/AR,
fixed versus telescoping and prop sizing. The results below retain the
October 10 review and its earlier layouts/search domains. The battery/range
comparison remains a separate historical backup; do not mix absolute weights
between it and the new common hub layout.

Lead with wing loading/aspect ratio, battery/range feasibility, and the
fixed-versus-telescoping concept decision. The new cruise-prop/high-lift sizing
study is also a useful main slide because it connects the chosen architecture
to a governing failure constraint. Use throttle and powered lift as
supporting operating evidence. Present a decision and its consequence, rather
than every sweep that has been run.

## Which studies are useful

| Priority | Study | Decision it supports | Treatment |
|---|---|---|---|
| 1 | Wing loading and aspect ratio | How much wing to carry; induced drag versus structure, span, power and field length | Main slide. Use `midterm_review/01_wing_loading_and_AR.png`. Include rejected cases and the landing constraint. |
| 2 | Pack specific energy and 250 versus assigned 300 nm | Whether the mission closes under optimistic and less optimistic technology | Main slide. The refreshed `02_battery_and_range.png` uses the current propulsion and flight-phase model. |
| 3 | Independently optimized fixed versus telescoping wing | Whether variable span earns its mechanism mass for the intended mission | Main concept-selection slide. An unfavorable result is still useful engineering evidence. |
| 4 | Cruise diameter versus high-lift prop downsizing | How much the cruise props can substitute for small-prop capacity, and what happens when both cruise props are lost | New completed study. Use `midterm_review/07_cruise_prop_trade.png`; the primary selections retain battery-out screens. |
| Supporting | Throttle and blown lift by phase | Whether the props deliver lift at the power actually available on approach and climb | Operating evidence, not a separate trade study. Show only the current-mission phases needed to explain the aircraft. |
| Backup | Parasite-drag sensitivity | Value of a measurable drag-reduction target | Label CD0 changes as assumptions; the sweep does not prove that a particular feature achieves them. |
| Backup | Mechanism mass, seal quality, fixed-range MTOW and fixed-MTOW range | What must improve before variable span becomes competitive | Retain the researched telescoping sweep. Put component bills and all seven builds in backup. |
| Backup | Battery-bank failure/climb power | Which failure and low-speed maneuver govern installed power | Keep the active coupled failure screens. Small MTOW changes do not make a failure requirement unimportant. |
| Retire | Equal/two-size/graded prop distributions at fixed aircraft weight | Historical architecture exploration | Different prop configuration and failure set; not the main current design decision. |

## What the current evidence says

**Wing loading and AR.** The coupled study favors high AR, but its best fixed
wing reaches the AR18 upper bound and approximately .20 taper lower bound.
Say “best found within our search bounds,” not “AR18 is the optimum.” Detailed
airfoil, stiffness, gust and aeroelastic constraints are still missing.

The primary minimum-MTOW current-mission fixed design is 2,245.4 lb at
W/S32.72 lb/ft² and 35.15 ft span. Its modeled landing distance is 1,522 ft,
exceeding the 1,500 ft target. A checked landing-passing sampled alternative
is 2,249.1 lb at W/S31.40, AR17.85, 35.76 ft span and 1,494 ft landing distance.
It is the best examined passing alternative, not a separately optimized
landing-constrained solution.

The separate 59-kt clean-stall target remains disabled. These candidates have
clean stall speeds around 76-78 kt and must not be presented as satisfying
that target. The powered landing-configuration stall requirement is a
different screen.

The new wing figure uses only the common coarse grid from the completed
coupled study. Uneven local-search coverage must not masquerade as an AR
sweep. Its left panel minimizes sampled MTOW over W/S and taper at each AR;
the right panel holds taper at .20, connects passing cases and marks rejected
phase/landing cases with crosses. Coincident curves on the left mean the
same coarse samples satisfy both selection rules.

At W/S30 and taper .20, AR14/16/18 give MTOWs of
2,334.6/2,287.9/2,259.9 lb. Wing mass rises 128.1/138.9/151.1 lb and span rises
33.0/34.9/36.8 ft. All three pass the modeled landing check under the assumed
reverse-thrust level. This makes a clear benefit/cost comparison.

**Battery and range.** A fresh 40-case sensitivity uses AR18, taper .20,
W/S28:2:36, 120 KTAS, 45-minute reserve, six 2.8-ft high-lift props and two
4.5-ft cruise props. Each case closes aircraft weight. The plotted selections
also pass the modeled 1,500 ft landing check.

| Pack specific energy, Wh/kg | 250-nm MTOW, lb | 300-nm MTOW, lb |
|---:|---:|---:|
| 300 | 2,762 | 3,142 |
| 350 | 2,468 | 2,713 |
| 400 | 2,260 | 2,468 |
| 450 | 2,115 | 2,282 |

At the assumed 400 Wh/kg PACK level, going from 250 to the assigned 300 nm
adds approximately 208 lb and 29.7 kWh of installed capacity. At 300 Wh/kg,
the 300-nm design is about 3,142 lb. These are sensitivities, not demonstrated
battery products or a full geometry optimization at every technology level.
The W/S grid is coarser than the wing optimization, so its 400 Wh/kg baseline
is slightly heavier than the refined fixed-wing candidate. Compare changes
within each study. The separate three-stop mission remains enforced.

**Telescoping.** Compare an optimized fixed long wing with an optimized
variable-span wing on the same mission. A short fixed-wing benchmark would
mix the benefit of more span with the benefit of retractability.

| Current 120-knot mission | Fixed | Telescoping |
|---|---:|---:|
| Primary minimum MTOW, lb | 2,245.4 | 2,260.6 |
| Landing distance at those points, ft | 1,522 | 1,519 |
| Best examined landing-passing candidate, lb | 2,249.1 | 2,263.1 |
| Landing distance at those candidates, ft | 1,494 | 1,499 |
| Primary mechanism mass, lb | 0 | 10.36 |
| Primary cruise span, ft | 35.15 | 35.11 |

The adaptive wing has 20% mechanical span-retraction capability, but its
lowest-drag setting is full extension at 120 knots. The primary MTOW penalty
is 15.2 lb, or 0.68%; among landing-passing candidates it is 14.0 lb. The
illustrative 100/160-knot route also chooses full span and adds 21.6 lb, or
0.83%, at the primary minima. The current model has not demonstrated a
mission-efficiency benefit from retractability.

Partial retraction appears at higher diagnostic speeds, but favorable points
exceed the assigned cruise-motor ratings, and some exceed the modeled speed
ceiling. Do not present those as achievable performance improvements. The
mechanism and joint-seal estimates remain optimistic conceptual assumptions.

Carry the fixed high-AR wing as the performance reference. Retain telescoping
as a research option whose mission benefit must be demonstrated before
selection. Its interesting concept and fair negative result make a good
midterm trade slide.

## Most useful additional studies

The first version of the proposed cruise-prop study is now complete:
`run_cruiseproptrades2035` checked 251 re-sized combinations using AR18,
taper .20, W/S28/30/32 and the current 250-nm/120-KTAS mission. It calls
`AEGAconstraint` quietly, enforces the modeled landing target, and compares
all-operating sizing with battery-out sizing.

For 4/4.5/5-ft cruise props, the minimum-MTOW battery-out designs select
2.55/2.70/2.80-ft high-lift props and weigh 2,222/2,259/2,306 lb, with total
shaft ratings 137/146/159 kW. Battery 4 out during landing-flap go-around
governs all three. With only all-operating requirements, 1.15-ft high-lift
props minimize sampled MTOW. This makes a clear presentation decision:
downsizing must preserve surviving low-speed capacity.

The disk-area rating rule still ties each motor's power to diameter. There
is no independent rating allocation, RPM/torque limit or wingtip swirl credit.
The 5-ft case hits the 2.8-ft high-lift upper bound; the best 4-ft cruise
case hits the cruise-diameter lower bound. The smallest mathematical passes
require roughly 1–1.6 MW and are **not** the recommended design choices.
Use the minimum-MTOW selections and state the boundaries. See
[the cruise-prop study notes](CRUISE_PROP_TRADE.md) for details.

1. **Landing and approach robustness.** Re-size with the 1,500 ft landing
   target enforced. Compare reverse thrust of 0%, 4% and 8% of weight and add
   deployment delay when supported. Evaluate powered lift at stabilized-
   approach throttle. The current 8% reverse assumption acts immediately
   after touchdown and is not established by a propeller model.
2. **Independent motor-rating split and physical prop limits.** Extend the
   completed cruise-diameter/high-lift downsizing study within the chosen layout.
   Keep two large outboard cruise props and fixed physical high-lift stations.
   Compare the proposed 4/4.5/5-ft diameters and motor allocations using mission energy,
   prop/motor mass, clearance, tip speed and the failure that removes both
   cruise props. This is more relevant than arbitrary prop grading. The
   current disk-area-proportional rating assumption must be updated before
   claiming an independently optimized power split.
3. **Battery placement, fuselage volume and CG.** Compare credible module
   arrangements under explicitly assumed pack volumetric energy density.
   Check occupant/baggage access, containment/cooling space, solo/dual CG and
   required tail size. The fresh pack mass/capacity estimates provide inputs;
   battery dimensions and volumetric density are not established. This is a
   useful integrated configuration study once packaging envelopes are defined.
4. **Cruise speed versus range and installed power.** Re-size each intended
   cruise speed with common reserve and field-length requirements. A speed
   sweep on one already-sized aircraft is an operating diagnostic, not this
   design trade. It would identify a realistic niche for variable span.
5. **2035 technology robustness.** Add usable pack fraction/aging and wing
   mass factors .90 and 1.00 versus the current .80. Pack volume, cooling,
   discharge power and accessible energy after a bank failure need physical
   justification beyond specific-energy assumptions.
6. **Variable-span break-even.** Keep the fixed-wing benchmark and real
   cruise-motor ratings. Sweep mechanism mass and joint drag to determine
   whether any feasible mission produces a net gain. Exclude out-of-rating
   speed points from benefit claims.

## Which saved packages to trust for presentation

| Package | Use / qualification |
|---|---|
| `midterm_review/` | Curated main figures, refreshed battery/range data, exact CSVs and portable MAT details. Start with its README. |
| `trade_results/cruise_props_20261010_163126_508/` | Checked full 251-case cruise-prop/high-lift diameter study, with landing enforced. Use its minimum-MTOW battery-out selections. The package records exact bounds and assumptions. |
| `trade_results/optimized_wings_20261007_190112_237/` | Checked current fixed/adaptive numeric source. Notes record execution on October 8; actual-throttle lift, explicit phase energy, two cruise props and at least 20% retraction capability. The curated main comparison is redrawn directly from its numeric selections. |
| `trade_results/telescoping_20261007_145631_278/` | Mechanism and fixed-range/fixed-MTOW backup. Earlier mission formulation; compare within this package, not absolute weights against the coupled optimization. |
| `trade_results/20261006_125740_775/` | Refined AR9–18 scoping including landing-passing choices. Original all-eight-cruise/inboard-large architecture and older wing assumptions. |
| `trade_results/20261005_124616_226/` | Earlier battery, range/reserve and CD0 sensitivities. Original all-eight-cruise architecture; prefer the refreshed battery figure for main slides. |
| Earlier optimized/telescoping folders | Historical iterations with different settings/energy models or partial exports. Do not choose by timestamp alone. |
| Smoke/validation folders | Checks on small grids, not main searches. |
| `wingtrade_results/` | Historical independent numerical preview. Its implementation is absent; MATLAB reproduction of that snapshot is unverified. |

## Suggested slide sequence

1. Mission, architecture and 2035 assumptions. Show the assigned 300 nm
   requirement alongside the 250 nm development case.
2. Wing loading/AR: benefit, structure/span cost and feasible candidate.
3. Battery/range: technology dependence and the cost of the assigned mission.
4. Fixed/telescoping: adaptation was allowed; full span was selected for the
   intended missions, with a small weight penalty.
5. Cruise diameter/high-lift sizing: show the governing loss of both cruise
   props. Use the thrust-split figure as backup if the main slide is crowded.
6. A compact current-mission phase table: takeoff, climb, cruise and approach.
   Tie powered lift to actual shaft-power demand.
7. Reference configuration and next studies: landing/approach robustness,
   then independent motor allocation and propeller operating limits.

Keep full search tables, mechanism bills, failure matrices and hypothetical
CD0 sensitivities in backup.

## Organization and checks

`AEGAengineout.m`, `run_engineout2035.m` and `check_engineout_climb.m` moved
to `archive/midterm_retired_20261010/` as `.m.txt`. Contents were preserved and
SHA-256 hashes matched. Earlier prop sweeps remain in `archive/propeller_studies/`.
Core geometry, blown-lift, battery-bank failure, mass and mission functions
remain active; their names do not make them disposable trade scripts.

The optimized-wing runner now requests .20–.40 retraction capability instead
of its stale .025–.30 override. Lift, packing and nesting still limit the
achievable stroke.

`prepare_midterm_review2035` checks the saved coupled study, curates its common
wing grid and runs the 40-case matched sensitivity. Force/power/lift balances,
weight/energy/geometry closure, the pack-density trend and CSV round-trip are
checked. See `midterm_review/RUN_NOTES.txt` for execution provenance. Primary
optimizers are not re-run during this curation.

## Architecture research

NASA's X-57 computations support studying large outboard cruise props and
stowed high-lift props. Wingtip-prop drag effects depend on thrust and wing
pressure drag; they are not a generic whole-aircraft efficiency credit. The
current model applies no such credit.
[NASA X-57 propulsion interaction study](https://ntrs.nasa.gov/citations/20230004198).

NASA also treated powered lift on approach as a control-schedule and
stabilized-flight problem. This supports evaluating actual approach throttle
and force balance rather than assuming full-power lift on landing.
[NASA X-57 high-lift propeller control schedules](https://ntrs.nasa.gov/citations/20205010303).
