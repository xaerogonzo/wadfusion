#!/usr/bin/env python3
"""
Writes Zscript/LevelScripts/Dcx_CoopCleanup.zsc for the merged Xtras pack: the Revised beta's DCX_Multiplayerweaponremoveal
(removes the extra weapons/ammo/power-ups that maps place for co-op only, and turns co-op Cyberdemons and Spider Mastermind
into the Lesser versions) behind the dcx_CoopWeaponRemoval option, default off. Things flagged for co-op only never spawn
in single player, so the option cannot change a single-player game.
"""
import argparse, os, re, zipfile
ap = argparse.ArgumentParser()
ap.add_argument('--revised', required=True)
ap.add_argument('--out', default=os.path.join('xtras', 'Wadfusion-Xtras-merged_uz5'))
a = ap.parse_args()
z = zipfile.ZipFile(a.revised)
name = [n for n in z.namelist() if n.lower().endswith('zscript/levelpostprocessors.zsc')][0]
lines = z.read(name).decode('latin-1').replace('\r\n', '\n').split('\n')
s = next(i for i, l in enumerate(lines) if re.match(r'\s*class DCX_Multiplayerweaponremoveal', l, re.I))
e = next(i for i, l in enumerate(lines) if i > s and l.startswith('//Used in case the ACS script'))
body = '\n'.join(lines[s:e]).rstrip()
body = re.sub(r'class DCX_Multiplayerweaponremoveal\s*:\s*LevelPostProcessor', 'class DCX_CoopCleanup : LevelPostProcessor', body, flags=re.I)
body = body.replace('protected void Apply(Name checksum, String mapname)\n\t\t{', 'protected void Apply(Name checksum, String mapname)\n\t\t{\n\t\t\tif ( !CVar.FindCVar("dcx_CoopWeaponRemoval").GetBool() )\n\t\t\t\treturn;\n', 1)
assert 'dcx_CoopWeaponRemoval' in body
src = '// Co-op item cleanup, taken from the Xtras Revised beta (DCX_Multiplayerweaponremoveal) by xtras/make_coop_cleanup.py.\n// Off unless dcx_CoopWeaponRemoval is on.\n\n' + body + '\n'
os.makedirs(os.path.join(a.out, 'Zscript', 'LevelScripts'), exist_ok=True)
open(os.path.join(a.out, 'Zscript', 'LevelScripts', 'Dcx_CoopCleanup.zsc'), 'w', encoding='latin-1', newline='\r\n').write(src)
print('wrote Dcx_CoopCleanup.zsc')
