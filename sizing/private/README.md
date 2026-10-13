# Active model helpers

MATLAB finds this folder automatically from the public functions in its parent.
Do not add it to the path or launch helpers directly. Use `AEGAsize`,
`AEGAconstraint`, `AEGAtrades`, and `AEGAinputs` from the sizing root.

- Study engines: AEGAwingtrades, AEGAoptimizewings2035, AEGAcruiseproptrades2035.
- Common setup: AEGAstudysettings2035 and AEGAstudycase2035.
- Physics: prop geometry, weights, drag, blown lift, phase/mission energy,
  battery-bank failures, telescoping hardware/geometry and ground roll.
- Supporting studies: reverse thrust and input sensitivities.
- Export/plot helpers and checks.

AEGAprop and AEGAlegacyinputs2035 support historical regression checks; they
are not current design entry points. The shared coupled solver lives in the
public AEGAsize.m and is called by every active study engine.
