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
  Also silenced the `ACS: 'H2P_RocketLauncher': Unknown actor class.` spam: the pack's `WeaponManagement` ACS script
  touched weapons that only exist in the Unofficial addon, so it now asks `DCX_Util.OEWeaponsLoaded()` (new ZScript
  helper, via `ScriptCall`) and skips them when the addon isn't loaded. Recompiled with ACC; the unmodified source
  compiles byte-identical to the shipped `.o`, so nothing else changed.
  Tested: loads with no script errors; the hack maps hand over to the right maps (PSX02, PSX02B, E3M1,
  JA_MAP01, AB_MAP12, TN_MAP21).

- **LZDoom works too** (tested on LZDoom l4.14.4): the current build, both Xtras packs and the Unofficial addon
  load with no errors, the ID24 monsters and decorations spawn (LZDoom ships them too), the Legacy of Rust Tyrant
  boss actors exist, and the PlayStation E3M1 swap works. Upstream already documents "UZDoom or LZDoom" and
  its 1.6.1 changelog adds LZDoom 4.14.3a support. The old v1.5.1 ipk3 fails on LZDoom with the same
  "Class name ... already exists" errors it gives on UZDoom 5, so rebuilding is the fix there as well.
  Not tested: LZDoom 4.14.3a itself, or anything older, and actual play on a low-end machine.

- **Xtras episodes in the Full Run chain.** After WadFusion's last episode (in all three orders) the Full Run
  continues with Jaguar, then Absolution; with "Full Run loop" on it then wraps back to the first episode.
  Cast calls (`Jaguar_Cast`, `D64Inter_Cast`) play when "Show cast call" is on. Also fixed the Jaguar ending,
  which pointed at a non-existent intermission name. Implementation notes: `DCX_StaticHandler` is a separate
  handler that runs next to WadFusion's (`Replaces` does not remove the original), after it on each tick, so it
  adjusts WadFusion's `nextMap` instead of racing it; the Xtras ending uses its own hand-over map
  `DCX_HANDOVER` (a copy of a WadFusion hack map) that WadFusion's handler ignores.
  Tested on UZDoom 5.0.3 and LZDoom l4.14.4 with an auto-exit test pack: Jaguar→Absolution, Absolution→loop,
  chain end, PL_MAP30→Jaguar (order 1, with and without loop), LR_MAP14→Jaguar (order 2), E2M8→PSX02/PSX02B.

## Known issues (Xtras-main)
- Not play-tested end to end: title-screen input flow, E4/PSX ending maps (`e4ending`), cast sequences.

## Planned
(nothing queued)

## Xtras Revised beta — what had to change for UZDoom 5
Pack: `Wadfusion-Xtras-Revised_beta.pk3`. All edits are renames or deletions:
| File | Change |
|------|--------|
| `mapinfo/id1_levels_X.txt` | delete `compat_nombf21 = 0` |
| `Zscript/dcx_sbar.zsc` | `Fuel`→`ID24Fuel`, `Incinerator`→`ID24Incinerator`, `Heatwave`→`ID24CalamityBlade`; cvars `wf_id1_weapswap`→`wf_compat_id24_weapons` |
| `Zscript/Weapons.zsc` | `Incinerator`→`ID24Incinerator`, `CalamityBlade`→`ID24CalamityBlade` |
| `Zscript/EventHandlers.zsc` | cvar `wf_hulshult_idkfa`→`wf_mus_idkfa` |
