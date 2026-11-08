version "4.14.1"

// Test helper (not shipped): exits each normal map after 2 seconds and reports WadFusion's chosen
// next map / ending intermission on its hack maps, so Full Run transitions can be checked from the log.
class DCXTest_AutoExit : StaticEventHandler
{
	String reported;
	
	// start on wf_endgame_custom as if the outside campaign named in dcxtest_pending had just ended
	override void WorldLoaded(WorldEvent e)
	{
		CVar pc = CVar.FindCVar("dcxtest_pending");
		if ( pc && pc.GetString() != "" && Level.MapName.MakeLower() == "wf_endgame_custom" )
		{
			let h = WadFusionStaticHandler(StaticEventHandler.Find("WadFusionStaticHandler"));
			if ( h )
				h.wfPendingEntry = pc.GetString();
		}
	}
	
	override void WorldTick()
	{
		String m = Level.MapName.MakeLower();
		if ( m.Left(3) == "wf_" || m == "dcx_handover" )
		{
			if ( reported != m )
			{
				reported = m;
				let h = WadFusionStaticHandler(StaticEventHandler.Find("WadFusionStaticHandler"));
				if ( h )
					Console.Printf("DCXTEST_STATE %s next=[%s] inter=[%s]", m, h.nextMap, h.intermission);
			}
			return;
		}
		CVar c = CVar.FindCVar("dcxtest_exits");
		if ( c && c.GetInt() > 0 && Level.MapTime == 70 )
		{
			c.SetInt(c.GetInt() - 1);
			// report where the exit would go (the hook result); only follow it when asked
			String nm = Level.NextMap;
			Console.Printf("DCXTEST exiting %s -> [%s]", m, nm);
			CVar f = CVar.FindCVar("dcxtest_follow");
			// dcxtest_jump = "from:to": like a player typing "map <to>" in the console while on <from>
			CVar j = CVar.FindCVar("dcxtest_jump");
			if ( j && j.GetString() != "" )
			{
				Array<String> parts;
				j.GetString().MakeLower().Split(parts, ":");
				if ( parts.Size() == 2 && parts[0] == m )
				{
					Console.Printf("DCXTEST jumping %s -> [%s]", m, parts[1]);
					j.SetString("");
					Level.ChangeLevel(parts[1], 0, CHANGELEVEL_NOINTERMISSION);
					return;
				}
			}
			if ( f && f.GetInt() > 0 )
			{
				if ( nm != "" && nm.Left(11) != "EndSequence" )
					Level.ChangeLevel(nm, 0, CHANGELEVEL_NOINTERMISSION);
				else
					Level.ExitLevel(0, false);
			}
		}
	}
}
