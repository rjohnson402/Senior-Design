# Trade-study search and presentation workflow

`AEGAtrades` defaults to `search_mode='review'`. The wing-loading/AR sweep is
unchanged. The two expensive studies use the following presets; explicit
`options.wings` and `options.props` fields take precedence.

| Setting | Review (default) | Thorough |
|---|---|---|
| Fixed/adaptive missions | Current input mission | Current + illustrative 100/160-knot route |
| Wing W/S samples | 12, 20, 28, 36, 48 plus current | 12:4:48 plus current |
| Fixed AR samples | 8, 12, 18 plus current | 8:2:18 plus current |
| Taper samples | Bounds .15/.70 plus current | .15, .20, .35, .50, .70 plus current |
| Local wing refinement | One seed, 60 evaluations per family/profile | Three seeds, 140 evaluations each |
| Final wing polishing | Two coordinate passes with AR/taper-bound checks | Same |
| Cruise prop diameters | 2, 2.75, 3.5, 4.5, 6 ft | Original 12 diameters, 2–6 ft |
| High-lift diameters | 1, 1.4, 1.8, 2.2, 2.4, 2.8, 3.2 ft | Original coarse grid + local diameter searches |
| Prop W/S samples | 16, 24, 30, 36 plus current | Original grid, 16–36 plus current |
| Prop sizing modes | Required battery-out design | All-operating and battery-out designs |
| Prop local refinement | Joint W/S/diameter near best per cruise diameter | Diameter search at each W/S + joint refinement |
| Extra plot-only sizing | None: reuses common coarse lattice | Common 0.1-ft high-lift lattice |

The review preset reduces aircraft evaluations; it does not relax mass closure,
landing, powered-lift, phase-thrust, cruise-power or battery-out checks. Dense
sampling can find a lighter design or a narrow feasible region missed by review
mode. Use thorough mode or a targeted local sweep before making a final choice.
The current input point is included in the wing W/S/AR/taper grids. Prop grids
are explicit diameter choices, not a hardware database.

Each output folder contains input-derived figure captions, `MAJOR_ASSUMPTIONS.txt`,
numerical tables and the complete saved study. Titles describe the comparison;
the assumptions file records the provisional whole-aircraft polar interpretation,
2035 technology, structure, ground reverse and model limitations. Rejected
samples remain visible as crosses; curves are not spline-smoothed.

For styling changes only, use `AEGAtrades('replot',[],struct('source_folder',folder))`.
Select the original `wing_...`, `optimized_wings_...` or `cruise_props_...` folder.
The new timestamped folder retains the original numbers and assumptions, with a
refresh-provenance file. This avoids running the aircraft solver again. To apply
changed physical inputs, run the normal study command instead.

The AR summary replaces fixed propeller diameter with installed shaft power.
When landing is already enforced, its duplicate “with landing check” curve is
omitted. Propeller diagnostic plots omit empty all-operating panels when only
the battery-out sizing case is requested.
