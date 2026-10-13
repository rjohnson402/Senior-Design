# Constraint-sized cruise and high-lift power

Implemented October 12, 2026. Current sizing, wing studies and propeller studies use the same independent group-rating calculation. The wingtip swirl model remains active for cruise/reserve.

## What changed

The previous rule assigned motor ratings in proportion to propeller disk area. When a failure case required more high-lift power, that rule also increased the cruise-motor ratings. The new calculation holds the cruise rating at its mission requirement (or a supplied physical motor rating) and solves for the six high-lift motors separately. The total installed shaft rating is a **result of the constraints**, not a prescribed power budget.

With two cruise motors and six identical high-lift motors:

```text
C = maximum cruise/reserve shaft demand * cruise_rating_margin
H = smallest high-lift group rating satisfying all enabled constraints
Pinstalled = C + H
Cruise motor rating = C / 2
High-lift motor rating = H / 6
```

The default cruise rating margin is 2%. No additional peak overload or crossfeed is credited. The inner sizing calculation holds C fixed while solving H; the outer aircraft weight/battery iteration recalculates cruise demand as the aircraft changes.

At each low-speed phase, the rated cruise pair provides as much of the required thrust as needed, up to its rating. The high-lift group supplies the residual thrust **and** any additional power needed for blown-lift capacity. If blowing requires transferring some thrust from the cruise pair to the high-lift system, the controller reduces cruise power. Approach must balance the descent thrust exactly; it cannot satisfy lift by simply adding excess forward thrust. Climb can exceed the minimum thrust needed for its declared climb target. Takeoff uses all installed motor ratings, consistent with the existing takeoff field correlation.

This is not a subtraction of shaft kilowatts. Each propeller's axial momentum/energy balance relates power to thrust:

```text
T = 2 rho A vi (V + vi)
Pshaft = T (V + vi) / prof
TH_needed = max(0, T_required - TC_available)
```

The controller converts the remaining thrust into high-lift shaft power on the actual surviving disk area. Wing blowing is integrated on the existing physical hub locations and contracted wakes. The two groups generally have different disk loading, so their thrust fractions are no longer equal to their power fractions or area fractions.

## Constraints that set the result

Every candidate checks the normal takeoff-field, climb and turn power correlations, plus the actual takeoff, initial/clean climb, approach and go-around phase allocations. Cruise and reserve use the two cruise motors alone and retain the clean lift limit.

The battery-out calculation tests four mirrored pairs: banks 1-3 each remove two high-lift motors, while bank 4 removes both cruise motors. For each pair it checks the powered landing-config lift target, force-balanced approach, takeoff-flap climb and landing-flap go-around. It solves high-lift rating at fixed cruise rating without transferring failed motor power to survivors. The selected total is the largest enabled requirement, including the declared power margin. A separate single-motor loss may produce asymmetric control and trim requirements that these mirrored screens do not resolve.

The default failure climb gradient remains the existing **2% analyst target**, at 1.3 times the landing-config target speed. It is not a newly established certification requirement. Required normal flight uses the existing 730-ft/min climb schedule and its phase lift margins. These two conditions must not be described as the same requirement.

## Current-input result

For the current AR15.5, W/S27, 4.5-ft cruise and 2.8-ft high-lift configuration, the checked result is:

| Rating | Result |
|---|---:|
| Cruise pair | 39.54 kW, 19.77 kW per motor |
| Six high-lift motors | 80.91 kW, 13.49 kW per motor |
| Total installed shaft rating | 120.45 kW |
| Governing failure | Bank 4 out, landing-flap go-around |
| Resized MTOW | 2274.31 lb |
| Modeled landing distance | 1426 ft |

These are preliminary model results, not hardware ratings validated by a propeller map. The current constraint table reports 88.56 kW total installed for the cruise-bank-out takeoff-climb screen and 120.45 kW for its landing-flap go-around screen. The installed total includes the cruise motors even in the failure case where they provide zero power.

Exact checks and phase/group allocations are saved in `trade_results/residual_power_check/constraint_ratings.csv` and `current_phase_power.csv`. The propeller trade now exports separate group ratings, actual takeoff/climb group thrust and power, and a stacked group-rating figure.

A checked sensitivity on the same 4.5-ft/2.8-ft configuration, independently
resizing weight at each failure gradient, gives 120.45 kW at 2%, 132.73 kW at
4%, and 145.34 kW at 6%. Cruise-bank-out landing-flap go-around governs all
three. This is why the project's actual failure-climb target should be settled
before interpreting the calculated rating as a hardware requirement. Exact
values are in `trade_results/residual_power_check/failure_gradient_sensitivity.csv`.

## Inputs and limitations

`msn.prop_power` controls the calculation. `mode='cruise-residual'` is the current default; `mode='disk-area'` preserves the old allocation. `cruise_pair_rating_kW=[]` requests automatic cruise sizing; a positive value represents an explicitly selected pair rating. A selected pair that cannot cover cruise/reserve is rejected. `max_installed_shaft_kW=Inf` allows the constraints to determine the required rating without an arbitrary hardware cap. A finite cap is optional and rejects oversized results; it never truncates the calculated requirement and marks it as passing.

The existing 0.60-hp/lb failure-search ceiling is a numerical search bound, not a selected installed-power budget. Small-prop results still require blade loading, RPM/torque, thermal, ground-clearance and structural validation. The low-speed model assumes the props can absorb their assigned shaft ratings with suitable pitch; it does not establish that a selected fixed-pitch blade can do so. High-lift slipstream benefit, flap model, profile factor and minimum failure gradient remain explicit conceptual assumptions.

`AEGAtrades('check')` verifies group-rating sums, fixed cruise hardware, residual climb thrust, actual per-disk energy balances, power-cap rejection, cruise-bank loss, mission energy accounting, and the existing workflow/export checks. Saved full-grid figures from before this change remain historical snapshots; rerun the desired trade for a new full-grid search.
