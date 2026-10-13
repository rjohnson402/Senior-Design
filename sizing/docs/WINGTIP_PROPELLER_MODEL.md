# Preliminary wingtip-propeller interaction model

Implemented October 12, 2026. Enabled by default in `AEGAinputs.m` for cruise and reserve. The usual `AEGAsize` and `AEGAtrades` commands use it automatically.
Motor rating allocation has since been updated to [independent constraint-sized
cruise and high-lift groups](PROP_POWER_ALLOCATION.md). The on/off comparison
near the end of this note isolates the wingtip model under the former disk-area
allocation, rather than the current complete aircraft configuration.

## Model choice and scope

This is an original **reduced-order rotating-actuator-disk / classical lifting-line implementation**, following the actuator-disk/wing-analysis approach of [NASA PEGASUS, Blaesser (2019)](https://ntrs.nasa.gov/api/citations/20200002426/downloads/20200002426.pdf). It resolves the vortex-induced and swirl-induced contributions emphasized by [Nederlof et al. (2023)](https://pure.tudelft.nl/ws/portalfiles/portal/154235098/6.2023_3543.pdf). It does not reproduce NASA's FlightStream/XROTOR implementation or Delft's BEM/slipstream-tube/corrected-VLM model. No fixed percentage benefit is assigned.

Missing blade geometry and measured propeller maps prevent a blade-specific prediction. Instead, the existing profile efficiency and explicit RPM assumptions close a rotating-disk model. The smooth solid-body swirl distribution is an analyst-selected minimum-energy closure for a given wake torque, not measured blade loading. This makes the result a preliminary design estimate suitable for sensitivity studies. Numerical conservation and convergence tests are not experimental validation.

The clean source polar is assumed to represent the unpowered baseline; confirm this with the teammate. If that polar already includes powered interactions, applying this correction would count some benefit twice. The supplied baseline span efficiency and parasite calibration are preserved rather than overwritten by an ideal-wing efficiency.

## Equations

All internal units match the existing sizing model: ft, ft/s, lbf, slug/ft³. Power in ft·lbf/s is divided by 737.56 to obtain kW.

For each active propeller, thrust is allocated in proportion to disk area. Axial momentum gives:

```text
A = pi D² / 4
T = 2 rho A vi (V + vi)
Uw = V + 2 vi
Aw = A (V + vi) / Uw
Rw = sqrt(Aw / pi)
```

The hub fraction h and contracted radius define the wake's polar area moment, I = pi Rw⁴ (1-h⁴)/2. A solid-body angular wake velocity s gives angular momentum and kinetic energy fluxes:

```text
Q = rho Uw I s
Pswirl = rho Uw I s² / 2 = Q² / (2 rho Uw I)
Q = Pshaft / omega
prof Pshaft = T (V + vi) + Pswirl
```

The last relation is a quadratic in shaft power. The smaller positive root is evaluated without subtractive cancellation. A negative discriminant rejects loading/RPM combinations outside this closure's operating domain. Thus greater swirl is charged to propulsion power before any wing benefit is credited.

At propeller-to-wing spacing x, the chosen uniformly loaded disk interpolation is g = (1 + x/sqrt(x²+(D/2)²))/2. It changes the axial velocity from V+vi at the disk toward V+2vi downstream. Mass conservation contracts the local wake, and the tangential field uses g times the downstream circulation mapped to that radius. This is an engineering interpolation, not a free-wake solution. Axial induction occupies the disk projection; swirl excludes the hub. Mirrored inboard-up rotation creates upward velocity on the wing side of a tip propeller.

The current deployed trapezoid, including the core/exposed-tip chord step, is represented with a Fourier lifting-line series. With U the local axial velocity and u the upward propeller-induced velocity, the wing equations are:

```text
Gamma(y) = 2 b_visible V sum(An sin(n theta))
w(y) = V sum(n An sin(n theta)) / sin(theta)  [downward positive]
Gamma / (0.5 a0 c U) + w/U - alpha = u/U
integral(rho U Gamma dy) = W
Dvortex = integral(rho Gamma w dy)
Dswirl = -integral(rho Gamma u dy)
```

Angle of attack and circulation are solved together at the same required aircraft lift. The baseline polar receives **Dvortex,powered - Dvortex,unpowered + Dswirl**, computed on the same geometry. Added scrubbing drag integrates the existing calibrated wing-friction coefficient against the increase in local dynamic pressure. The scalar cruise solution iterates total thrust until it equals the resulting aircraft drag. Battery power uses the resulting shaft power and existing motor/inverter efficiencies. No extra efficiency bonus is added for swirl recovery.

## Inputs and outputs

Edit `msn.wingtip_prop` in `AEGAinputs.m`:

| Input | Default | Meaning |
|---|---:|---|
| enabled | true | Set false to recover the previous cruise model exactly |
| design_J | 1.35 | Assumed design advance ratio when RPM is unspecified |
| rpm | [] | Optional fixed RPM, scalar or one value per motor |
| reference_speed_ktas | [] | Resolved once from the design cruise speed; held across route/reserve |
| rotation | +1 | Mirrored inboard-up; -1 reverses the rotation |
| hub_radius_fraction | .20 | Hub radius / disk radius |
| x_over_D | .25 | Propeller plane distance ahead of wing / diameter |
| lift_curve_slope | 2 pi | Assumed section slope per radian |
| panels | 64 | Fourier modes/collocation points across the full visible span |
| max_tip_mach | .85 | Helical tip Mach ceiling for this incompressible model |

With unspecified RPM, each candidate diameter is designed at J = Vreference/(nD). RPM is then fixed as the same aircraft flies other speeds. This is a variable-pitch/design-envelope assumption, not a fixed-pitch propeller map. Low-speed operation continues to use the existing separate blown-lift model. No wingtip interaction credit is added to takeoff, climb, landing, reverse, or engine-out constraints.

`out.wingtip_prop` records RPM, advance ratio, tip Mach, physical hub positions, vortex/swirl drag, scrubbing drag, swirl power, effective efficiency, and lift/thrust/power residuals. `out.CDi`, cruise drag, shaft power, mission energy, battery mass, and converged MTOW use the new calculation. Each route/reserve phase stores its own interaction diagnostics. Propeller-trade tables export the modeled induced-drag reduction, swirl drag/power, and RPM.

Cruise motors stay at stationary core ends as telescoping panels deploy; the model uses the actual deployed semispan and physical hub coordinates. Enabled adaptive deployment/stroke searches minimize **shaft power**, subject to the existing lift/packing/nesting constraints. Historical `drag_optimum_fraction` and `RetractDragOptimum` export names remain for compatibility; `optimization_metric` and `operating_optimum_fraction` identify the current meaning.

## Checks and limitations

`AEGAtrades('check')` now checks this model's lift, thrust and power conservation; zero-thrust behavior; reversed rotation; diameter/RPM sensitivity; fixed core hubs; 64-to-128-mode refinement; fixed-RPM mixed-speed mission accounting; and exact disabled/missing-input fallback. It also runs the existing workflow checks. A current on/off comparison is saved in `trade_results/wingtip_model_check/`.

The approximation assumes attached, small-angle flow, nearly straight high-aspect-ratio wings, aligned tractor propellers, and prescribed axial/swirl wakes. It does not model finite-blade loading, finite-slipstream-height correction, wing deformation of the wake, mutual propeller inflow, propeller-off windmilling drag, or detailed nacelle interference. Section slope, profile factor, RPM, hub fraction, and disk spacing need sensitivity checks and eventual replacement with geometry-specific data. The 2° reference sweep is treated as straight; a substantially swept wing needs a VLM implementation.

The October 12 current-input check, with each model independently closing aircraft weight, gave:

| Quantity | Previous model | New model |
|---|---:|---:|
| MTOW, lb | 2313.32 | 2306.01 |
| Cruise drag, lbf | 120.78 | 118.51 |
| Cruise battery power, kW | 42.78 | 42.45 |
| Governing usable mission energy, kWh | 127.61 | 126.68 |

On the final new-model geometry, the modeled induced-drag reduction relative to its unpowered baseline is 5.41%, at approximately 2001 RPM and J = 1.35. This reduction is partly offset by 0.385 kW of wake swirl power and 0.139 lbf of additional wing friction drag. These are model outputs, not measured performance. Independent resizing also changes the wing area and mass, so the before/after table is not an isolated propeller test.

Saved full-grid reviews and figures predating this change remain dated snapshots. Rerun the desired trade command to obtain results with the new model.
