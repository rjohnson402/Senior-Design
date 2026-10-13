# AEGA aircraft sizing: three commands

Edit aircraft and mission assumptions in [AEGAinputs.m](AEGAinputs.m), then run:

```matlab
cd('C:\Users\ianjf\repos\Senior-Design\sizing')
out = AEGAsize();                 % Size the current aircraft
con = AEGAconstraint(out);        % Plot that aircraft's constraints
trades = AEGAtrades();            % Run and export the three main studies
```

For a quiet constraint check, use `con = AEGAconstraint(out,false)`.
The revised midterm inputs use **CD0 = 0.020768**, **2.75-ft cruise props** and
**1.50-ft high-lift props**, at **W/S = 27 and AR = 15.5**. Propeller trades
now hold W/S at `msn.WS_design`, including local refinement, unless explicitly
overridden. Change the two diameter fields in `AEGAinputs` to change the
reference hardware consistently across sizing and wing studies.
`msn.CD0_override` holds full-wing clean CD0 fixed; set it to `[]` to restore
the earlier geometry-sensitive calibrated buildup. Historical exports retain
their original inputs. The new final package is in
[midterm_revision_20261013](midterm_review/midterm_revision_20261013/).
The presentation wing/AR sweep uses **W/S 20:2:38** and **AR 12, 14, 15.5, 16, 18**,
with no additional local W/S refinement. Explicit study options can override it.
The constraint diagram shows the landing-distance limit; the 60-KCAS powered
landing-configuration stall screen remains in numerical checks but is hidden.
`AEGAtrades('battery')` compares mirrored and cross-paired motor supply and
audits per-bank normal-mission energy. Aggregate battery sizing does not by
itself establish adequate energy in four equal isolated banks.
The wing now uses **LS(1)-0417MOD**, 17% thickness near 30% chord. The team's
2D maximum lift of 2.3 is converted to provisional clean-wing CLmax 2.07 with
a 0.90 factor; flap increments and propeller blowing are added separately.
See [airfoil inputs and limitations](docs/AIRFOIL_CONFIGURATION.md). Saved
results need a new sizing run to apply this change.
`AEGAconstraint()` sizes the current aircraft before plotting. Every trade
sample calls the same `AEGAsize` solver and quiet constraint calculation.
Only the sizing root needs to be on MATLAB's path; do not add `private/`
or `archive/` or use `genpath`.

Current structural inputs are **3.8 ultimate load factor**, wing composite
utilization **FCOMP=.60**, and no extra whole-wing reduction
(`wing_mass_factor=1.00`). The carbon monocoque fuselage uses a single
`fuselage_mass_factor=.90` on the raw FLOPS equation. Use 1.00 as the
fuselage sensitivity. Saved plots and trade results from before this update
retain their original structural inputs and need regeneration for current sizing.
The [October 13 assumption review](assumption_review_20261013/REVIEW.md)
retains the requested **17 kW/kg motor target**, **400 Wh/kg pack** and **5% dry-empty
allowance**. The later team update sets fuselage wetted area to **184.5 ft²**
and CD0 to **0.020768**, giving about **1,736 lb MTOW**, **102.45 kWh**, and
**1,324 ft landing** at the selected geometry and propellers.
The wetted area is an explicit input used consistently by weight and drag.
Updated AR, propeller and battery-energy figures/results are in
[updated_trades_cd0_020768_20261013](updated_trades_cd0_020768_20261013/).
`energy = AEGAtrades('energy')` runs the new **350:25:500 Wh/kg** pack-level
specific-energy sensitivity at fixed input AR, W/S and propeller diameters;
it re-sizes the aircraft at every point. `battery` remains the bank-wiring study.
Saved midterm slides and trade curves predate these composite changes; rerun
the desired study to update its numerical results, rather than only replotting.

| Study | Command | Decision |
|---|---|---|
| Wing loading and aspect ratio | `wing = AEGAtrades('wing')` | Wing area/span versus weight and low-speed constraints |
| Fixed versus telescoping wing | `wings = AEGAtrades('wings')` | Whether adaptation offsets mechanism, structure and joint-drag penalties |
| Cruise and high-lift propellers | `props = AEGAtrades('props')` | Cruise diameter and high-lift diameter needed to satisfy constraints |

Read [the presentation guide](docs/THREE_MAIN_TRADES.md). The
fixed/variable comparison [returns each optimized aircraft and wing geometry](docs/OPTIMIZED_WING_OUTPUTS.md):
`wings.fixed`, `wings.adaptive`, and `wings.optimized_wings`. It optimizes taper
as well as wing loading, unlike the AR-only sweep, which holds taper fixed.
The output distinguishes retraction capability from actual cruise retraction.
The
[saved full-grid review](CURRENT_TRADE_REVIEW.md) contains the earlier AR18
reference results; it remains a dated snapshot until `AEGAtrades` refreshes it.
Cruise and reserve now use a preliminary rotating-propeller / lifting-line
interaction model, including swirl power, wing drag and physical prop stations.
See [the equations, assumptions and switch](docs/WINGTIP_PROPELLER_MODEL.md).
Set `m.wingtip_prop.enabled=false` to compare with the previous cruise physics.
Existing saved full-grid plots/reviews need rerunning after this model change.
Motor ratings now use [constraint-sized cruise and residual high-lift power](docs/PROP_POWER_ALLOCATION.md):
the cruise pair covers its mission demand, and the high-lift group closes
low-speed thrust, blowing and battery-out constraints. Total shaft rating is
solved from those requirements. Set `m.prop_power.mode='disk-area'` to compare
with the previous rating allocation.
The current concept has **AR15.5, W/S27, taper .35 and conditional ground reverse**. Sizing and reference studies
now honor that AR; fixed-wing search ceiling and adaptive full-extension AR
remain **18**. Earlier results are not relabeled as new AR15.5 runs.

The wing/AR study uses the presentation grid listed above. The fixed/adaptive
search retains wider W/S12–48 lb/ft² and AR8–18 bounds, taper .15–.70 and
20–45% allowed telescoping capability; cruise props 2–6 ft, high-lift props 1–3.2 ft and
prop-study W/S fixed at the selected input (currently 27). Local diameter refinement is retained where enabled. The current input point
is included. Actual retraction is limited by lift, packing and nesting; cruise
selects minimum shaft power within those limits. Climb and landing use full extension,
with cruise motors fixed at the core ends.

The default **review** search uses fewer samples and shorter local refinements.
The fixed/adaptive study focuses on the current mission; the prop study focuses
on the required battery-out sizing case. Bounds and physical screens remain
unchanged. These are best-found conceptual designs, not proven global optima.
Use **thorough** for the previous dense searches, both wing mission profiles
and the all-operating propeller comparison:

```matlab
wings = AEGAtrades('wings',[],struct('search_mode','thorough'));
props = AEGAtrades('props',[],struct('search_mode','thorough'));
```

The downsizing plot holds W/S at 27 by default. If a W/S sweep is explicitly
requested, it uses equal W/S coverage at every plotted diameter. Review
mode reuses its sizing grid; thorough mode adds a common 0.1-ft grid for selected
cruise diameters. Local refinement remains in the selection tables rather than
creating misleading curve jumps. See [plot sampling](docs/PROP_PLOT_SAMPLING.md).
Each numerical package includes `MAJOR_ASSUMPTIONS.txt` with the actual mission,
technology, structural, landing, reverse-thrust and aerodynamic assumptions.
The AR summary now plots installed shaft power instead of fixed prop diameter.

Refresh titles and plots from an existing result folder **without re-sizing**:

```matlab
o = struct('source_folder','C:\Users\ianjf\repos\Senior-Design\sizing\trade_results\YOUR_SAVED_STUDY_FOLDER');
updated = AEGAtrades('replot',[],o);
```

This creates a new `replot_...` folder and retains the saved run's physical
inputs and numerical results. It does not apply later edits to `AEGAinputs`.
See [search modes and figure refresh](docs/TRADE_WORKFLOW.md).

Supporting commands:

```matlab
reverse = AEGAtrades('reverse');  % Conditional reverse: mass, delay, power, energy
review = AEGAtrades('inputs');    % Refresh geometry and input sensitivities
AEGAtrades('check');              % Compact physics, regression and export checks
```

The active concept now uses a conditional 6% reverse target, only below 55 kt
and after at least 2 seconds on the ground, with a 1-second ramp and 19.8 lb
of added hardware. Power limits, low-speed fade and ground-roll battery energy
are included. These values need validation with a negative-pitch prop map.
The current 2.75/1.50-ft propeller candidate predicts about 1,325 ft landing.
The earlier 1,472-ft / 1,526-ft reverse comparison is a snapshot
from the former allocation model. See [the updated power calculation](docs/PROP_POWER_ALLOCATION.md)
and [the reverse configuration note](docs/REVERSE_CONFIGURATION.md).
`AEGAtrades('reverse')` compares separately sized no-reverse and reverse cases.
Set `m.reverse_TW=0` to test unavailable reverse with installed hardware;
also set `m.reverse_hardware_lb=0` for an aircraft without that hardware.
The input review updates [the geometry handoff](GEOMETRY_HANDOFF.md)
and `input_review/`. These exports record the inputs used when generated.
The teammate's polar is in `data/aerodynamics/`; its whole-aircraft
interpretation remains provisional. The modeled mission is 250 nm at 120 KTAS
plus 45 minutes reserve; the assigned 300-nm requirement remains a separate
sensitivity.

Change a sweep without editing helpers:

```matlab
m = AEGAinputs();
options = struct('plot',false,'save',false);
options.wing = struct('WS',20:.5:36,'AR_values',[14 16 18]);
wing = AEGAtrades('wing',m,options);
```

`options.wings` and `options.props` override the other study options. Shared
ranges/layout are in [private/AEGAstudysettings2035.m](private/AEGAstudysettings2035.m).
The full workflow saves timestamped numerical packages to `trade_results/`,
presentation figures/tables to `midterm_review/`, and updates
`CURRENT_TRADE_REVIEW.md`. Without plots, numerical exports still work but the
presentation review is not generated. Validation uses small grids and never
replaces the full-grid presentation review.

The root has four MATLAB files: inputs plus the three commands. `private/`
holds active reusable physics, study engines, plots and checks. These are
dependencies, not unused scripts. The old runners, `Hub`, old sizing model and
retired helpers are preserved in the [workflow archive](archive/workflow_before_20261011/README.md),
with checksums and `.m.txt` extensions to prevent accidental execution.
Existing numerical result packages are preserved.
