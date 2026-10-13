# The three studies to present

Use one principal figure and one decision per study. All three close aircraft
weight, propulsion power and mission battery together, using the same two
cruise / six high-lift architecture, phase throttle/blown-lift model,
mirrored-bank failure screens and enabled landing constraint.

| Study | Question | Vary | Show |
|---|---|---|---|
| Wing loading / AR | How much wing do we need? | W/S12–48 lb/ft², AR8–18, with local refinement | MTOW versus W/S, rejected points and landing limit |
| Fixed / telescoping | Does adaptation pay for its hardware? | Independently optimize W/S/taper and fixed AR; adaptive full-span AR18 and lift/packing-limited stroke | Optimized MTOW comparison and actual cruise deployment |
| Cruise / high-lift props | How large should each prop group be? | Cruise diameter2–6 ft, high-lift diameter1–3.2 ft, W/S16–36, with refinement | MTOW versus cruise diameter, selected high-lift diameter and governing constraint |

## 1. Wing loading / aspect ratio

The saved AR18/taper.35 result has a passing minimum around **W/S25.25,
2,277 lb**. The calculated weight trough near **W/S31.25, 2,207 lb** requires
about **1,657 ft** to land against a 1,500-ft target. The lighter point fails
the requirement. Dashed rejected curves now show why the feasible selection
ends before the aerodynamic/weight minimum.

Presentation takeaway: “The landing requirement limits how far we can reduce
wing area. Higher AR helps in this model, but AR18 is our search ceiling and
still needs structural and flutter analysis.”

[Wing figure](../midterm_review/current_20261011_180751_955/01_wing_loading_and_AR.png).

## 2. Fixed versus telescoping

Compare each family's independently optimized aircraft on the same mission.
The fixed wing gets one geometry. The adaptive wing chooses minimum-drag
cruise deployment within lift limits, with motors fixed at the core ends and
full extension for climb/landing. Mechanism mass, overlap/reinforcement and
joint drag count against its aerodynamic benefit.

The saved current-mission comparison gives approximately **2,228 lb fixed**
versus **2,242 lb adaptive**, a **14-lb / 0.6% penalty**. The selected adaptive
aircraft uses full extension in cruise. A 20% stroke capability is not evidence
of an efficiency gain or 20% commanded retraction. Label the mixed-speed
mission as an illustrative scenario and check its deployment table separately.

Presentation takeaway: “The modeled drag savings do not offset the added
hardware on our current mission. The fixed wing is our working choice under
these assumptions.”

[Fixed/adaptive figure](../midterm_review/current_20261011_180751_955/02_fixed_vs_telescoping.png).

## 3. Cruise and high-lift propellers

For each cruise diameter, sweep high-lift diameter and W/S, resize the aircraft,
and select the lowest-MTOW passing combination. This is a joint constrained
weight trade: smaller high-lift props can demand heavier motors and more
battery energy. Show the smallest feasible high-lift diameter separately from
the selected minimum-MTOW combination.

The previous **AR18** sweep selected about **2.75-ft cruise / 2.30-ft high-lift**,
approximately **2,171 lb**. Treat that as a model result, not a hardware choice.
The actuator-disk and empirical mass models lack validated RPM, torque, blade,
clearance and interaction data. The live reference is now **AR15.5**; rerun
before assigning those diameters or that mass to the updated aircraft.

Presentation takeaway: “Larger cruise props reduce disk loading but add weight.
We balance that against high-lift and failure constraints to identify a useful
diameter region for detailed propeller analysis.”

[Prop figure](../midterm_review/current_20261011_180751_955/03_cruise_prop_trade.png).

## Scope and presentation order

The numbers above are from the saved full-grid October11 AR18 reference
packages in [the trade review](../CURRENT_TRADE_REVIEW.md). They were not rerun
or relabeled during workflow consolidation. `AEGAtrades` regenerates results
from live inputs. Compare alternatives within each study: their variables
differ, so the three winning masses are not successive improvements to one
identical aircraft.

Present study1 first, then study3 for propulsion selection, then study2 for
the telescoping concept decision. Keep reverse thrust as an appendix using
`AEGAtrades('reverse')`. It includes hardware, delay, power and ground-roll
energy. The active input now enables a 6% target below 55 kt after at least
2 seconds on the ground. The numerical examples above used the earlier
no-reverse input; re-run before treating them as current reverse-enabled results.

State the common assumptions once: 400-Wh/kg pack target, 90% usable energy,
optimistic wing mass reduction, provisionally whole-aircraft clean polar,
unvalidated blown CLmax and detailed prop/structural limits. Modeled range is
250 nm; the assigned 300-nm requirement remains an open design gap.
