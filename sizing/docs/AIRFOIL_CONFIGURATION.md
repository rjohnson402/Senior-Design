# LS(1)-0417MOD input configuration

The selected wing airfoil is **LS(1)-0417MOD**. The original University of
Illinois coordinate file is saved in `data/aerodynamics/ls417mod.dat` (Lednicer
format: separate upper/lower surfaces). It agrees with approximately 17%
maximum thickness at 30% chord. `TCA=.17` feeds the FLOPS wing weight and
telescoping joint/spar-depth estimates; it does not define a manufactured spar.

Edit the airfoil block in `AEGAinputs.m`:

```matlab
'clmax_2d',2.3,'wing_clmax_factor',.90
```

The section maximum comes from the team's stated **2D analysis**, not an
independently verified aircraft test. The 0.90 factor is a provisional analyst
allowance for the finite wing, without a taper/twist-dependent stall analysis.
The resulting coefficients, before propeller blowing, are:

| Configuration | Calculation | Maximum lift coefficient |
|---|---|---:|
| Clean wing | 2.3 × .90 | 2.070 |
| Landing flaps, nominal area | clean + 1.40 × .69 × .92 | 2.959 |
| Takeoff flaps | clean + .50 assumed whole-wing increment | 2.570 |

Landing blown-lift models use the actual flap/strip areas of each sized wing,
so their unblown baseline may differ from the nominal area-average above.
Blowing is added separately at the scheduled thrust; the existing maximum
credit cap of 4.0 remains. Entering 2.3 as a flapped or blown coefficient would
double-count later increments. A measured or validated **3D wing** maximum
could instead replace `CLmax_clean` directly, with the section factor bypassed.

Reynolds number, Mach, transition settings, roughness and method of obtaining
the team's 2.3 are unconfirmed. The NASA report shows maximum section lift
depends on Reynolds number and surface condition; 2.3 is not universal.
Use a lower clean-wing maximum as a sensitivity until the section and wing
stall are validated. The teammate's existing drag polar and wing drag form
factor are retained provisionally; specifying a new airfoil does not generate
a new viscous polar or validate flap increments. Obtain matched clean and
flapped data for this section at the sized wing's Reynolds numbers.

Earlier numerical packages retain their original airfoil/lift assumptions.
Run the sizing/trade commands to apply these inputs; `replot` only restyles
saved numbers. `AEGAtrades('inputs')` refreshes the geometry handoff and input
sensitivities with the selected section.

Sources:

- [UIUC LS(1)-0417MOD coordinates](https://m-selig.ae.illinois.edu/ads/coord/ls417mod.dat)
- [NASA TM-78709: Low- and Medium-Speed Airfoil Development](https://ntrs.nasa.gov/citations/19800012809)
