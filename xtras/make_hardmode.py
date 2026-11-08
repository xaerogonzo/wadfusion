#!/usr/bin/env python3
"""
Builds the ACS library for the Total Carnage / ULTRA NIGHTMARE skills from the Revised beta's
ACS/Backup/XtraMonsters.txt (read only) and compiles it with ACC.

Only the part that runs on GameSkill() == 5 is taken; the Revised file's other placements
(Hard skill in Absolution, ChangeSkyTexture) already exist in Xtras main and are not copied.

Usage: python xtras/make_hardmode.py --revised <Revised_beta.pk3> --acc <acc.exe folder> [--out xtras/Wadfusion-Xtras-merged_uz5]
"""
import argparse, os, re, shutil, subprocess, sys, tempfile, zipfile

ap = argparse.ArgumentParser()
ap.add_argument('--revised', required=True)
ap.add_argument('--acc', required=True)
ap.add_argument('--out', default=os.path.join('xtras', 'Wadfusion-Xtras-merged_uz5'))
a = ap.parse_args()

z = zipfile.ZipFile(a.revised)
name = [n for n in z.namelist() if n.lower().endswith('acs/backup/xtramonsters.txt')][0]
lines = z.read(name).decode('latin-1').replace('\r\n', '\n').split('\n')

def find(pattern, start=0):
    for i in range(start, len(lines)):
        if re.search(pattern, lines[i]):
            return i
    raise SystemExit('pattern not found: ' + pattern)

enter = find(r'^script "Xtra_Monster_Placements" enter')
skill5 = find(r'if \(\(GameSkill \(\) == 5\)\)', enter)
# the enter script ends at the first line that is exactly "}" after the skill-5 block
end = skill5
depth = 0
for i in range(skill5, len(lines)):
    depth += lines[i].count('{') - lines[i].count('}')
    if depth == 0 and i > skill5:
        end = i
        break
block = lines[skill5:end + 1]
funcs_start = find(r'^function bool IsDoorOpen')
funcs_end = find(r'^Script "DeleteMe"')          # keep functions only; DeleteMe/TestTID are debugging scripts
funcs = lines[funcs_start:funcs_end]
# Replace() needs the helper functions that follow DeleteMe
rep = find(r'^function void Replace')
rep_end = find(r'^Script "TestTID"')
funcs += lines[rep:rep_end]

header = '''#library "XtraHardMode"
#include "zcommon.acs"

// Total Carnage / Unholy Massacre / ULTRA NIGHTMARE monster placements.
// Taken from the Xtras Revised beta (ACS/Backup/XtraMonsters.txt) by xtras/make_hardmode.py.
// Runs only when GameSkill() == 5, which only those skills return (see mapinfo.txt).

script "HardMode_Placements" enter
{
	if (PlayerNumber() != 0)
	terminate;

	if (GameType() == GAME_TITLE_MAP)
	terminate;

	str mapName = StrParam(n:PRINTNAME_LEVEL);
	str episode = StrMid(mapName, 1, 1);
	str mission = StrMid(mapName, 3, 1);

'''
body = '\n'.join(block)
# the Revised file spells one pickup 'Stimpaick', which never spawned
body = body.replace('"Stimpaick"', '"Stimpack"')
# the block ended with its own "terminate;" and closing braces of the original enter script: add the final brace
src = header + body + '\n}\n\n' + '\n'.join(funcs) + '\n'

os.makedirs(os.path.join(a.out, 'ACS', 'Backup'), exist_ok=True)
txt = os.path.join(a.out, 'ACS', 'Backup', 'XtraHardMode.txt')
open(txt, 'w', encoding='latin-1', newline='\r\n').write(src)

tmp = tempfile.mkdtemp()
for f in os.listdir(a.acc):
    if f.lower().endswith(('.acs', '.exe')):
        shutil.copy(os.path.join(a.acc, f), tmp)
shutil.copy(txt, os.path.join(tmp, 'XtraHardMode.acs'))
r = subprocess.run([os.path.join(tmp, 'acc.exe'), 'XtraHardMode.acs', 'XtraHardMode.o'], cwd=tmp, capture_output=True, text=True)
print(r.stdout, r.stderr)
if r.returncode != 0 or not os.path.exists(os.path.join(tmp, 'XtraHardMode.o')):
    sys.exit('ACC failed')
shutil.copy(os.path.join(tmp, 'XtraHardMode.o'), os.path.join(a.out, 'ACS', 'XtraHardMode.o'))
print('wrote', txt, 'and ACS/XtraHardMode.o')
