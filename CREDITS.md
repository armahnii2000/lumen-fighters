# Credits & Asset Licenses

## Code
The game code is **MIT** licensed — see [LICENSE](LICENSE).

## Character sprites — Kung Fu Man (KFM)
The in-game character is **Kung Fu Man**, the sample character created by **Elecbyte**
and bundled with the **M.U.G.E.N** engine. The sprites were extracted from the KFM
`.sff` file and re-composed into per-animation frames.

- **License:** Creative Commons **Attribution-NonCommercial (CC BY-NC)**.
- This is a **non-commercial learning / portfolio** project, and the KFM sprites are
  used under that license with attribution to Elecbyte.
- ⚠️ **Because of the CC BY-NC license, this build must NOT be sold or used
  commercially with these sprites.** To make the game commercial, swap them for your
  own art or a CC0 / commercially-licensed pack — the engine keeps art and logic fully
  separate (`assets/kfm/` + `core/kfm_frames.gd`), so it's a drop-in replacement that
  won't touch the gameplay code or break the tests.

## Test framework
**gdUnit4** by Mike Schulze (MIT license), bundled in `addons/gdUnit4/`.
