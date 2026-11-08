#!/usr/bin/env python3
"""
Adds the Final DOOM HUD styles of the Xtras Revised beta to Xtras main's status bar (Zscript/UI/Dcx_Sbar.zsc).

The Revised beta shipped the artwork, fonts and the Tnt_Hud_toggle / Plu_Hud_toggle options but its status bar code never
read them. Here they are finished: on TNT: Evilution maps (tn_) and Plutonia maps (pl_) the Final DOOM HUD (and the Dynamic
HUD) can use the original skins instead of the Plutonia 2 one that Xtras main uses for every Final DOOM style map.

  Tnt_Hud_toggle   0 TNT Evilution   1 TNT Revilution   2 Plutonia 2 (default, as in Xtras main)
  Plu_Hud_toggle   0 Plutonia        1 Plutonia 2 (default, as in Xtras main)   2 Plutonia Revisited

Main wins: both default to the Plutonia 2 skin, so nothing changes until the player picks another style.
"""
import argparse, os, re, zipfile
ap = argparse.ArgumentParser()
ap.add_argument('--main', required=True)
ap.add_argument('--out', default=os.path.join('xtras', 'Wadfusion-Xtras-merged_uz5'))
a = ap.parse_args()
z = zipfile.ZipFile(a.main)
name = [n for n in z.namelist() if n.lower().endswith('zscript/ui/dcx_sbar.zsc')][0]
raw = z.read(name).decode('utf-8', errors='replace')
crlf = '\r\n' in raw
t = raw.replace('\r\n', '\n')

def sub(old, new, count=1):
    global t
    assert t.count(old) == count, 'expected %d match(es) of: %s (found %d)' % (count, old[:60], t.count(old))
    t = t.replace(old, new)

# 1. fonts
sub("	HUDFont mPL2font;\n	HUDFont mPL2fontS;\n",
    "	HUDFont mPL2font;\n	HUDFont mPL2fontS;\n"
    "	// Final DOOM HUD styles from the Revised beta (Tnt_Hud_toggle / Plu_Hud_toggle)\n"
    "	HUDFont mPLfont;   // Plutonia\n	HUDFont mPRfont;   // Plutonia Revisited and TNT Revilution\n	HUDFont mTNTfont;  // TNT Evilution\n"
    "	HUDFont mPRfontS;  // small yellow digits of Plutonia Revisited\n	HUDFont mTNTfontS; // small yellow digits of TNT\n")
sub('		mPL2fontS = HUDFont.Create("FDFONT_SPLUTONIA2");\n',
    '		mPL2fontS = HUDFont.Create("FDFONT_SPLUTONIA2");\n'
    '		mPLfont = HUDFont.Create("FDFONT_PLUTONIA");\n'
    '		mPRfont = HUDFont.Create("FDFONT_PLUTONIA3");\n'
    '		mTNTfont = HUDFont.Create("FDFONT_TNTE");\n'
    '		mPRfontS = HUDFont.Create("FDFONT_SPLUTONIA3");\n'
    '		mTNTfontS = HUDFont.Create("FDFONT_STNT");\n')

# 2. style resolver (placed before Checklevel)
sub("	void Checklevel (double TicFrac)\n",
'''	// Which Final DOOM skin the current map uses: 0 Plutonia 2 (Xtras main), 1 Plutonia, 2 Plutonia Revisited,
	// 3 TNT Revilution, 4 TNT Evilution. Only TNT Evilution (tn) and Plutonia (pl) maps can change.
	int FinalHudStyle(String mapName)
	{
		String p = mapName.Left(2);
		if ( p == "tn" )
		{
			int v = CVar.FindCVar("Tnt_Hud_toggle").GetInt();
			if ( v == 0 ) return 4;
			if ( v == 1 ) return 3;
		}
		else if ( p == "pl" )
		{
			int v = CVar.FindCVar("Plu_Hud_toggle").GetInt();
			if ( v == 0 ) return 1;
			if ( v == 2 ) return 2;
		}
		return 0;
	}

	void Checklevel (double TicFrac)
''')

# 3. main bar
sub('''			x_value = 42;
			y_value = 171;
			get_font = mPL2Font;
			DrawImage("PTBAR", (-128, 168), DI_ITEM_OFFSETS);
			DrawImage("PTTPRCNT", (90, 171), DI_ITEM_OFFSETS);
			DrawImage("PTTPRCNT", (221, 171), DI_ITEM_OFFSETS);
''','''			x_value = 42;
			y_value = 171;
			get_font = mPL2Font;
			switch ( FinalHudStyle(mapName) )
			{
				case 1: // Plutonia
					get_font = mPLfont;
					DrawImage("PLBAR", (-128, 168), DI_ITEM_OFFSETS);
					DrawImage("PLTPRCNT", (90, 171), DI_ITEM_OFFSETS);
					DrawImage("PLTPRCNT", (221, 171), DI_ITEM_OFFSETS);
					break;
				case 2: // Plutonia Revisited
					get_font = mPRfont;
					DrawImage("PRBAR", (-128, 168), DI_ITEM_OFFSETS);
					DrawImage("PRTPRCNT", (90, 171), DI_ITEM_OFFSETS);
					DrawImage("PRTPRCNT", (221, 171), DI_ITEM_OFFSETS);
					break;
				case 3: // TNT Revilution
					get_font = mPRfont;
					DrawImage("TRBAR", (-128, 168), DI_ITEM_OFFSETS);
					DrawImage("PRTPRCNT", (90, 171), DI_ITEM_OFFSETS);
					DrawImage("PRTPRCNT", (221, 171), DI_ITEM_OFFSETS);
					break;
				case 4: // TNT Evilution (its bar is 18 pixels wider than the others)
					get_font = mTNTfont;
					y_value = 170;
					DrawImage("TNBAR", (-150, 168), DI_ITEM_OFFSETS);
					DrawImage("TNTPRCNT", (90, 170), DI_ITEM_OFFSETS);
					DrawImage("TNTPRCNT", (221, 170), DI_ITEM_OFFSETS);
					break;
				default:
					DrawImage("PTBAR", (-128, 168), DI_ITEM_OFFSETS);
					DrawImage("PTTPRCNT", (90, 171), DI_ITEM_OFFSETS);
					DrawImage("PTTPRCNT", (221, 171), DI_ITEM_OFFSETS);
					break;
			}
''')

# 4. arms panel
sub('''			DrawImage("PTARMS", (104, 168), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(2)? "PTYSNUM2" : "PLGNUM2", (111, 172), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(3)? "PTYSNUM3" : "PLGNUM3", (123, 172), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(4)? "PTYSNUM4" : "PLGNUM4", (135, 172), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(5)? "PTYSNUM5" : "PLGNUM5", (111, 182), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(6)? "PTYSNUM6" : "PLGNUM6", (123, 182), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(7)? "PTYSNUM7" : "PLGNUM7", (135, 182), DI_ITEM_OFFSETS);
''','''			// arms panel and digits of the chosen Final DOOM skin
			String armsImg = "PTARMS";
			String yel = "PTYSNUM";
			String gry = "PLGNUM";
			switch ( FinalHudStyle(mapName) )
			{
				case 1: armsImg = "PLARMS"; yel = "PLYSNUM"; gry = "PLGNUM"; break;
				case 2: armsImg = "PRARMS"; yel = "PRYSNUM"; gry = "PRGNUM"; break;
				case 3: armsImg = "TRARMS"; yel = "TNYSNUM"; gry = "TNGNUM"; break;
				case 4: armsImg = "TNARMS"; yel = "TNYSNUM"; gry = "TNGNUM"; break;
			}
			DrawImage(armsImg, (104, 168), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(2)? yel.."2" : gry.."2", (111, 172), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(3)? yel.."3" : gry.."3", (123, 172), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(4)? yel.."4" : gry.."4", (135, 172), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(5)? yel.."5" : gry.."5", (111, 182), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(6)? yel.."6" : gry.."6", (123, 182), DI_ITEM_OFFSETS);
			DrawImage(CPlayer.HasWeaponsInSlot(7)? yel.."7" : gry.."7", (135, 182), DI_ITEM_OFFSETS);
''')

# 5. ammo numbers
sub('''				x_value = 288; x_offset = 26; y_value = 170; get_font = mPL2fontS;
				DrawImage("PTAMMO24", (248, 168), DI_ITEM_OFFSETS);
''','''				x_value = 288; x_offset = 26; y_value = 170; get_font = mPL2fontS;
				switch ( FinalHudStyle(mapName) )
				{
					case 1: get_font = mPL2fontS; break;
					case 2: get_font = mPRfontS; break;
					case 3: case 4: get_font = mTNTfontS; break;
				}
				DrawImage("PTAMMO24", (248, 168), DI_ITEM_OFFSETS);
''')
# 6. ammo numbers of the plain (non-ID24) table
sub('''			else if (CheckForFinalHud)
			{
				x_value = 288; x_offset = 26; y_value = 173;
				get_font = mPL2fontS;
			}
''', '''			else if (CheckForFinalHud)
			{
				x_value = 288; x_offset = 26; y_value = 173;
				get_font = mPL2fontS;
				switch ( FinalHudStyle(mapName) )
				{
					case 2: get_font = mPRfontS; break;
					case 3: case 4: get_font = mTNTfontS; break;
				}
			}
''')
out = t.replace('\n', '\r\n') if crlf else t
dst = os.path.join(a.out, 'Zscript', 'UI')
os.makedirs(dst, exist_ok=True)
open(os.path.join(dst, 'Dcx_Sbar.zsc'), 'w', encoding='utf-8', newline='').write(out)
print('wrote Dcx_Sbar.zsc (%d bytes)' % len(out))
