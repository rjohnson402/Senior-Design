# AEGA electric-aircraft sizing

Start with [the geometry handoff for the aerodynamic teammate](GEOMETRY_HANDOFF.md), [the current trade results](CURRENT_TRADE_REVIEW.md), and [the input/assumption review](docs/INPUT_ASSUMPTIONS.md).

The [reverse-thrust comparison](REVERSE_THRUST_REVIEW.md) includes conditional 3%, 5% and 8% ground-braking targets, added pitch/control hardware, deployment delay, power limits and landing energy. Run `run_reversetrades2035` for this comparison alone; `run_currenttrades2035` now includes it after the three main studies. The trainer reference remains capable of the modeled landing without reverse.

The October 11 input revision uses the teammate's supplied panel-polar summary, a geometry-sensitive calibrated drag buildup, effective e = .763, and landing without reverse-thrust credit. The working reference is **W/S 24 lb/ft², AR 18, taper .35**, with two 4.5-ft cruise props and six 2.8-ft high-lift props. The current mission remains 250 nm at 120 KTAS plus 45 minutes reserve; the assigned 300-nm requirement is a separate sensitivity. These are conceptual sizing results and optimistic 2035 technology targets.

## Run in MATLAB from this folder

If MATLAB is currently in a different folder, enter:

```matlab
cd('C:\Users\ianjf\repos\Senior-Design\sizing')
run_currenttrades2035
```

Alternatively, launch directly with `run('C:\Users\ianjf\repos\Senior-Design\sizing\run_currenttrades2035.m')`. The runner adds its own folder to the MATLAB path so its helpers can be found.

| Command | Purpose |
|---|---|
| `Hub` | Size the current two-cruise/six-high-lift reference and show its constraint diagram |
| `run_inputreview2035` | Generate the geometry handoff, source-polar plot, phase table and assumption sensitivities |
| `run_currenttrades2035` | Rerun all three studies, validate the selections, and refresh the current review |
| `run_wingtrades2035` | Wing loading / aspect ratio |
| `run_optimizedwingcomparison2035` | Independently optimized fixed / telescoping wings |
| `run_cruiseproptrades2035` | Cruise diameter / constraint-sized high-lift propellers |
| `run_reversetrades2035` | Conditional reverse thrust versus no reverse, including hardware and energy |

`AEGAinputs.m` owns mission, technology, aircraft assumptions and the polar calibration. `AEGAstudysettings2035.m` owns search ranges and the common prop layout. `AEGAstudycase2035.m` resolves the current architecture and coupled flight-phase options. Constraint checks within sweeps are quiet; only summary plots are produced. Input changes require rerunning the studies; saved reports are snapshots.

Wing-loading plots distinguish passing designs (solid lines) from converged designs that fail performance screens (dashed lines and crosses). The search still covers W/S12–48; a feasible curve ending near25 is usually a landing or flight-phase limit, not the end of the numerical search. The wing review includes the full calculated weight curve, a zoom of its trough and the landing-distance curve. `08_AR_feasibility_diagnostics.csv` reports passing and calculated weight minima separately. The calculated minimum is not an acceptable design unless its screens pass.

## Files and folders

| Location | Contents |
|---|---|
| Root `.m` files | Active MATLAB entry points, models and checks; kept together so ordinary MATLAB path resolution works |
| `data/aerodynamics/` | Unmodified teammate source polar and provenance |
| `docs/` | Aerodynamic assumptions, coupled-flight model and detailed study notes |
| `input_review/` | Current reference geometry, polar plot, sensitivity results and saved sizing details |
| `trade_results/` | Timestamped complete study runs; earlier results preserved |
| `midterm_review/current_*/` | Presentation figures and selection tables from completed three-study runs |
| `concept_variable_span/` | Earlier illustrative OpenVSP/layout models; **not updated to the new handoff geometry** |
| `wingtrade_results/` | Historical independent numerical preview; superseded |
| `archive/` | Retired studies, the previous input file and the previous long README |

Detailed notes: [coupled flight phases](docs/COUPLED_FLIGHT_MODEL.md), [prop trade](docs/CRUISE_PROP_TRADE.md), [fixed/adaptive optimization](docs/OPTIMIZED_WING_COMPARISON.md), [mechanism research](docs/TELESCOPING_TRADE.md), and [historical midterm review](docs/MIDTERM_TRADE_REVIEW.md). Historical numerical sections retain their dates and original assumptions; use `CURRENT_TRADE_REVIEW.md` for the latest selections.

## Model and validation

`AEGAtrade_size` closes weight, installed power and mission energy. `AEGAparasiticdrag` applies the teammate-polar calibration once while preserving geometry changes; `AEGAtelescopingcruise` uses the same calibrated wing-friction contribution during retraction. `AEGAblownstate2035`, `AEGAflightphases2035`, and `AEGAcoupledmission2035` connect actual throttle, lift capacity, thrust and phase energy. `AEGAbatteryout` screens the four mirrored bank failures. `AEGAweight` supplies empirical component masses.

Run `check_polarinputs2035` for source/fit/calibration/landing checks and `check_currenttrades2035` for current-input propagation and physical balances. The runner also checks completed selections. `AEGAlegacyinputs2035` is an explicit old-input regression fixture, not the current design. Historical `AEGAsize` remains available as an all-eight-props-cruise compatibility calculation; it now shares the calibrated drag helper, while `Hub` uses the current architecture.

The biggest unresolved assumptions are pack capability, clean/flapped CLmax, structure and flutter at AR18, installed hardware/cooling mass, and real propeller performance. The input review quantifies these. The clean polar's component scope and trim need confirmation; it is provisionally interpreted as a whole-aircraft clean polar. The separate 59-kt clean-stall screen remains disabled. No wingtip-swirl credit, flight-tested blown-lift gain, or demonstrated post-failure controllability is claimed.

Legacy supporting runners `run_telescopingtrades2035`, `prepare_midterm_review2035`, and `refresh_coupledflight_exports` are retained for reproducing their documented workflows; they are not the main three-study presentation path.

