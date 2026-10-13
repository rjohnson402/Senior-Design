# Fixed and variable-span wing optimization outputs

Run `wings = AEGAtrades('wings')`.

Both families are resized at every candidate until aircraft mass and mission
battery close. The fixed wing searches **W/S, AR and taper**. The variable-span
wing searches **W/S and taper**, with fully extended AR fixed at **18**, as
requested. In the default lift-drag policy, allowable stroke is derived from
cruise lift, propeller packing and nesting; deployment is optimized per cruise
or reserve speed. The manual policy additionally searches stroke capability.

The aircraft hardware does not change during the selected-design speed sweep.
The variable wing changes deployment, while its motors stay at the fixed core
ends. Climb and landing use full extension. If optimized cruise deployment is
1, that aircraft stays fully extended at the mission speed; nonzero available
stroke does not imply useful retraction.

The results now directly return the complete selected aircraft:

```matlab
wings.fixed                 % first mission's optimized fixed aircraft
wings.adaptive              % first mission's optimized variable-span aircraft
wings.optimized_wings       % geometry and actual cruise deployment table
wings.selected_mass_breakdown
wings.optimization_checks
```

For multiple profiles, use `wings.optimized_aircraft(ip).fixed` or `.adaptive`;
each element includes its profile name. Full returned aircraft contain `msn`,
`options`, `SW`, `span`, `MAC`, `W`, `cruise_geometry`, `operating_phases`,
propeller layout and constraint results. A selected candidate is checked against
the lowest passing MTOW actually evaluated in its family/profile, then checked
for geometry, mass closure and landing/phase consistency.
After simplex refinement, two short coordinate passes check nearby values and
the AR/taper bounds. This reduces missed endpoint minima when a short simplex
run spends evaluations outside the bounds. A short scalar W/S search then
re-optimizes loading for the selected AR/taper. `polish_passes` and
`final_WS_refine` can be overridden.

The saved package includes `09_optimized_wing_geometry.csv`,
`10_selected_mass_breakdown.csv`, `11_optimization_checks.csv`, and
`10_optimized_wing_geometry.png`/`.fig`. The planform figure shows full extension,
minimum available span and chosen cruise span. The comparison figure also labels
taper. The recorded best result is bounded by the search and model assumptions;
it is not a proven global optimum.

The AR-only study holds taper at the input value (currently .35). This comparison
can select .15, its lower bound. Differences therefore combine AR, W/S and taper
choices; they cannot be attributed entirely to span adaptation. Boundary values
are flagged in `best.BoundaryVariables` and the geometry table.

In the October 12 19:31 saved run (new airfoil), selected weights were 1,854.22 lb
fixed and 1,901.44 lb variable. The AR-only study selected 1,864.34 lb at AR18 and
taper .35. The 10-lb fixed-wing difference is much smaller than comparing these
results with older saved plots from different structural/airfoil inputs.
The variable design had 20% stroke capability but chose full span for 120-KTAS
cruise. Those are dated numerical results, not new structural validation.

`AEGAtrades('replot',[],struct('source_folder',folder))` can expose the new tables
and planform figures for an existing optimized study without a new search. Its
original inputs and numerical selections are retained.

The updated full review search at October 12 23:05, including final coordinate
and W/S refinement, selected **1,847.12 lb fixed** and **1,898.85 lb variable**.
Both use AR18 and taper .15 (the lower search bound). Selected W/S values are
32.132 and 26.655 lb/ft²; spans are 32.17 and 35.81 ft. The variable design has
20% retraction capability and 0% actual retraction at 120 KTAS. Both close mass
and pass the modeled landing/phase screens. This remains a bounded conceptual
result, particularly at the taper endpoint; it is not a structural validation.
