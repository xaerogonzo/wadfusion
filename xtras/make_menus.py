#!/usr/bin/env python3
"""
Writes the merged MENUDEF (Xtras main's file plus the options the Revised beta had) and the matching CVARINFO lines.
Options added: Final DOOM HUD style for TNT / Plutonia (Tnt_Hud_toggle, Plu_Hud_toggle) and co-op item cleanup (dcx_CoopWeaponRemoval).
"""
import argparse, os, zipfile
ap = argparse.ArgumentParser()
ap.add_argument('--main', required=True)
ap.add_argument('--out', default=os.path.join('xtras', 'Wadfusion-Xtras-merged_uz5'))
a = ap.parse_args()
z = zipfile.ZipFile(a.main)
name = [n for n in z.namelist() if n.lower().endswith('/menudef.txt')][0]
raw = z.read(name).decode('cp1252')
crlf = '\r\n' in raw
t = raw.replace('\r\n', '\n')

def sub(old, new):
    global t
    assert t.count(old) == 1, 'expected one match of: ' + old[:60]
    t = t.replace(old, new)

sub('OptionValue DCX_CabalLevelOrder\n', '''OptionValue TNTHUDtweaks
{
	0.0, "TNT Evilution"
	1.0, "TNT Revilution"
	2.0, "Plutonia 2 \c[Dark Grey](Default)"
}

OptionValue PLUHUDtweaks
{
	0.0, "Plutonia"
	1.0, "Plutonia 2 \c[Dark Grey](Default)"
	2.0, "Plutonia Revisited"
}

OptionValue DCX_CabalLevelOrder
''')
sub('''	option "Doom 64 For Doom 2 Hud", "AB_hud_toggle", "D64HudTweaks"
	StaticText "Select which hud to use for the D64D2 levels", "dark red"
	StaticText " "
''', '''	option "Doom 64 For Doom 2 Hud", "AB_hud_toggle", "D64HudTweaks"
	StaticText "Select which hud to use for the D64D2 levels", "dark red"
	StaticText " "
	option "TNT Evilution Final DOOM hud", "Tnt_Hud_toggle", "TNTHUDtweaks"
	StaticText "Skin of the Final DOOM / Dynamic hud on the TNT: Evilution maps.", "dark red"
	StaticText " "
	option "Plutonia Final DOOM hud", "Plu_Hud_toggle", "PLUHUDtweaks"
	StaticText "Skin of the Final DOOM / Dynamic hud on the Plutonia Experiment maps.", "dark red"
	StaticText " "
''')
sub('''	Option "Cabal Level Order", "dcx_CabalOrder", "DCX_CabalLevelOrder"
	StaticText "Configures the level order of the cabal series of maps.", "dark red"
	StaticText " "
''', '''	Option "Cabal Level Order", "dcx_CabalOrder", "DCX_CabalLevelOrder"
	StaticText "Configures the level order of the cabal series of maps.", "dark red"
	StaticText " "
	Option "Co-op item cleanup", "dcx_CoopWeaponRemoval", "OnOff"
	StaticText "In co-op, removes the extra weapons, ammo and power-ups that levels place for co-op only", "dark red"
	StaticText "and turns the co-op Cyberdemons and Spider Mastermind into their lesser versions.", "dark red"
	StaticText "(Taken from the Xtras Revised beta; not play-tested in a network game.)", "dark red"
	StaticText " "
''')
out = t.replace('\n', '\r\n') if crlf else t
os.makedirs(a.out, exist_ok=True)
open(os.path.join(a.out, 'MENUDEF.txt'), 'w', encoding='cp1252', newline='').write(out)
ap_dir = os.path.join(a.out, '_append')
os.makedirs(ap_dir, exist_ok=True)
open(os.path.join(ap_dir, 'CVARINFO'), 'w', encoding='cp1252', newline='').write(
    '\r\nUser int Tnt_Hud_toggle = 2;\r\nUser int Plu_Hud_toggle = 1;\r\nserver bool dcx_CoopWeaponRemoval = false;\r\n')
print('wrote MENUDEF.txt and _append/CVARINFO')
