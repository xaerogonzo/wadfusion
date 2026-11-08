# WadMelt — UZDoom 5 / LZDoom fork

**WadMelt merges your DOOM, DOOM II, Final DOOM and re-release data into one IPK3 for [UZDoom](https://zdoom.org/downloads) or LZDoom, with every game and expansion as its own entry in the episode list.**

WadMelt is a fork of [WadFusion by Owlet7](https://github.com/Owlet7/wadfusion) (GPL-3.0), which is itself based on [WadSmoosh](https://jp.itch.io/wadsmoosh) by JP LeBreton. All the original work and credit stay with them. This fork is **not** the official WadFusion and is not endorsed by its author; it was renamed from "WadFusion UZDoom 5 fork" to avoid confusion with upstream's own releases. Current version: **2.0.0**, built on upstream commit `2e95646`, tested on **UZDoom 5.0.3** and **LZDoom l4.14.4**. Internal names (the `wf_` console variables, `WFRUN` files, `wadfusion.exe`, `WadFusion Menu.bat`) are unchanged so existing settings and add-ons keep working.

> [!NOTE]
> Upstream's 1.6.1 release builds an IPK3 for UZDoom 4.14. On UZDoom 5 it fails with "Class name already exists" and `compat_nombf21` errors, because UZDoom 5 now contains the ID24 actors itself. Building from this fork fixes that.

## What this fork adds

- **Works on UZDoom 5 and LZDoom.** A clean build loads with no script or MAPINFO errors on both. Patch mode (`-p`) now removes stale files left by older builds.
- **One Full Run router with a campaign catalog.** The three built-in orders behave exactly as before (checked against 96 recorded cases). New: a **Custom** order with 16 slots and a menu to set it, and outside campaigns (for example *Back to Saturn X*) described by a small `WFRUN` text file. See [Custom Full Run](#custom-full-run).
- **Outside-mod awareness.** At start-up WadMelt reports when another file replaces one of its maps or ships its own texture tables, and an outside campaign keeps its own ending and music.
- **A pre-flight check for your source WADs.** `WadFusion Menu.bat` (and `wadfusion --check` / `--scan`) shows which WADs were found, what each unlocks and which episodes the build would contain, before anything is built. See [Checking your WADs](#checking-your-wads-before-you-build).
- **Original Wolfenstein textures.** With the original `doom2_original.wad` (DOOM II v1.9) the uncensored textures are used; the censored ones are an option.
- **Master Levels:** with both `masterlevels.wad` and the 20 individual WADs present, the individual ones are used (the bundle lacks three sky patches).
- **One Xtras pack.** `xtras/` rebuilds a single pack from the two original Xtras releases ([details below](#xtras-packs)).
- **A release script** (`build_release.ps1`, no 7-Zip needed) and a **test harness** (`tests/`) that plays campaign hand-overs by script on both engines.

See [CHANGES.md](CHANGES.md) for the full list and [ROADMAP.md](ROADMAP.md) for what was tested and what is planned.

## Quick start

1. Download **`wadfusion_win.zip`** (Windows, includes `wadfusion.exe`) or **`wadfusion_py.zip`** (needs Python 3; also for macOS and Linux) from the [latest release](https://github.com/xaerogonzo/wadmelt/releases/latest), and extract it. The download contains no game data; you supply your own WADs.
2. Copy your WAD files into `source_wads\`, or leave them where they are and add that folder from the menu. WADs are recognised by file name; case does not matter.
3. Run `WadFusion Menu.bat`, choose **1** to see what was found, then **2** to build. You get `doom_fusion.ipk3` (about 436 MB with everything).
4. Start the game with the IPK3 as the IWAD. The widescreen graphics pack is optional; `build_release.ps1` creates it from `ultrawiderpix\`, and the release zips contain it:

```
uzdoom.exe -iwad doom_fusion.ipk3 -file doom_fusion_widescreen_gfx.pk3
```

For the WAD list, versions and file names see [Supported WADs](#supported-wads). If you have never done this before, read the [Absolute Beginner's Guide](#absolute-beginners-guide).

## Complete setup: everything, including the merged Xtras

A full install is **several files that you load together**, not one. The IPK3 is the game itself, built on your PC from your own WADs; the Xtras are add-ons that the engine loads on top of it.

| File | What it is | Where it comes from | Needed? |
|---|---|---|---|
| `doom_fusion.ipk3` | Every game and expansion you own, as one episode list, plus the Full Run, custom runs and menus | You build it: `WadFusion Menu.bat`, option 2 | Yes |
| `doom_fusion_widescreen_gfx.pk3` | Ultra-widescreen HUD and title graphics | Inside the release zip | Optional |
| `Wadfusion-Xtras-Merged_UZ5.pk3` | Jaguar Doom, PlayStation levels, Doom 64: Absolution, the Total Carnage / Unholy Massacre / ULTRA NIGHTMARE skills, extra music and HUD skins | You build it: `WadFusion Menu.bat`, option 9 | Optional |
| `WadFusion-Unofficial-Xtras-main_UZ5.pk3` | Doom Zero, Freedoom 1 and 2, Hell to Pay, Perdition's Gate, Plutonia 2, TNT: Revilution and more | Built by the same option 9 | Optional, needs the merged Xtras |

The Xtras are not bundled because they are other people's work; option 9 downloads them straight from their authors' GitHub pages and builds the packs on your machine.

1. **Get the tool.** Download `wadfusion_win.zip` from the [latest release](https://github.com/xaerogonzo/wadmelt/releases/latest) and extract it. (macOS and Linux: `wadfusion_py.zip`, which needs Python 3.)
2. **Add your WADs.** Copy them into `source_wads\`, or run `WadFusion Menu.bat` and use option 4 to find them on your PC and option 3 to add their folder. Option 1 then shows what was found and which episodes you will get. More WADs, more episodes; the list of names is under [Supported WADs](#supported-wads).
3. **Build the IPK3** with option 2 (about a minute). You now have `doom_fusion.ipk3`.
4. **Build the Xtras (optional)** with option 9. It needs [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows) (`winget install Microsoft.PowerShell`), downloads about 440 MB and creates the two Xtras packs next to the menu. When it is done you can delete the `xtras_downloads` folder.
5. **Install an engine:** [UZDoom](https://zdoom.org/downloads) 5.0.3 or LZDoom l4.14.4.
6. **Start it** with all the files, in this order:

```
uzdoom.exe -iwad doom_fusion.ipk3 -file doom_fusion_widescreen_gfx.pk3 Wadfusion-Xtras-Merged_UZ5.pk3 WadFusion-Unofficial-Xtras-main_UZ5.pk3
```

In a launcher such as Doom Runner, choose `doom_fusion.ipk3` as the game (IWAD) and add the other three as files, in that order. Leave out any you don't want; the game works with just the IPK3.

7. **Turn on the extras in the game.** Options, WadMelt Options: set **Full Run** (three built-in orders, or **On (custom order)** and open **Custom Full Run** to pick up to 16 campaigns, including the Xtras ones). The Xtras' own settings (PlayStation levels, Final DOOM HUD skins, skills) are under Options, DCX Options. The extra skills appear in the skill menu when you start a new game.

**Optional files that unlock more:** `doom2_original.wad` (the original DOOM II v1.9, for the uncensored Wolfenstein textures), the soundtrack WADs `sigil_shreds.wad` and `sigil2_mp3.wad`, and your own campaigns through [WFRUN files](#adding-outside-campaigns-wfrun-files).

## Xtras packs

The community **WadFusion Xtras** packs by Someguyman add the console maps (Jaguar Doom, PlayStation levels, Doom 64: Absolution), extra music and graphics, and the unofficial campaigns. They are other people's work, have no published licence, and are **not included in this repository or in the releases**. Instead, `xtras/` holds PowerShell scripts that take the original download and apply this fork's changes (UZDoom 5 fixes, Full Run files, merged features) to a copy. The originals are never modified.

**The easy way:** `WadFusion Menu.bat`, option 9, or `pwsh -File xtras\get_xtras.ps1`, downloads the right versions and builds both packs for you (see [Complete setup](#complete-setup-everything-including-the-merged-xtras)). The rest of this section is what that does, for anyone who prefers to do it by hand.

**Step 1: download exactly these versions** (the scripts refuse any other, because the patches replace whole files of those versions; commits newer than these have not been ported yet):

| Pack | Download (pinned commit) |
|---|---|
| Xtras main | [`54be31c`](https://github.com/Someguyman/Wadfusion-Xtras/archive/54be31c11659e209da0aa446dba82f6758691d00.zip) |
| Xtras Revised beta | [`42d2c95`](https://github.com/Someguyman/Wadfusion-Xtras/archive/42d2c95ad6ef28e637461f792a0ec4083fd194d5.zip) (the `Revised_beta` branch) |
| Unofficial Xtras (optional) | [`d28ae24`](https://github.com/Someguyman/WadFusion-Unoffical-Xtras/archive/d28ae2423bd525bd04dcd2275f675240f80a138d.zip) |

**Step 2: run the scripts** (PowerShell 7) from a clone or download of this repository:

```
.\xtras\apply_merged_uz5.ps1 -Main <xtras main zip> -Revised <revised beta zip> -Out Wadfusion-Xtras-Merged_UZ5.pk3
.\xtras\apply_unofficial_uz5.ps1 -Zip <unofficial zip> -Out WadFusion-Unofficial-Xtras-main_UZ5.pk3
```

| Script | Result |
|---|---|
| `apply_merged_uz5.ps1` | **One** pack from Xtras main and the Revised beta, with the UZDoom 5 fixes, Jaguar and Absolution in the Full Run, the Total Carnage / Unholy Massacre / ULTRA NIGHTMARE skills with their monsters, Final DOOM HUD skins for TNT and Plutonia (menu options), and a co-op item cleanup option. A build record (`.build.json`) is written next to it. |
| `apply_unofficial_uz5.ps1` | Adds a `WFRUN` file so Doom Zero, Evil Unleashed, Freedoom 1 and 2, Hell to Pay, Perdition's Gate, Plutonia 2 and TNT: Revilution can be put in a Custom Full Run. |

`xtras/MERGE_DISPOSITION.md` records what happened to every item of the Revised beta (ported, superseded, left out, and why). Load the merged pack **instead of** the two originals, then the Unofficial pack if you want it:

```
uzdoom.exe -iwad doom_fusion.ipk3 -file doom_fusion_widescreen_gfx.pk3 Wadfusion-Xtras-Merged_UZ5.pk3 WadFusion-Unofficial-Xtras-main_UZ5.pk3
```

## Known limits

- **Outside mods change the look of everything while loaded.** A mod that ships its own palette, `TEXTURE1`/`PNAMES`, flats, sprites or menu art (Back to Saturn X does) replaces same-named resources for the whole session, so DOOM and Plutonia look different too. The mod is loaded when the game starts, so Full Run order cannot help. WadMelt detects and reports this but cannot undo it yet; a per-map fix is on the [roadmap](ROADMAP.md).
- A campaign that another mod replaces keeps its menu name ("Hell on Earth" starts Back to Saturn X).
- The Custom Full Run and the Xtras packs were tested by script (map exits and hand-overs) and by loading each pack, not by playing every campaign through.
- Tested on Windows with UZDoom 5.0.3 and LZDoom l4.14.4 only.

## Building the release files

On Windows, `build_release.ps1` builds `wadfusion.exe` and the two zips (`wadfusion_win.zip`, `wadfusion_py.zip`) with PowerShell and Python only:

```
python -m venv .venv-build
.venv-build\Scripts\python -m pip install pyinstaller
.\build_release.ps1 -Python .venv-build\Scripts\python.exe
```

`windows_build.bat` is the original upstream script and needs 7-Zip. The tests in `tests/` need an engine and a built IPK3; see `tests/fullrun_matrix.ps1`.

---

# Reference (from upstream, updated for this fork)

## What WadMelt does

WadMelt merges your provided DOOM, DOOM II, and Final DOOM data into a single IPK3 file that can be played in [ZDoom](https://zdoom.org/index), with each game as its own entry in the episode list. This makes it very convenient to play all of classic DOOM's official releases without re-launching the game with different settings.

It's fine if you don't have all of the DOOM games, e.g. you have DOOM II but not Final DOOM—WadMelt will package up everything it can find.

If you just bought these games from [GOG](https://www.gog.com/en/game/doom_doom_ii), or [Steam](https://store.steampowered.com/app/2280/), etc., and you aren't familiar with ZDoom and DOOM modding, see the [**Absolute Beginner's Guide**](#absolute-beginners-guide) section below.

> [!NOTE]
> WadMelt requires UZDoom or LZDoom. It will not work with other engines.

## Usage

Simply copy all of your WADs into the `source_wads` subfolder, then run WadMelt. A log will appear showing progress and any errors that arise. A new file called `doom_fusion.ipk3` will be created, with all the game content in it. It should be selectable in ZDoom as "DOOM Fusion".

Also included is a file called `doom_fusion_widescreen_gfx.pk3`, which adds super-ultra-widescreen assets courtesy of the [Ultra-Widerpix854 project](https://www.doomworld.com/forum/topic/148537). DOOM Fusion will load it automatically if it's placed in the same directory as the IPK3. ZDoom's own widescreen assets are disabled in Fusion. (It's worth noting that the full Ultra-Widerpix854 project has some extra features not included with WadMelt, such as alternate versions for some graphics, extended sky textures, and support for other DOOM-based games.)

### Checking your WADs before you build
Run `WadFusion Menu.bat` (it sits next to `wadfusion.exe`). Option 1 lists every source WAD it found, what each one
unlocks, which Master Levels files are missing and which episodes the build would contain, before anything is built. Option 4
searches a folder tree (for example `D:\Games`) for usable WADs and flags names that exist in more than one version, and
option 3 adds a folder to the search list, so you don't have to copy WADs around. The same checks are available on the
command line as `wadfusion --check` and `wadfusion --scan <folder>`.

## Options

WadMelt can be launched with the following command line arguments:

- `-h`, `--help` — Show the help message and exit.
- `--version` —  Show program's version number and exit.
- `-v`, `--verbose` — Print out all the logged information.
- `-w PATH`, `--wads PATH` — Search the specified directory path for WADs. Can be used multiple times.
- `-p`, `--patch` — Patch an existing IPK3 without extracting WADs.
- `-d`, `--deflate` — Use DEFLATE compression when generating the IPK3.
- `-c`, `--check` — List which source WADs were found and what they unlock, then exit without building (exit code 1 if no main game was found).
- `--scan PATH` — Search a folder and everything below it for source WADs WadMelt can use, then exit.
- `-e`, `--extract-only` — Skip copying pre-authored lumps and only extract WADs (for developers).

## Supported WADs

WadMelt is not a general-purpose tool for merging DOOM WADs; it is for merging *official content only*—it was created out of a desire for a "complete" version of retail DOOM and DOOM II. Please do not ask if WadMelt will support any specific WAD. This includes any content from the 5th generation console ports. If you want to add your own content to a custom IPK3, either modify WadMelt's code yourself, or simply edit the IPK3 that WadMelt generates. Please try consulting the [ZDoom Wiki](https://zdoom.org/wiki/Main_Page) first before asking for help. If you've created an addon for WadMelt, feel free to share it with the community on the [Discussions](https://github.com/Owlet7/wadfusion/discussions/categories/show-and-tell) section.

Here is the official list of WADs that WadMelt will recognize:
- DOOM (original registered version of `doom.wad`, containing only episodes 1-3)
- The Ultimate DOOM (retail version of `doom.wad` or `doomu.wad`, containing episodes 1-4)
- DOOM II (`doom2.wad`)
- Master Levels for DOOM II (the original 20 WAD files, or `masterlevels.wad` from the [KEX-based re-release](https://doomwiki.org/wiki/Doom_%2B_Doom_II))
- Master Levels Rejects ([see below](#master-levels-rejects) for a full list of supported WADs)
- Final DOOM (`tnt.wad` and `plutonia.wad`)
- No Rest for the Living (`nerve.wad`)
- SIGIL (`sigil.wad` and optionally its MP3 soundtrack version)
- SIGIL II (`sigil2.wad` and optionally its MP3 soundtrack version)
- Legacy of Rust (`id1.wad` and `iddm1.wad` from the [KEX-based re-release](https://doomwiki.org/wiki/Doom_%2B_Doom_II))
- Xbox secret levels (`sewers.wad` and `betray.wad` from the [original Xbox port of DOOM](https://doomwiki.org/wiki/Xbox))
- Tech Gone Bad and Phobos Mission Control (`e1m8b.wad` and `e1m4b.wad`, John Romero's map remakes)
- Extras (`extras.wad` from the [Unity](https://doomwiki.org/wiki/Doom_Classic_Unity_port) or [KEX-based](https://doomwiki.org/wiki/Doom_%2B_Doom_II) re-releases)
- Optional: the original, uncensored DOOM II v1.9 as `doom2_original.wad`. The DOOM II sold today has the swastikas in the Wolfenstein secret levels (MAP31 and MAP32) replaced with a different symbol. If this file is present, only its Wolfenstein textures are copied into the IPK3, and they are used by default; turn on "Censored Wolfenstein textures" in the WadMelt options menu to go back to the modern ones. `doom2.wad` is still needed, and the original WAD is not included with WadMelt. The original is the 14,604,584-byte `DOOM2.WAD` (MD5 `25e1459ca71d321525f84628f45ca8cd`).

If IWADs from the Unity or KEX-based re-releases are also included (must be named `doomunity.wad`, `doom2unity.wad`, `tntunity.wad`, `plutoniaunity.wad` or `doomkex.wad`, `doom2kex.wad`, `tntkex.wad`, `plutoniakex.wad`), WadMelt will extract the official widescreen assets from them. These versions can also be used as the main IWADs for extraction, but do keep in mind that they are censored, and that WadMelt already comes with optional super-ultrawide assets.

If `extras.wad` from the re-releases is included, WadMelt will extract the official "secret revealed" sound, and some status bar icons that can be used by the custom alternate fullscreen HUD. If the version from the KEX-based re-release is used, WadMelt will also extract Andrew Hulshult's "IDKFA" covers of the DOOM and DOOM II soundtracks, which can be toggled from the WadMelt options menu.

None of the "official add-on" content from the Unity or KEX-based re-releases of DOOM and DOOM II is supported.

For SIGIL and SIGIL II, all the filenames for different releases of those WADs are also recognized; you shouldn't have to rename your original files. If the registered versions of SIGIL or SIGIL II are included, WadMelt will extract both MIDI and MP3 soundtracks from them, which can be toggled from the WadMelt options menu. The MP3 versions aren't supported on their own, the MIDI versions must be included alongside them.

[Tech Gone Bad](https://doomwiki.org/wiki/Tech_Gone_Bad) and [Phobos Mission Control](https://doomwiki.org/wiki/Phobos_Mission_Control) are levels that were made as a warm-up exercise for John Romero's cancelled game, Blackroom. If they're included, enabling them in the WadMelt options menu will replace E1M8 or E1M4 in the Knee-Deep in the Dead episode.

## Recommended WADs

WadMelt will work with most versions of the supported WADs, but in order to generate a "best" version of `doom_fusion.ipk3`, it is recommended to use the following versions ([Master Levels Rejects](#master-levels-rejects) listed separately):

| WAD                       | WAD filename            | MD5 hash code                      | Where to get                                                                                                                     |
| :------------------------ | :---------------------- | :--------------------------------- | :------------------------------------------------------------------------------------------------------------------------------- |
| DOOM                      | `DOOM.WAD`              | `1cd63c5ddff1bf8ce844237f580e9cf3` | Mail order from id Software in 1993                                                                                              |
| The Ultimate DOOM         | `DOOM.WAD`              | `c4fe9fd920207691a9f493668e0a2083` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (DOS) (rename to `DOOMU.WAD`) |
| DOOM II                   | `DOOM2.WAD`             | `25e1459ca71d321525f84628f45ca8cd` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (DOS)                         |
| TNT: Evilution            | `TNT.WAD`               | `4e158d9953c79ccf97bd0663244cc6b6` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (DOS)                         |
| The Plutonia Experiment   | `PLUTONIA.WAD`          | `75c8cf89566741fa9d22447604053bd7` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (DOS)                         |
| Master Levels for DOOM II | `masterlevels.wad`      | `ab3ce78e085e50a61f6dff46aabbfaeb` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (KEX)                         |
| No Rest for the Living    | `nerve.wad`             | `23422eb42833ac7b0dd59c0c7ae18a6f` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (KEX)                         |
| SIGIL                     | `sigil.wad`             | `08ee05388c137db5f5d7996e89425b95` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (KEX)                         |
| SIGIL II                  | `sigil2.wad`            | `953f65cf079d0ba9a25be2c407da7ec1` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (KEX)                         |
| Legacy of Rust            | `id1.wad`               | `713c5a3c1734b1d55b2813a3dd0136d9` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (KEX)                         |
| id Deathmatch Pack #1     | `iddm1.wad`             | `cb92010b8ec05f8924ac966a8ed95b74` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (KEX)                         |
| DOOM + DOOM II Extras     | `extras.wad`            | `2e76d93d52ef64fb9db3cee2437c686b` | [GOG](https://www.gog.com/en/game/doom_doom_ii) / [Steam](https://store.steampowered.com/app/2280) (KEX)                         |
| SIGIL + Buckethead        | `SIGIL_V1_23_REG.wad`   | `25c5835ec5352c9587440b7403ff6e8f` | [The Romero Shop](https://romero.com/sigil)                                                                                      |
| SIGIL II + THORR          | `SIGIL_II_MP3_V1_0.WAD` | `732fb8f9c470e857189c206a9279af74` | [The Romero Shop](https://romero.com/sigil)                                                                                      |
| Tech Gone Bad             | `e1m8b.wad`             | `86e94729257b94f982dbe3e3a81e2679` | [/idgames archive](https://www.doomworld.com/idgames/levels/doom/Ports/d-f/e1m8b)                                                |
| Phobos Mission Control    | `e1m4b.wad`             | `ffce7f3a2e42ba779e211c4cf17fa591` | [/idgames archive](https://www.doomworld.com/idgames/levels/doom/Ports/d-f/e1m4b)                                                |
| Sewers                    | `SEWERS.WAD`            | `7b30cba8c9a79405a7240fd68eb013a5` | [ClassicDoom.com](https://classicdoom.com/xboxspec.htm)                                                                          |
| Betray                    | `BETRAY.WAD`            | `2bb99c282627b58ef3c753a9544255b9` | [ClassicDoom.com](https://classicdoom.com/xboxspec.htm)                                                                          |

## Master Levels Rejects

The WadMelt options menu has an option to switch the Master Levels between the official 21 map order as arranged by Xaser, and the expanded 43 map order that incorporates the rejected and related bonus maps, and arranges them into sub-episode campaigns.

To integrate the Master Levels Rejects, you must include The Ultimate DOOM, DOOM II, Master Levels for DOOM II (either the original 20 WAD files, or preferably `masterlevels.wad` from the KEX-based re-release), and *all* of the following WADs:

| Link to WAD                                                                              | WAD file                | MD5 hash code                      |
| :--------------------------------------------------------------------------------------- | :---------------------- | :--------------------------------- |
| [The C.P.U.](https://www.doomworld.com/idgames/levels/doom2/a-c/cpu)                     | `cpu.wad`               | `b346e39e3a3f60f9f6b09a3c68c00764` |
| [Device One](https://www.doomworld.com/idgames/levels/doom2/d-f/device_1)                | `device_1.wad`          | `7a377bf109886caaea83c5786ae1f711` |
| [The D.M.Z.](https://www.doomworld.com/idgames/levels/doom2/d-f/dmz)                     | `dmz.wad`               | `ebc27a4459c932067a80b0ec01dcf122` |
| [The Fury](https://www.doomworld.com/idgames/levels/doom2/a-c/cdk_fury)                  | `cdk_fury.wad`          | `149a79c153d7031f685b83d4d7379385` |
| [The Enemy Inside](https://www.doomworld.com/idgames/levels/doom2/d-f/e_inside)          | `e_inside.wad`          | `185fea1f3ce7224c83620d29f6b36fd3` |
| [The Hive](https://www.doomworld.com/idgames/levels/doom2/g-i/hive)                      | `hive.wad`              | `4cb405b9ae5bb04fd80dfc81ecb9960a` |
| [Doom2 Map14 Homage](https://www.doomworld.com/idgames/levels/doom2/s-u/twm01)           | `TWM01.WAD`             | `f9134bb5449bc17a2c37cb207281cd95` |
| [Mines of Titan](https://www.doomworld.com/idgames/levels/doom2/m-o/mines2)              | `MINES.WAD`             | `b4e975d9a824759a45302ad3d3894dcc` |
| [The Titan Anomaly](https://www.doomworld.com/idgames/levels/doom2/a-c/anomaly)          | `anomaly.wad`           | `00a605251b95e4a4853d09cfbc151399` |
| [The Farside of Titan](https://www.doomworld.com/idgames/levels/doom2/d-f/farside)       | `FARSIDE.WAD`           | `857933d2018470d49a15381f34c124b6` |
| [Trouble on Titan](https://www.doomworld.com/idgames/levels/doom2/s-u/trouble)           | `TROUBLE.WAD`           | `ee7a0adf490b495de1a4ad8388dbe3c6` |
| [Dante's Gate](https://www.doomworld.com/idgames/levels/doom2/d-f/dante25)               | `DANTE25.WAD`           | `bb8269f8ec1fe408ef946e48b2b185d1` |
| [Crossing Acheron](https://www.doomworld.com/idgames/levels/doom2/a-c/achron22)          | `ACHRON22.WAD`          | `58fdafefd08cb2e1841aa49052ff78bd` |
| [Caball](https://doomshack.org/uploads/caball.zip)                                       | `CABALL.WAD`            | `a4a7e7b33233014601e1ba74c5dae1fe` |
| [Ultimate Doom The Way id Did](https://www.doomworld.com/idgames/levels/doom/s-u/udtwid) | `UDTWiD.wad`            | `c04696a6abda5ed345b040065e2934c6` |

> [!CAUTION]
> [Works of the Masters](https://jp.itch.io/deluxe-master-levels) is not supported by WadMelt! Do not use the WADs included with it!

## Full Run Mode

WadMelt features optional "Full Run" modes. When enabled, finishing an episode will immediately start the next episode. If an episode isn't available, it will be skipped over.

It can be enabled from the WadMelt options menu, and is available in three configurations:

| Default order           | Release Order           | Chronological order     |
| ----------------------- | ----------------------- | ----------------------- |
| Knee-Deep in the Dead   | Knee-Deep in the Dead   | Knee-Deep in the Dead   |
| The Shores of Hell      | The Shores of Hell      | The Shores of Hell      |
| Inferno                 | Inferno                 | Inferno                 |
| Thy Flesh Consumed      | Hell On Earth           | Thy Flesh Consumed      |
| SIGIL                   | Thy Flesh Consumed      | SIGIL                   |
| SIGIL II                | Master Levels           | SIGIL II                |
| Hell On Earth           | TNT: Evilution          | Hell On Earth           |
| Master Levels           | The Plutonia Experiment | No Rest for the Living  |
| No Rest for the Living  | No Rest for the Living  | Master Levels           |
| The Vulcan Abyss        | SIGIL                   | TNT: Evilution          |
| Counterfeit Eden        | SIGIL II                | The Plutonia Experiment |
| TNT: Evilution          | The Vulcan Abyss        | The Vulcan Abyss        |
| The Plutonia Experiment | Counterfeit Eden        | Counterfeit Eden        |

> [!TIP]
> Whether or not the Master Levels are included in a Full Run can also be toggled from the WadMelt options menu.

### Custom Full Run

Choosing **Custom** as the Full Run mode lets you pick your own order. Open **Custom Full Run** in the WadMelt options menu and choose a campaign for each of up to 16 slots; empty slots are ignored and campaigns that aren't installed are skipped, as in the other modes. The order is read once when you start a run, so changing the menu mid-run does not affect it. The choices are saved by campaign ID, not by position, so they stay correct when you add or remove other mods.

#### Adding outside campaigns (WFRUN files)

A Full Run can also include a WAD or PK3 that WadMelt doesn't know about, for example a replacement for DOOM II. Describe it in a small text file named `WFRUN` (a loose `WFRUN.txt` works, or put one inside the PK3):

```
version = 1

entry
{
    id = btsx                  // required, unique, a-z 0-9 _ -
    name = "Back to Saturn X"  // required, shown in the menu
    start = MAP01              // required, first map
    end = MAP32                // required, last map; repeat the line for several
    end = MAP31
    cast = MY_CAST_INTERMISSION    // optional ending screens (MAPINFO intermission names)
    nocast = MY_END_INTERMISSION
    replaces = doom2           // optional, see below
    container = btsx_e1.wad    // file that supplies the maps; required in a loose WFRUN.txt
    order = 100                // optional, sorts the list of outside campaigns (then by id)
    presets = 1,2,3            // optional, see below
}
```

Values that contain spaces need quotes. Names are not case sensitive.

- WadMelt never guesses a campaign's last map. Without a `WFRUN` entry an outside campaign is simply not part of a Full Run.
- `replaces = doom2` says the campaign takes over WadMelt's DOOM II slot. It then also takes that place in the three built-in orders. Without it the campaign is only used in a Custom run.
- `presets = 1,2,3` appends the campaign to the end of those built-in orders. It is meant for packs that extend WadMelt itself (the Xtras pack uses it for Jaguar and Absolution); an ordinary outside mod shouldn't use it.
- A mod's last map only needs to be listed in `end`. The intermediate maps of a campaign, even ones WadMelt would normally treat as an ending (such as `MAP30`), are left alone while an outside campaign owns them.
- `cast` / `nocast` name ending screens (MAPINFO intermissions) shown when the "cast call" option is on / off. If you leave one out, nothing is shown in that case and the run moves straight on.
- A map that WadMelt normally supplies but another file overrides (for example a WAD that provides its own `MAP01`) is reported in the console at start-up, and that built-in campaign is skipped in Full Runs unless a `WFRUN` entry describes the replacement.
- Textures, flats and sprites are looked up by name for the whole game, so an outside WAD that redefines a name used by other episodes can change how those look too. WadMelt can't prevent that yet; it prints a warning at start-up when an outside file brings its own `TEXTURE1`, `TEXTURE2`, `PNAMES` or `TEXTURES`. The outside file is loaded when the game starts, so the order of campaigns in a Full Run does not help: the other campaigns look different for the whole session. To see Fusion's own look, start the game without that mod (a per-map fix is on the roadmap).
- The New Game menu keeps the name "Hell on Earth" for the DOOM II slot because those names are fixed text. To rename it, load a tiny add-on with `episode WF_NEWGAME_MAP01 { Name = "Back to Saturn X" }` in its MAPINFO.

## Absolute Beginner's Guide

1. Download [WadMelt for Windows](https://github.com/xaerogonzo/wadmelt/releases/latest/download/wadfusion_win.zip) or [for macOS and GNU/Linux](https://github.com/xaerogonzo/wadmelt/releases/latest/download/wadfusion_py.zip) from this fork's releases, and extract it somewhere. (The upstream project's downloads build an IPK3 for UZDoom 4.14 and will not work on UZDoom 5.)
2. Find the folder(s) where GOG / Steam installed your game(s).
   - For Steam on Windows, this will be something like\
   `C:\Program Files (x86)\Steam\steamapps\common\Ultimate Doom\base`
3. Copy any files you find with a `.WAD` extension to the `source_wads` subfolder where you extracted WadMelt.
4. On Windows, double-click `WadFusion Menu.bat` (option 1 checks your WADs, option 2 builds). Otherwise run the `wadfusion.py` Python 3 script.
5. A terminal window will show which episodes can be extracted. Press Y and then Enter to proceed.
6. The terminal window will show progress as it generates the IPK3. When it finishes, press Enter to close the window. You should now have a file in the WadMelt folder called `doom_fusion.ipk3`.
7. Download [UZDoom](https://zdoom.org/downloads) and extract it to a folder.
8. Move the `doom_fusion.ipk3` and `doom_fusion_widescreen_gfx.pk3` files to UZDoom's folder.
9. Launch UZDoom and play!

## Acknowledgements

[WadSmoosh](https://jp.itch.io/wadsmoosh) was originally developed by JP LeBreton. WadFusion is based on its [source code](https://heptapod.host/jp-lebreton/wadsmoosh).

WadMelt uses the [Omgifol Python library](https://github.com/devinacker/omgifol) by Fredrik Johansson and Devin Acker.
