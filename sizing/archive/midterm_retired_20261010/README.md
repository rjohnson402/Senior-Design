# Studies retired for the October 13 midterm

These three files were moved on October 10, 2026, without changing their
contents. `MANIFEST.csv` records SHA-256 hashes checked before and after each
move. The `.m.txt` extension prevents accidental execution on MATLAB's path.

| File | Why it is not a main presentation study |
|---|---|
| `AEGAengineout.m.txt` | Holds aircraft weight fixed and compares equal, two-size and graded prop families, including largest-inboard layouts. Its arbitrary two-motor failures differ from the active mirrored battery-bank failure model. It does not establish a minimum-weight design for the selected two-large-outboard-cruise-prop architecture. |
| `run_engineout2035.m.txt` | Runner for that legacy prop-family/failure comparison. |
| `check_engineout_climb.m.txt` | Regression check for that retired model and its old reference aircraft. |

Failure analysis remains important. `AEGAbatteryout.m`, `AEGAtrade_size.m`,
and the active wing/flight-phase checks retain the coupled battery-bank
failure screens. The geometry helpers `AEGAprop.m` and `AEGAtrade_prop.m`
and the blown-lift helper `blow_wind.m` remain active dependencies.

To revisit this historical comparison, copy the files into a separate MATLAB
working folder, restore their `.m` extensions, and provide the original
shared helper functions. Do not interpret their fixed-weight results as
current aircraft sizing.
