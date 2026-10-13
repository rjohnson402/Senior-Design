# Workflow snapshot before consolidation, 2026-10-11

Original MATLAB files and the previous README are preserved byte for byte as
`.m.txt` / `.md.txt`, with SHA-256 hashes in SHA256.json. They cannot shadow the
active functions, even with a recursive MATLAB path. The MAT file captures
pre-refactor AR18, live AR15.5 and legacy regression sizing results.

Current commands are `AEGAsize`, `AEGAconstraint`, and `AEGAtrades` in the
sizing root. Active reusable models are in `private/`; do not add that folder
or this archive to the MATLAB path. Superseded runners, Hub, the older sizing
implementation, duplicate blown-lift helper, old telescoping sweep and old
export refresh scripts are preserved here. The current optimized adaptive
wing comparison, reverse-thrust and input sensitivity models remain active.

Restore by copying a snapshot to a separate working folder and removing the
final `.txt` extension; restore its dependencies together. Do not mix the old
runners into the current root. Existing result packages were not moved.
