//-----------------------------------------------------------------------------
//
// Copyright 2025-2026 Owlet VII
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

// Full Run router. The list of campaigns (the catalog) lives in wf_runs.zs; this file decides, when a campaign ends,
// which one comes next and which ending to show. The behaviour of the three built-in orders is unchanged.

extend class WadFusionStaticHandler
{
	String wfCurrentEntry;       // id of the campaign the player is in
	String wfPendingEntry;       // id of the outside campaign whose ending is being shown on wf_endgame_custom
	Array<String> wfActiveRun;   // custom run (wf_fullrun = 4), fixed when the run starts
	bool wfRunSnapshot;          // wfActiveRun is valid
	bool wfRouterStarted;        // the router itself started the entry that is loading

	void FullRun()
	{
		WFInitRuns(); // wf_runs.zs

		String mapName = Level.MapName.MakeLower();

		WFTrackArrival(mapName);

		if ( mapName.Left(10) == "wf_endgame" )
			WFEndGameMap(mapName);

		if ( CVar.FindCVar("wf_compat_nextmap").GetBool() )
			WFHookEndMap(mapName);
	}

	//-------------------------------------------------------------------------
	// Which campaign is being played
	//-------------------------------------------------------------------------

	WFRunEntry WFBuiltinByStart(String startMap)
	{
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			if ( !wfCatalog[i].external && wfCatalog[i].startMap == startMap )
				return wfCatalog[i];
		}
		return null;
	}

	WFRunEntry WFBuiltinByHack(String suffix)
	{
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			if ( !wfCatalog[i].external && wfCatalog[i].hackSuffix == suffix )
				return wfCatalog[i];
		}
		return null;
	}

	void WFTrackArrival(String mapName)
	{
		if ( Level.MapTime != 0 )
			return;

		if ( mapName.Left(10) == "wf_newgame" )
		{
			// a game started from the menu begins a new run; one the router started continues the current one
			if ( wfRouterStarted )
				wfRouterStarted = false;
			else
				wfRunSnapshot = false;

			// an outside campaign can start from a hack map of its own (the Xtras ones do)
			for ( int i = 0; i < wfCatalog.Size(); i++ )
			{
				let x = wfCatalog[i];
				if ( x.external && x.available && x.startMap == mapName )
				{
					wfCurrentEntry = x.id;
					return;
				}
			}
			
			let e = WFBuiltinByStart(mapName);
			if ( e )
			{
				let rep = WFReplacementFor(e.id);
				wfCurrentEntry = rep ? rep.id : e.id;
			}
			return;
		}

		if ( mapName.Left(3) == "wf_" )
			return;

		// arriving at the first map of an outside campaign
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let e = wfCatalog[i];
			if ( e.external && e.available && e.startMap == mapName )
			{
				wfCurrentEntry = e.id;
				return;
			}
		}
	}

	//-------------------------------------------------------------------------
	// Hand-over maps
	//-------------------------------------------------------------------------

	bool WFEntryEndsOn(WFRunEntry e, String mapName)
	{
		if ( e.dynamicMasterEnd )
			return mapName == GetMasterLevelsEndGame();
		if ( e.aliasMap != "" && mapName == e.aliasMap )
			return true;
		for ( int i = 0; i < e.endMaps.Size(); i++ )
		{
			if ( e.endMaps[i] == mapName )
				return true;
		}
		return false;
	}

	// if `mapName` is a declared end map of this outside campaign and one of its own files supplies it,
	// send the player to the shared hand-over map
	bool WFHookOutside(WFRunEntry e, String mapName)
	{
		if ( !e.available || !WFEntryEndsOn(e, mapName) )
			return false;

		// with Full Run off an outside campaign keeps its own ending
		int fullRun = CVar.FindCVar("wf_fullrun").GetInt();
		if ( fullRun < 1 || fullRun > 4 )
			return false;

		String supplier = WFMapContainer(mapName);
		for ( int i = 0; i < e.containers.Size(); i++ )
		{
			if ( e.containers[i] == supplier )
			{
				wfPendingEntry = e.id;
				wfCurrentEntry = e.id;
				Level.NextMap = "wf_endgame_custom";
				Level.NextSecretMap = "wf_endgame_custom";
				return true;
			}
		}
		return false;
	}

	// the last map of a campaign sends the player to that campaign's hand-over map
	void WFHookEndMap(String mapName)
	{
		// an outside campaign: only its own declared end maps count, and only if they come from its own files.
		// The campaign being played is tried first; others are matched by end map and file (a player can warp in).
		let cur = WFFindEntry(wfCurrentEntry);
		if ( cur && cur.external && WFHookOutside(cur, mapName) )
			return;
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let x = wfCatalog[i];
			if ( x.external && x != cur && WFHookOutside(x, mapName) )
				return;
		}

		// WadFusion's own campaigns (unless an outside campaign has taken the slot)
		for ( int i = 0; i < wfCatalog.Size(); i++ )
		{
			let e = wfCatalog[i];
			if ( e.external || !e.available )
				continue;
			if ( WFEntryEndsOn(e, mapName) )
			{
				// a map with this name that some other file supplies is not WadFusion's to redirect
				String supplier = WFMapContainer(mapName);
				String fusion = WFFusionContainer();
				if ( supplier != "" && fusion != "" && supplier != fusion )
					return;

				Level.NextMap = "wf_endgame_"..e.hackSuffix;
				return;
			}
		}

		// historic quirk: ml_map43 outside the Rejects order pointed at a hand-over map that does not exist
		if ( mapName == "ml_map43" )
			Level.NextMap = "wf_endgame_"..mapName;
	}

	void WFEndGameMap(String mapName)
	{
		String suffix = mapName.Mid(11);
		WFRunEntry entry = suffix == "custom" ? WFFindEntry(wfPendingEntry) : WFBuiltinByHack(suffix);

		if ( Level.MapTime == 0 )
		{
			int fullRun = CVar.FindCVar("wf_fullrun").GetInt();
			let fullRunCast = CVar.FindCVar("wf_fullrun_cast").GetBool();

			nextMap = "";
			if ( entry )
			{
				nextMap = WFNextEntryStart(entry, fullRun);

				if ( fullRun >= 1 && fullRun <= 4 )
					intermission = fullRunCast ? entry.interCast : entry.interNoCast;
				else
					intermission = entry.interNormal;

				if ( nextMap != "" )
					wfRouterStarted = true;
			}
			else
				intermission = "";
		}

		if ( intermission != "" )
			StoryStartIntermission(); // wf_story.zs

		if ( Level.MapTime >= 1 )
		{
			let isPistolStart = CVar.FindCVar("wf_compat_pistolstart").GetBool();
			let pistolStart = CHANGELEVEL_RESETINVENTORY|CHANGELEVEL_RESETHEALTH|CHANGELEVEL_NOINTERMISSION;

			Level.ChangeLevel(nextMap, 0, isPistolStart ? pistolStart : CHANGELEVEL_NOINTERMISSION);
		}
	}

	//-------------------------------------------------------------------------
	// Choosing the next campaign
	//-------------------------------------------------------------------------

	// reads the custom run slots (wf_run_slot1..16) once, when a run starts
	void WFBuildActiveRun()
	{
		wfRunSnapshot = true;
		wfActiveRun.Clear();

		for ( int i = 1; i <= 16; i++ )
		{
			let c = CVar.FindCVar(String.Format("wf_run_slot%d", i));
			if ( !c )
				continue;
			String id = c.GetString();
			if ( id != "" )
				wfActiveRun.Push(id.MakeLower());
		}
	}

	// start map of the campaign that follows `entry`, or "" if the run is over
	String WFNextEntryStart(WFRunEntry entry, int fullRun)
	{
		Array<String> ids;
		if ( fullRun >= 1 && fullRun <= 3 )
			WFPresetIds(fullRun, ids);
		else if ( fullRun == 4 )
		{
			if ( !wfRunSnapshot )
				WFBuildActiveRun();
			ids.Copy(wfActiveRun);
		}
		else
			return "";

		let fullRunMasterLevels = CVar.FindCVar("wf_fullrun_ml").GetBool();
		let fullRunLoop = CVar.FindCVar("wf_fullrun_loop").GetBool();

		int i = ids.Find(entry.id);
		if ( i == ids.Size() )
			return "";

		// after the last campaign, "loop" goes back to the first
		bool fullRunEndLoop = fullRunLoop && i == ids.Size() - 1;

		for ( int j = fullRunEndLoop ? 0 : i + 1; j < ids.Size(); j++ )
		{
			let e = WFFindEntry(ids[j]);
			if ( !e || !e.available )
				continue;
			if ( !fullRunMasterLevels && e.id == "masterlevels" )
				continue;
			return e.startMap;
		}
		return "";
	}

	String GetMasterLevelsEndGame()
	{
		if ( CVar.FindCVar("wf_map_mlr").GetBool() )
			return "ml_map43";
		else
			return "ml_map20";
	}
}
