//-----------------------------------------------------------------------------
//
// Copyright 2026 WadFusion fork contributors
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/
//
//-----------------------------------------------------------------------------
//
// Full Run catalog: the list of campaigns a Full Run can chain together.
//
//  * Built-in entries are WadFusion's own episodes.
//  * External entries are declared by text lumps named WFRUN (the Xtras pack ships one too),
//    see README.md ("Custom Full Run").
//
// This file only builds and queries the catalog. Routing lives in wf_fullrun.zs.

class WFRunEntry
{
	String id;             // stable identifier, lower case
	String displayName;
	bool external;         // declared by a WFRUN lump
	String startMap;       // map (or wf_newgame_* hack map) a run goes to in order to start this entry
	String presentName;    // map name used to test whether the entry is installed
	Array<String> endMaps;
	String hackSuffix;     // built-in entries: wf_endgame_<hackSuffix> is their own hand-over map
	String aliasMap;       // e1m8b counts as the end of E1M8 too
	bool dynamicMasterEnd; // Master Levels: the end map depends on wf_map_mlr
	String interNormal;    // ending intermission with Full Run off
	String interCast;      // ending intermission with Full Run on, with cast
	String interNoCast;    // ending intermission with Full Run on, without cast
	String replacesId;     // id of the built-in entry this one supersedes
	Array<String> containers; // files that must supply the maps (external entries)
	int presetMask;        // bit 1/2/4: also appended to Full Run preset 1/2/3 (compatibility extensions only)
	int sortOrder;         // outside entries are listed by this, then by id (default 100)
	String source;         // file the descriptor came from (diagnostics)
	bool available;        // computed: installed and not overridden
	String unavailableReason;
}

extend class WadFusionStaticHandler
{
	Array<WFRunEntry> wfCatalog;
	Array<String> wfNotes;   // startup report lines (also shown in the Custom Full Run menu)
	bool wfCatalogReady;

	//-------------------------------------------------------------------------
	// Built-in catalog
	//-------------------------------------------------------------------------

	WFRunEntry WFAddBuiltin(String id, String name, String startMap, String presentName, String endMap, String hackSuffix,
		String interNormal, String interCast, String interNoCast)
	{
		let e = new("WFRunEntry");
		e.id = id;
		e.displayName = name;
		e.startMap = startMap;
		e.presentName = presentName;
		if ( endMap != "" )
			e.endMaps.Push(endMap);
		e.hackSuffix = hackSuffix;
		e.interNormal = interNormal;
		e.interCast = interCast;
		e.interNoCast = interNoCast;
		wfCatalog.Push(e);
		return e;
	}

	void WFBuildBuiltinCatalog()
	{
		// the same data that used to be spread over the arrays in FullRun()
		let e1 = WFAddBuiltin("doom1_e1", "Knee-Deep in the Dead", "wf_newgame_e1m1", "e1m1", "e1m8", "e1m8",
			"Doom1_Ep1_Fusion_FullRun_Off", "Doom1_Ep1_Fusion_FullRun", "Doom1_Ep1_Fusion_FullRun");
		e1.aliasMap = "e1m8b";
		WFAddBuiltin("doom1_e2", "The Shores of Hell", "wf_newgame_e2m1", "e2m1", "e2m8", "e2m8",
			"Doom1_Ep2_Fusion_FullRun_Off", "Doom1_Ep2_Fusion_FullRun", "Doom1_Ep2_Fusion_FullRun");
		WFAddBuiltin("doom1_e3", "Inferno", "wf_newgame_e3m1", "e3m1", "e3m8", "e3m8",
			"Inter_Bunny_Fusion_FullRun_Off", "Inter_Bunny_Fusion_FullRun", "Inter_Bunny_Fusion_FullRun");
		WFAddBuiltin("doom1_e4", "Thy Flesh Consumed", "wf_newgame_e4m1", "e4m1", "e4m8", "e4m8",
			"Doom1_Ep4_Fusion_FullRun_Off", "Doom1_Ep4_Fusion_FullRun", "Doom1_Ep4_Fusion_FullRun");
		WFAddBuiltin("sigil", "SIGIL", "wf_newgame_e5m1", "e5m1", "e5m8", "e5m8",
			"Doom1_Ep5_Fusion_FullRun_Off", "Doom1_Ep5_Fusion_FullRun", "Doom1_Ep5_Fusion_FullRun");
		WFAddBuiltin("sigil2", "SIGIL II", "wf_newgame_e6m1", "e6m1", "e6m8", "e6m8",
			"Doom1_Ep6_Fusion_FullRun_Off", "Doom1_Ep6_Fusion_FullRun", "Doom1_Ep6_Fusion_FullRun");
		WFAddBuiltin("doom2", "Hell on Earth", "wf_newgame_map01", "map01", "map30", "map30",
			"Inter_Cast", "Inter_Cast_Fusion_FullRun", "Doom2_End_Fusion_FullRun_NoCast");
		let ml = WFAddBuiltin("masterlevels", "Master Levels", "wf_newgame_ml_map01", "ml_map01", "", "masterlevels",
			"MasterLevels_End", "MasterLevels_End_Fusion_FullRun", "MasterLevels_End_Fusion_FullRun_NoCast");
		ml.dynamicMasterEnd = true;
		WFAddBuiltin("nerve", "No Rest for the Living", "wf_newgame_nv_map01", "nv_map01", "nv_map08", "nv_map08",
			"Inter_Cast", "Inter_Cast_Fusion_FullRun_NoCredits", "Doom2_End_Fusion_FullRun_NoCast_NoCredits");
		WFAddBuiltin("lr_e1", "The Vulcan Abyss", "wf_newgame_lr_map01", "lr_map01", "lr_map07", "lr_map07",
			"Id1_Ep1_Fusion_FullRun_Off", "Id1_Ep1_Fusion_FullRun", "Id1_Ep1_Fusion_FullRun");
		WFAddBuiltin("lr_e2", "Counterfeit Eden", "wf_newgame_lr_map08", "lr_map08", "lr_map14", "lr_map14",
			"Id1Cast", "Id1Cast_Fusion_FullRun", "Id1_End_Fusion_FullRun_NoCast");
		WFAddBuiltin("tnt", "TNT: Evilution", "wf_newgame_tn_map01", "tn_map01", "tn_map30", "tn_map30",
			"Inter_Cast_Tnt", "Inter_Cast_Tnt_Fusion_FullRun", "Tnt_End_Fusion_FullRun_NoCast");
		WFAddBuiltin("plutonia", "The Plutonia Experiment", "wf_newgame_pl_map01", "pl_map01", "pl_map30", "pl_map30",
			"Inter_Cast_Plutonia", "Inter_Cast_Plutonia_Fusion_FullRun", "Plutonia_End_Fusion_FullRun_NoCast");
	}

	// ids of the three legacy presets, in their exact existing order
	void WFPresetIds(int preset, out Array<String> ids)
	{
		ids.Clear();

		if ( preset == 1 )
		{
			String o1[] = { "doom1_e1", "doom1_e2", "doom1_e3", "doom1_e4", "sigil", "sigil2", "doom2", "masterlevels", "nerve", "lr_e1", "lr_e2", "tnt", "plutonia" };
			for ( int i = 0; i < o1.Size(); i++ )
				ids.Push(o1[i]);
		}
		else if ( preset == 2 )
		{
			String o2[] = { "doom1_e1", "doom1_e2", "doom1_e3", "doom2", "doom1_e4", "masterlevels", "tnt", "plutonia", "nerve", "sigil", "sigil2", "lr_e1", "lr_e2" };
			for ( int i = 0; i < o2.Size(); i++ )
				ids.Push(o2[i]);
		}
		else if ( preset == 3 )
		{
			String o3[] = { "doom1_e1", "doom1_e2", "doom1_e3", "doom1_e4", "sigil", "sigil2", "doom2", "nerve", "masterlevels", "tnt", "plutonia", "lr_e1", "lr_e2" };
			for ( int i = 0; i < o3.Size(); i++ )
				ids.Push(o3[i]);
		}
		else
			return;

		// an outside campaign that declares "replaces = <id>" takes over that slot
		for ( int i = 0; i < ids.Size(); i++ )
		{
			let rep = WFReplacementFor(ids[i]);
			if ( rep )
				ids[i] = rep.id;
		}

		// compatibility extensions (e.g. Xtras Jaguar / Absolution) append themselves, in catalog order
		int bit = 1 << (preset - 1);
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let e = wfCatalog[i];
			if ( e.external && (e.presetMask & bit) )
				ids.Push(e.id);
		}
	}

	WFRunEntry WFFindEntry(String id)
	{
		id = id.MakeLower();
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			if ( wfCatalog[i].id == id )
				return wfCatalog[i];
		}
		return null;
	}

	//-------------------------------------------------------------------------
	// Map / lump source queries
	//-------------------------------------------------------------------------

	// every lump that supplies a map with this name, in load order:
	// a WAD map marker (an empty lump with the map's name), or a maps/<name>.wad file
	void WFMapSuppliers(String mapName, out Array<int> lumps)
	{
		lumps.Clear();
		mapName = mapName.MakeLower();

		int l = Wads.FindLump(mapName, 0, Wads.GlobalNamespace);
		while ( l != -1 )
		{
			if ( Wads.GetLumpLength(l) == 0 )
				lumps.Push(l);
			l = Wads.FindLump(mapName, l + 1, Wads.GlobalNamespace);
		}

		l = Wads.CheckNumForFullName("maps/"..mapName..".wad");
		if ( l != -1 )
			lumps.Push(l);
	}

	bool WFMapExists(String mapName)
	{
		Array<int> l;
		WFMapSuppliers(mapName, l);
		return l.Size() > 0;
	}

	String WFBaseName(String path)
	{
		// container names use / (the engine normalises paths); take what follows the last one
		int slash = path.RightIndexOf("/");
		if ( slash >= 0 )
			path = path.Mid(slash + 1);
		return path.MakeLower();
	}

	// file name (lower case, no path) of the file a lump comes from; GetContainerName wants a container number, not a lump number
	String WFContainerOf(int lump)
	{
		return WFBaseName(Wads.GetContainerName(Wads.GetLumpContainer(lump)));
	}
	
	// container (file name, lower case, no path) that supplies this map, or ""
	// the lump with the highest number comes from the file loaded last, which the engine uses
	String WFMapContainer(String mapName)
	{
		Array<int> l;
		WFMapSuppliers(mapName, l);
		if ( l.Size() == 0 )
			return "";

		int best = l[0];
		for ( int i = 1; i < l.Size(); i++ )
		{
			if ( l[i] > best )
				best = l[i];
		}
		return WFContainerOf(best);
	}

	// container holding WadFusion's own resources (wadfused.txt exists only there)
	String WFFusionContainer()
	{
		int l = Wads.CheckNumForFullName("wadfused.txt");
		if ( l == -1 )
			return "";
		return WFContainerOf(l);
	}

	void WFNote(String line)
	{
		wfNotes.Push(line);
		Console.Printf("WadMelt runs: %s", line);
	}

	//-------------------------------------------------------------------------
	// WFRUN descriptors
	//-------------------------------------------------------------------------

	bool WFEndsWith(String s, String suffix)
	{
		int n = s.Length() - suffix.Length();
		return n >= 0 && s.Mid(n) == suffix;
	}
	
	bool WFValidId(String id)
	{
		if ( id.Length() == 0 )
			return false;
		for ( int i = 0; i < id.Length(); i++ )
		{
			int c = id.ByteAt(i);
			bool ok = (c >= 97 && c <= 122) || (c >= 48 && c <= 57) || c == 95 || c == 45;
			if ( !ok )
				return false;
		}
		return true;
	}

	// reads "= value"; returns false (leaving the scanner at the bad token) if there is no "="
	bool WFReadValue(ScriptScanner sc, out String value)
	{
		if ( !sc.GetString() )
			return false;
		if ( sc.GetStringContents() != "=" )
		{
			sc.UnGet();
			return false;
		}
		if ( !sc.GetString() )
			return false;
		value = sc.GetStringContents();
		return true;
	}

	void WFSkipBlock(ScriptScanner sc)
	{
		while ( sc.GetString() )
		{
			if ( sc.GetStringContents() == "}" )
				return;
		}
	}

	// parse the body of one "entry { ... }" block; the opening brace has been read
	void WFParseEntry(ScriptScanner sc, String descName, bool loose, int line)
	{
		let e = new("WFRunEntry");
		e.external = true;
		e.sortOrder = 100;
		e.source = descName;
		String problem = "";

		while ( sc.GetString() )
		{
			String key = sc.GetStringContents().MakeLower();
			if ( key == "}" )
				break;

			String value;
			if ( !WFReadValue(sc, value) )
			{
				problem = String.Format("expected '= value' after '%s' (line %d)", key, sc.Line);
				WFSkipBlock(sc);
				break;
			}

			if ( key == "id" )
				e.id = value.MakeLower();
			else if ( key == "name" )
				e.displayName = value;
			else if ( key == "start" )
				e.startMap = value.MakeLower();
			else if ( key == "end" )
				e.endMaps.Push(value.MakeLower());
			else if ( key == "cast" )
				e.interCast = value;
			else if ( key == "nocast" )
				e.interNoCast = value;
			else if ( key == "replaces" )
				e.replacesId = value.MakeLower();
			else if ( key == "container" )
				e.containers.Push(WFBaseName(value));
			else if ( key == "order" )
				e.sortOrder = value.ToInt();
			else if ( key == "presets" )
			{
				Array<String> parts;
				value.Split(parts, ",");
				for ( int i = 0; i < parts.Size(); i++ )
				{
					int n = parts[i].ToInt();
					if ( n >= 1 && n <= 3 )
						e.presetMask |= 1 << (n - 1);
				}
			}
			else
				WFNote(String.Format("%s: ignoring unknown field '%s' (line %d)", descName, key, sc.Line));
		}

		String label = e.id != "" ? e.id : String.Format("entry at line %d", line);

		if ( problem == "" && !WFValidId(e.id) )
			problem = "missing or invalid id (use a-z, 0-9, _ and -)";
		if ( problem == "" && e.displayName == "" )
			problem = "missing name";
		if ( problem == "" && e.startMap == "" )
			problem = "missing start map";
		if ( problem == "" && e.endMaps.Size() == 0 )
			problem = "missing end map";
		if ( problem == "" && WFFindEntry(e.id) )
			problem = "duplicate id (the first definition is used)";
		if ( problem == "" && e.containers.Size() == 0 )
		{
			// an embedded descriptor describes maps in its own archive; a loose WFRUN.txt cannot say where its maps are
			if ( loose )
				problem = "a loose WFRUN file needs a 'container = <file name>' line";
			else
				e.containers.Push(descName);
		}

		if ( problem != "" )
		{
			WFNote(String.Format("%s: skipping %s: %s", descName, label, problem));
			return;
		}

		e.presentName = e.startMap;
		wfCatalog.Push(e);
	}

	void WFParseDescriptor(int lump)
	{
		String descName = WFContainerOf(lump);
		bool loose = WFEndsWith(descName, ".txt") || WFEndsWith(descName, ".lmp");

		let sc = new("ScriptScanner");
		sc.OpenLumpNum(lump);
		sc.SetNoFatalErrors(true);

		while ( sc.GetString() )
		{
			String tok = sc.GetStringContents().MakeLower();
			if ( tok == "version" )
			{
				String v;
				if ( WFReadValue(sc, v) && v.ToInt() != 1 )
					WFNote(String.Format("%s: unsupported WFRUN version %s, reading it as version 1", descName, v));
			}
			else if ( tok == "entry" )
			{
				int line = sc.Line;
				if ( sc.GetString() && sc.GetStringContents() == "{" )
					WFParseEntry(sc, descName, loose, line);
				else
					WFNote(String.Format("%s: expected '{' after 'entry' (line %d)", descName, line));
			}
			else
				WFNote(String.Format("%s: unexpected '%s' (line %d)", descName, tok, sc.Line));
		}
		sc.Close();
	}

	// outside entries sorted by (order, id), after the built-in ones, so the catalog never depends on load order
	void WFSortExternals()
	{
		Array<WFRunEntry> ext;
		Array<WFRunEntry> builtin;
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			if ( wfCatalog[i].external )
				ext.Push(wfCatalog[i]);
			else
				builtin.Push(wfCatalog[i]);
		}
		
		for ( int i = 1; i < ext.Size(); i++ )
		{
			let cur = ext[i];
			int j = i - 1;
			while ( j >= 0 && (ext[j].sortOrder > cur.sortOrder || (ext[j].sortOrder == cur.sortOrder && ext[j].id > cur.id)) )
			{
				ext[j + 1] = ext[j];
				j--;
			}
			ext[j + 1] = cur;
		}
		
		wfCatalog.Clear();
		for ( int i = 0; i < builtin.Size(); i++ )
			wfCatalog.Push(builtin[i]);
		for ( int i = 0; i < ext.Size(); i++ )
			wfCatalog.Push(ext[i]);
	}
	
	void WFLoadDescriptors()
	{
		int l = Wads.FindLump("WFRUN", 0, Wads.GlobalNamespace);
		while ( l != -1 )
		{
			WFParseDescriptor(l);
			l = Wads.FindLump("WFRUN", l + 1, Wads.GlobalNamespace);
		}
		WFSortExternals();
	}

	//-------------------------------------------------------------------------
	// Availability, overrides and conflicts
	//-------------------------------------------------------------------------

	WFRunEntry WFReplacementFor(String builtinId)
	{
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let e = wfCatalog[i];
			if ( e.external && e.replacesId == builtinId && e.available )
				return e;
		}
		return null;
	}

	void WFComputeAvailability()
	{
		String fusion = WFFusionContainer();

		// external entries first, so that built-in entries can see what replaces them
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let e = wfCatalog[i];
			if ( !e.external )
				continue;

			e.available = false;
			if ( !WFMapExists(e.startMap) )
			{
				e.unavailableReason = "start map "..e.startMap.." not found";
				continue;
			}

			String supplier = WFMapContainer(e.startMap);
			bool inContainer = false;
			for ( int j = 0; j < e.containers.Size(); j++ )
			{
				if ( e.containers[j] == supplier )
					inContainer = true;
			}
			if ( !inContainer )
			{
				e.unavailableReason = "map "..e.startMap.." comes from "..supplier..", not "..e.containers[0];
				WFNote(String.Format("%s: %s", e.displayName, e.unavailableReason));
				continue;
			}
			e.available = true;
		}

		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let e = wfCatalog[i];
			if ( e.external )
				continue;

			// the same installed test that Full Run always used
			e.available = Wads.CheckNumForFullName("maps/"..e.presentName..".wad") != -1;
			if ( !e.available )
			{
				e.unavailableReason = "not installed";
				continue;
			}

			let rep = WFReplacementFor(e.id);
			if ( rep )
			{
				e.available = false;
				e.unavailableReason = "replaced by "..rep.displayName;
				WFNote(String.Format("%s (%s) is replaced by %s", e.displayName, e.presentName, rep.displayName));
				continue;
			}

			// a map with this name from another file than Fusion's, which no WFRUN entry claims
			String supplier = WFMapContainer(e.presentName);
			if ( supplier != "" && fusion != "" && supplier != fusion )
			{
				e.available = false;
				e.unavailableReason = "map "..e.presentName.." comes from "..supplier;
				WFNote(String.Format("%s: map %s is supplied by %s. Full Run skips it unless a WFRUN entry describes that campaign.", e.displayName, e.presentName, supplier));
			}
		}
	}

	// resource definitions from outside files can change how every episode looks
	void WFCheckResourceConflicts()
	{
		String fusion = WFFusionContainer();
		String names[] = { "TEXTURE1", "TEXTURE2", "PNAMES", "TEXTURES" };
		Array<String> seen;

		for ( int n = 0; n < names.Size(); n++ )
		{
			int l = Wads.FindLump(names[n], 0, Wads.GlobalNamespace);
			while ( l != -1 )
			{
				String c = WFContainerOf(l);
				bool engine = c == "uzdoom.pk3" || c == "lzdoom.pk3" || c == "gzdoom.pk3" || c == "game_support.pk3"
					|| c.IndexOf("widescreen") >= 0 || c == "brightmaps.pk3" || c == "lights.pk3";
				if ( c != fusion && !engine )
				{
					// say it once per file and resource, however many lumps it has
					String key = c.."|"..names[n];
					if ( seen.Find(key) == seen.Size() )
					{
						seen.Push(key);
						WFNote(String.Format("%s supplies %s. Outside texture definitions can change the look of other episodes too.", c, names[n]));
					}
				}
				l = Wads.FindLump(names[n], l + 1, Wads.GlobalNamespace);
			}
		}
	}

	//-------------------------------------------------------------------------
	// Read-only access for the menu (the menu runs on the UI side)
	//-------------------------------------------------------------------------

	clearscope int WFCatalogSize() { return wfCatalog.Size(); }
	clearscope String WFEntryIdAt(int i) { return wfCatalog[i].id; }
	clearscope String WFEntryNameAt(int i) { return wfCatalog[i].displayName; }
	clearscope bool WFEntryAvailableAt(int i) { return wfCatalog[i].available; }
	clearscope String WFEntryReasonAt(int i) { return wfCatalog[i].unavailableReason; }
	clearscope int WFNoteCount() { return wfNotes.Size(); }
	clearscope String WFNoteAt(int i) { return wfNotes[i]; }

	void WFInitRuns()
	{
		if ( wfCatalogReady )
			return;
		wfCatalogReady = true;

		WFBuildBuiltinCatalog();
		WFLoadDescriptors();
		WFComputeAvailability();
		WFCheckResourceConflicts();

		// summary: outside entries, and anything that is not available
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let e = wfCatalog[i];
			if ( e.external )
				Console.Printf("WadMelt runs: outside entry %s (%s) %s", e.id, e.displayName, e.available ? "available" : "NOT available: "..e.unavailableReason);
		}
	}
}
