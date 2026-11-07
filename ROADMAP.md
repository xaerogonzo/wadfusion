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

- **Wadfusion-Xtras-main ported to UZDoom 5** (and the Unofficial Xtras addon on top of it loads too).
  `xtras/apply_main_uz5.ps1` builds a working copy from your original zip; the changed files are in
  `xtras/Wadfusion-Xtras-main_uz5/`. The pack was written against a development build of WadFusion
  (between 1.5.1 and 1.6.0), so its handler was rewritten as a small subclass of `WadFusionStaticHandler`
  that adds only what Xtras needs: the PlayStation E3M1 maps (`dcx_playstationmaps`) and title screens/music
  for the Jaguar, Absolution and Doom II / TNT / Plutonia part 2 and 3 hack maps.
  Tested: loads with no script errors; the hack maps hand over to the right maps (PSX02, PSX02B, E3M1,
  JA_MAP01, AB_MAP12, TN_MAP21).

## Known issues (Xtras-main)
- Console/screen spam `ACS: 'H2P_RocketLauncher': Unknown actor class.` (and similar). Comes from the pack's
  compiled ACS (`XtraMisc`), which probes for weapons from other mods and prints when they aren't loaded.
  Not caused by the port. Possible fix: recompile the ACS without those checks, or define stub classes.
- Full Run only covers WadFusion's own episodes; the Xtras episodes aren't in the Full Run chain.
- Not play-tested end to end: title-screen input flow, E4/PSX ending maps (`e4ending`), cast sequences.

## Planned
1. **LZDoom support.** Goal: a build that runs on low-end machines where UZDoom is slow.
   - Find out what LZDoom lacks: ID24 actors (UZDoom 5 has them built in), ZScript version, MAPINFO properties.
   - Likely shape: a build option that bundles the ID24 actors again (upstream's 4.14.3 alternate build
     does the same) and keeps Fusion's scripts independent of how the actors are provided.
   - Test on LZDoom and UZDoom separately; don't claim support for one from testing the other.
2. **Clearer "Full Run" menu wording.** The options (`Full Run`, `Master Levels in Full Run`,
   `End cast sequences in Full Run`, `Full Run loop`) aren't self-explanatory. Add short descriptions.

## Xtras Revised beta — what had to change for UZDoom 5
Pack: `Wadfusion-Xtras-Revised_beta.pk3`. All edits are renames or deletions:
| File | Change |
|------|--------|
| `mapinfo/id1_levels_X.txt` | delete `compat_nombf21 = 0` |
| `Zscript/dcx_sbar.zsc` | `Fuel`→`ID24Fuel`, `Incinerator`→`ID24Incinerator`, `Heatwave`→`ID24CalamityBlade`; cvars `wf_id1_weapswap`→`wf_compat_id24_weapons` |
| `Zscript/Weapons.zsc` | `Incinerator`→`ID24Incinerator`, `CalamityBlade`→`ID24CalamityBlade` |
| `Zscript/EventHandlers.zsc` | cvar `wf_hulshult_idkfa`→`wf_mus_idkfa` |
