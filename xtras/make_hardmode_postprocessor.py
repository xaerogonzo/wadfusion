#!/usr/bin/env python3
"""
Writes Zscript/LevelScripts/Dcx_HardMode_Placements.zsc for the merged Xtras pack: the thing changes the Xtras Revised beta
makes on the Total Carnage / ULTRA NIGHTMARE skills (its DCX_TotalCarnageMonsterPlacementsBackup, block 'Check_Difficulty == 2').
Only that block is taken. The Revised class also changed Episode 4 on every skill and repeated the Doom 64 placements that
Xtras main already has; both are left out. The skill test uses the skill's ACS number (5) instead of an ACS call.
"""
import argparse, os, re, zipfile
ap = argparse.ArgumentParser()
ap.add_argument('--revised', required=True)
ap.add_argument('--out', default=os.path.join('xtras', 'Wadfusion-Xtras-merged_uz5'))
a = ap.parse_args()
z = zipfile.ZipFile(a.revised)
name = [n for n in z.namelist() if n.lower().endswith('zscript/levelpostprocessors.zsc')][0]
lines = z.read(name).decode('latin-1').replace('\r\n', '\n').split('\n')
start = next(i for i, l in enumerate(lines) if re.search(r'If \(CallACS\("Check_Difficulty"\) == 2\)', l, re.I))
depth, end = 0, start
for i in range(start + 1, len(lines)):
    depth += lines[i].count('{') - lines[i].count('}')
    if depth == 0 and '}' in lines[i]:
        end = i
        break
body = lines[start + 1:end + 1]        # '{' ... '}'
src = '''// Total Carnage / ULTRA NIGHTMARE: extra and replaced monsters, changed in the map data when a map loads.
// Taken from the Xtras Revised beta (Levelpostprocessors.zsc) by xtras/make_hardmode_postprocessor.py.
// Runs only when the skill's ACS number is 5 (Total Carnage, ULTRA NIGHTMARE).

class DCX_HardModePlacements : LevelPostProcessor
{
	protected void Apply(Name checksum, String mapNameArg)
	{
		if ( G_SkillPropertyInt(SKILLP_ACSReturn) != 5 )
			return;

		String mapName = level.MapName.MakeLower();

''' + '\n'.join('\t\t' + l if l.strip() else l for l in body) + '''
	}
}
'''
os.makedirs(os.path.join(a.out, 'Zscript', 'LevelScripts'), exist_ok=True)
open(os.path.join(a.out, 'Zscript', 'LevelScripts', 'Dcx_HardMode_Placements.zsc'), 'w', encoding='latin-1', newline='\r\n').write(src)
print('wrote', len(body), 'lines')
