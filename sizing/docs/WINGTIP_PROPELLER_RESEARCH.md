# Wingtip propellers: research and a future sizing approach

Research date: October 12, 2026. The initial research step did not change the solver.
The original search is preserved below. A reduced-order variant has since been
implemented; see [the active model and assumptions](WINGTIP_PROPELLER_MODEL.md).

The literature supports induced-drag reduction from powered wingtip propellers. It does not establish a universal reduction percentage determined only by diameter and RPM. A useful model must include propeller loading, slipstream swirl, rotation direction, wing geometry, and propeller location. Distinguish flight speed V from rotation rate n = RPM/60.

## Papers to start with

1. **Blaesser (2019), NASA Langley: Propeller-Wing Integration on the Parallel Electric-Gas Architecture with Synergistic Utilization Scheme (PEGASUS) Aircraft.** [NASA record](https://ntrs.nasa.gov/citations/20200002426), [PDF](https://ntrs.nasa.gov/api/citations/20200002426/downloads/20200002426.pdf). Most directly relevant diameter/speed study: Section IV.A and Figure 8 sweep diameter and helical tip Mach number. For this configuration, larger tip props increased required thrust but decreased shaft power. Its workflow couples FlightStream aerodynamics with XROTOR propeller performance; minimize power with lift and thrust balance constraints. These trends are configuration-specific.

2. **Sinnige et al. (2019): Wingtip-Mounted Propellers: Aerodynamic Analysis of Interaction Effects and Comparison with Conventional Layout.** [PDF](https://pure.tudelft.nl/ws/portalfiles/portal/127913588/1.C034978.pdf), DOI 10.2514/1.C034978. Wind-tunnel evidence: approximately 15% drag reduction relative to an inboard-propeller configuration at CL = 0.5 and CT = 0.12. The reported percentage is not an aircraft-wide induced-drag correction. The favorable tractor rotation is inboard-up, opposing the wingtip vortex. Effective span efficiency increases.

3. **Nederlof et al. (2023): Contribution of Swirl Recovery to the Induced Drag of a Propeller-Wing System - A Parametric Study.** [PDF](https://pure.tudelft.nl/ws/portalfiles/portal/154235098/6.2023_3543.pdf), DOI 10.2514/6.2023-3543. Best modeling reference: blade-element momentum, a slipstream tube model, and a corrected vortex-lattice model. Section III.B, equations 4-8, calculates circulation and separates vortex-induced and swirl-induced drag. Finite slipstream height is explicitly corrected. The paper studies wing induced drag; propeller efficiency and viscous penalties require separate accounting.

4. **Borer et al. (2024): Flight Performance Estimates for the NASA X-57 Distributed Electric Propulsion Flight Demonstrator.** [PDF](https://ntrs.nasa.gov/api/citations/20240010807/downloads/x57_performance_manuscript-v4.pdf). Table 2 separates power-off and power-on results. The often quoted 53% Mod III versus Mod II cruise L/D improvement includes wing redesign and integration; it is not a 53% propeller-only drag reduction. These are estimates, with the program concluding before flight demonstration of the features.

5. **Minervino et al. (2022): Drag Reduction by Wingtip-Mounted Propellers in Distributed Propulsion Configurations.** [Paper](https://www.mdpi.com/2311-5521/7/7/212), DOI 10.3390/fluids7070212. Diameter and thrust allocation sweeps using actuator disks and wing analyses. Predicted wing-drag reductions reach 6% in cruise and 10% in climb for the configurations studied. Useful for comparison, not a transferable default.

6. **Cole et al. (2021): Influence of Propeller Location, Diameter, and Rotation Direction on Aerodynamic Efficiency.** [University record](https://pure.psu.edu/en/publications/influence-of-propeller-location-diameter-and-rotation-direction-o/), DOI 10.2514/1.C035917. Uses trimmed propeller power as the metric. For its test case, the overall optimum was an inboard-down propeller near the root. Minimum wing drag and minimum propulsion power can lead to different layouts.

## Equations and a proposed implementation interface

Use Dp for propeller diameter and Drag for aircraft drag. With SI units, standard propeller definitions are:

```text
n = RPM / 60
J = V / (n * Dp)
T = CT(J, pitch, ...) * rho * n^2 * Dp^4
Pshaft = CP(J, pitch, ...) * rho * n^3 * Dp^5
eta_p = J * CT / CP
```

These definitions appear in the [NASA X-57 propeller test nomenclature](https://ntrs.nasa.gov/api/citations/20210016834/downloads/LSAWT_HLP_Test_Aviation2021_Final0628.pdf). CT and CP require a propeller performance map or blade analysis; they are not constants across arbitrary RPM, diameter, and airspeed changes. Check coefficient conventions before combining papers, particularly FlightStream's CT in the PEGASUS paper and the freestream-based TC in Nederlof.

For the existing sizing interface, a proposed calibrated correction is:

```text
CDi_base = CL^2 / (pi * AR * e_base)
fi = 1 - CDi_powered / CDi_base
CDi_powered = (1 - fi) * CDi_base
```

The baseline expression is documented by [NASA Glenn](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/winglets/). The last two lines are algebraic definitions, not a published correlation for fi. For positive CDi_powered, they can also be written e_effective = e_base/(1-fi). For example, a hypothetical 20% induced-drag reduction corresponds to e_effective = 1.25 e_base. If induced drag represents half of total drag, that gives 10% total-drag reduction before installation penalties. These are illustrations, not predictions for AEGA.

My recommended future interface is a lookup or fitted function of Dp/b, J, propeller loading, CL, normalized hub coordinates, rotation direction, and the relevant wing/propeller geometry. Generate its values from a coupled propeller/wing model at equal aircraft lift, rather than assigning an unvalidated diameter-only formula. The propeller model must provide swirl as well as axial induction: an axial-only disk model misses swirl recovery.

For level flight, iterate thrust and drag until sum(T) = Drag. Then calculate battery power as sum(Pshaft)/(eta_motor * eta_power_electronics). Include changed viscous/nacelle drag, installation mass, and propeller efficiency when comparing designs. Do not credit the same recovered energy once as reduced drag and again as an unrelated propeller-efficiency bonus.

## Fit to the current code

- AEGAsize.m currently calculates cruise CDi using fixed msn.e_osw. Its propeller efficiency estimate depends on thrust loading and active disk area, without a resolved swirl field or RPM map.
- private/AEGAtelescopingcruise.m selects deployment using parasite drag plus an induced-drag term with fixed e_osw. A future correction must enter this calculation before choosing deployment, and then be reflected in reported CDi and mission power.
- The README and geometry helpers describe cruise motors fixed at core ends for the telescoping concept. Evaluate each physical hub relative to the current deployed semispan. With an extended outer panel, a core-end propeller is inboard of the aerodynamic tip; a true-wingtip correlation cannot be applied unchanged.

Recommended first study: explicitly labeled sensitivity cases with no benefit and several assumed induced-drag reductions, followed by a geometry-specific diameter/RPM/thrust sweep once propeller and swirl data are available. Preserve zero credit as the baseline until calibrated. Current implementation is unchanged.
