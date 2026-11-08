# Xtras merge: what happened to everything unique in the Revised beta

Built by `xtras/apply_merged_uz5.ps1` from the two original archives. Main wins on every conflict, and every Revised
feature that changes how the game plays is either a new option or a new skill, so with default settings the merged pack
plays like Xtras main. `merge_manifest.json` has the per-file inventory; this table is the decision for each group.

Correction to `MERGE_STAGE_B.md`: the first class inventory skipped classes written `Class ...` with a capital C. With
that fixed Main has 145 classes and the Revised beta 102 (72 shared, 30 Revised-only). Most of the 30 are older names of
things Main has under a `Dcx_` prefix (Kick Attack monsters) or consolidated code, as listed below.

| Revised item | Disposition | Where / why |
|---|---|---|
| Total Carnage, Unholy Massacre!, ULTRA NIGHTMARE skills | **ported** | `mapinfo.txt` (after Nightmare, so the standard skills keep their ACS numbers); skill art `M_ULTRP`, `M_UHOLY`, `M_ULTNM` imported |
| ACS monster placements for those skills (Revised `Xtra_Monster_Placements`, skill 5 part) | **ported** | `ACS/XtraHardMode.o` (compiled with ACC from the Revised source by `make_hardmode.py`), loaded by `LOADACS`; a misspelt `Stimpaick` pickup fixed |
| `DCX_LesserCyber`, `DCX_LesserMastermind`, `DCX_NightmareCyberdemon`, `DC_Replacer` | **ported** | `Zscript/Actors/Dcx_HardMode_Actors.zsc`; DoomEdNums 616, 607, 711; sprites `LCYB`, `LSPI` and sounds `DSLCY*`, `DSWID*` imported |
| Thing changes on the hard skills (`DCX_TotalCarnageMonsterPlacementsBackup`, skill-5 block) | **ported** | `Zscript/LevelScripts/Dcx_HardMode_Placements.zsc`. Its Episode 4 changes (applied on every skill) and the Doom 64 placements Main already has were left out |
| `DCX_Multiplayerweaponremoveal` | **ported, off by default** | `Dcx_CoopCleanup.zsc`, option "Co-op item cleanup" (`dcx_CoopWeaponRemoval`). Only touches things flagged co-op-only, so single player cannot change. Not play-tested in a network game |
| `Tnt_Hud_toggle`, `Plu_Hud_toggle` and the TNT / Plutonia / Revilution / Revisited bars, fonts, arms panels | **finished and ported** | The Revised code never used them. `Dcx_Sbar.zsc` now has `FinalHudStyle()`; menu "TNT Evilution / Plutonia Final DOOM hud"; defaults reproduce Main (Plutonia 2) |
| `D64_Hud_toggle` | superseded | Main's `AB_hud_toggle` already offers four Doom 64 skins |
| Freedoom HUD digits (`FDTNUM*`), Plutonia Red digits (`RPTNUM*`), `ARMRTXT`, `HEALTXT` | imported, not used | Art only; nothing in either pack draws them. `FDFONT_SFREEDOOM`, `FDFONT_RPLUTONIA` are defined if a skin is added later |
| `dcx_TextureFixes` | superseded | Main fixes the Icon of Sin face and the E2M4 blood tiles itself (`dcx_TextureEchancements`) |
| `always_pistol_start`, `keep_inventory_items`, `PISTART_*` strings | superseded | Old pistol-start option; WadFusion's own `wf_compat_pistolstart` replaced it. Declared in Revised CVARINFO, never read |
| `DCX_MapFixes`, `DCX_PlaystationSecrets` | superseded | Main's `WadfusionXtras_PostProcessor` does these map fixes |
| Kick Attack / Master Levels actors (`Kick_*`, `BallOSpew`, `LoungeSinger`, `SurferMutant*`, ...) | superseded | Main has them as `Dcx_*` in `Dcx_KickAttack_Actors.zsc` |
| `Hang*NS` non-solid hanging bodies | not ported | Only used by Revised event handler replacements Main does not have; sprites exist in Main already |
| Eight Master Levels maps (Canyon, Hack2, ...) and `E2M5B` | already in Main | Byte-identical to Main's `ML_MAP44`-`51` and `PSX01B` |
| Revised PSX maps (`PSX01`-`08`, `01B`, `02B`) and `thyfleshconsumed_levels_x.txt` | not ported (older editions) | Same maps as Main's with slightly older edits and a different numbering (for example Revised `PSX03` is Main's `PSX04`); Main's versions and its own Episode 4 / PlayStation route stay. Importing them would add a second, older copy of each map |
| Episode 4 intermission art (`WIMAP4`, `WIA40*`, `IN_EP42`) | imported, not used | Belongs to the Revised PSX-in-E4 layout; kept as art so a future route can use it |
| Doom 64 alternate tracks (9 files, `D_ALTPIN`, ...) | imported, not used | Neither pack assigns them to a map |
| `d2spfx20.wad`, `misctextures.wad` | archived under `Revised_Archive/` | Root-level WADs are not loaded from inside a pack |
| MOTH sprite frames | not imported | Main stores the Mother Demon frames as mirrored pairs (`MOTHB1C1`); importing the Revised single frames would give duplicate frames |
| `BSP2`, `TSTR` sprites | imported, unused | Used only by Revised variants of classes Main defines differently |
| Revised-only LANGUAGE keys (TNT/Plutonia music names, pistol start, one level name) | not merged | Nothing in the merged pack reads them |
| Revised MAPINFO (old WF_NEWGAME-less episode and map definitions) | not merged | Main's are adapted to the current WadFusion; Revised's would redefine them |
