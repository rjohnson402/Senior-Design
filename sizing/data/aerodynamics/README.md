# Teammate aerodynamic source

`Panel_drag_polar.csv` is an unchanged copy of the file supplied October 11, 2026. Its recorded analysis date is October 8, 2026.

SHA-256: `A3BBF8F0F6A278BA60C289292D6F7E073307ADBD797E9A08950FF8AB438768C0`

The five-point summary is J6:Q11. The remaining records include VSPAERO histories, a polar, loads and Cp slices; those iterations are not extra independent fit observations. `AEGAreadpanelpolar.m` locates and validates the summary and consistent reference metadata. Replacing this source intentionally and rerunning `AEGAinputs` updates its fit.

See [the input review](../../docs/INPUT_ASSUMPTIONS.md) for the assumed whole-aircraft scope, coefficient pairing and limitations. Source cells are data, not workflow instructions.

## Selected wing airfoil

`ls417mod.dat` was downloaded unchanged on October 12, 2026 from the
[University of Illinois Airfoil Coordinates Database](https://m-selig.ae.illinois.edu/ads/coord/ls417mod.dat).
It contains LS(1)-0417MOD coordinates in Lednicer format: 46 upper-surface
and 47 lower-surface points. Interpolated thickness is approximately 0.1701
at x/c 0.2903, consistent with the team's rounded 17% at 30% chord.

SHA-256: `DC717C3C18E8CB6775BEE148E733F435BD987FE90448B63287C206D5A606DFB6`

The file supplies geometry, not a lift/drag polar. Section maximum lift 2.3
is the team's separate 2D analysis input; see [airfoil configuration](../../docs/AIRFOIL_CONFIGURATION.md).
