# Retired sizing files

Archived on 2026-10-05. File contents were preserved byte for byte; only their
locations and extensions changed. `.m.txt` keeps them off MATLAB's function
path, including when the sizing directory is added recursively.

| File | Reason |
|---|---|
| `propeller_studies/blown_sweep.m.txt` | Retired prop count/disk-area, diameter-distribution, taper/inboard-bias and optional free-diameter sweeps. These focus on blown CL and normalized spanwise thrust moment rather than coupled aircraft sizing. Includes the preexisting plot edits. |
| `propeller_studies/AEGAengineout_trade.m.txt` | Retired fixed-weight diameter-ratio trade. Its original source contains a duplicated function declaration and a syntax error; retained as history, not a runnable study. |
| `unused/check_engineout2035.m.txt` | Exact duplicate of the now-retired `check_engineout_climb.m`; also declared the same function name despite having a different filename. |
| `unused/pick.m.txt` | No callers found in the sizing source. Active weight code uses its own local `state` helper. |

The remaining legacy fixed-weight prop-family comparison was retired on
2026-10-10 into [midterm_retired_20261010](midterm_retired_20261010/README.md),
including `run_engineout2035.m`, `AEGAengineout.m`, and its regression check.
The active battery-bank failure model is `AEGAbatteryout.m`; failure constraints
remain included in the coupled sizing studies.

The old `thrust_moment_norm` output is a normalized spanwise thrust-location
proxy. It is not a pitching-moment coefficient or a structural bending-load
solution. The user's reason for retiring the propeller coefficient/moment
studies was their small observed changes; those old sweeps were not re-run
during this cleanup.


The October 11 workflow consolidation is in [workflow_before_20261011](workflow_before_20261011/README.md). Public commands are now AEGAsize, AEGAconstraint and AEGAtrades. Active dependencies live in private/.
