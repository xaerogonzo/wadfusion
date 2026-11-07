# Fork roadmap

This fork tracks [Owlet7/wadfusion](https://github.com/Owlet7/wadfusion) and targets **UZDoom 5.x**.
Tested: UZDoom 5.0.3, WadFusion 1.6.2-dev (upstream `2e95646`).

## Done
- Verified a clean build from upstream source loads in UZDoom 5.0.3 with no script or MAPINFO errors.
  The failure that started this fork came from a stale v1.5.1 `doom_fusion.ipk3`, which still bundled its
  own ID24 actors (now built into UZDoom 5) and used the removed `compat_nombf21` MAPINFO property.
- Patch mode (`-p`) now removes stale files from `zscript/` and `mapinfo/` that are no longer part of
  WadFusion, and no longer appends duplicate `#include` lines to `textures.txt` on repeated runs.
- `build_release.ps1`: builds `wadfusion.exe` and the release zips with only PowerShell + Python
  (no 7-Zip needed).

## Planned
1. **LZDoom support.** Goal: a build that runs on low-end machines where UZDoom is slow.
   - Find out what LZDoom lacks: ID24 actors (UZDoom 5 has them built in), ZScript version, MAPINFO properties.
   - Likely shape: a build option that bundles the ID24 actors again (upstream's 4.14.3 alternate build
     does the same) and keeps Fusion's scripts independent of how the actors are provided.
   - Test on LZDoom and UZDoom separately; don't claim support for one from testing the other.
2. **Port the "Wadfusion-Xtras" pack** (`Wadfusion-Xtras-main`, plus the Unofficial Xtras addon that needs it).
   It replaces `WadFusionStaticHandler` and calls functions from WadFusion 1.5.x (`FullRunEnd`, `FullRunStory`,
   `FullRunMultiplayer`, `PlaySigilIntroMusic`, ...) that no longer exist. Also has `compat_nombf21`.
3. **Clearer "Full Run" menu wording.** The options (`Full Run`, `Master Levels in Full Run`,
   `End cast sequences in Full Run`, `Full Run loop`) aren't self-explanatory. Add short descriptions.

## Xtras Revised beta — what had to change for UZDoom 5
Pack: `Wadfusion-Xtras-Revised_beta.pk3`. All edits are renames or deletions:
| File | Change |
|------|--------|
| `mapinfo/id1_levels_X.txt` | delete `compat_nombf21 = 0` |
| `Zscript/dcx_sbar.zsc` | `Fuel`→`ID24Fuel`, `Incinerator`→`ID24Incinerator`, `Heatwave`→`ID24CalamityBlade`; cvars `wf_id1_weapswap`→`wf_compat_id24_weapons` |
| `Zscript/Weapons.zsc` | `Incinerator`→`ID24Incinerator`, `CalamityBlade`→`ID24CalamityBlade` |
| `Zscript/EventHandlers.zsc` | cvar `wf_hulshult_idkfa`→`wf_mus_idkfa` |
