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
// "Custom Full Run" menu: one slot per campaign, filled from the Full Run catalog (wf_runs.zs).
// The slots are string cvars (wf_run_slot1..16) that store the campaign ID, not a list position,
// so a saved run stays correct when other mods are added or removed.

class WF_RunSlotItem : OptionMenuItem
{
	CVar mCVar;
	Array<String> mIds;
	Array<String> mNames;

	WF_RunSlotItem Init(String label, Name cvarName)
	{
		Super.Init(label, 'None');
		mCVar = CVar.FindCVar(cvarName);

		// choice 0 is an empty slot; then every campaign that is installed
		mIds.Push("");
		mNames.Push(StringTable.Localize("$WF_MENU_RUN_EMPTY"));

		let h = WadFusionStaticHandler(StaticEventHandler.Find("WadFusionStaticHandler"));
		if ( h )
		{
			for ( int i = 0; i < h.WFCatalogSize(); i++ )
			{
				if ( h.WFEntryAvailableAt(i) )
				{
					mIds.Push(h.WFEntryIdAt(i));
					mNames.Push(h.WFEntryNameAt(i));
				}
			}
		}
		return self;
	}

	// index of the stored id, or -1 if it is not available (it is then shown as such and never remapped)
	int GetSelection()
	{
		if ( !mCVar )
			return -1;
		String stored = mCVar.GetString().MakeLower();
		for ( int i = 0; i < mIds.Size(); i++ )
		{
			if ( mIds[i] == stored )
				return i;
		}
		return -1;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		drawLabel(indent, y, selected ? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor);

		int sel = GetSelection();
		String text;
		if ( sel >= 0 )
			text = mNames[sel];
		else
			text = String.Format("%s (%s)", mCVar.GetString(), StringTable.Localize("$WF_MENU_RUN_UNAVAILABLE"));

		drawValue(indent, y, OptionMenuSettings.mFontColorValue, text, false, false);
		return indent;
	}

	override bool MenuEvent(int mkey, bool fromcontroller)
	{
		if ( !mCVar )
			return Super.MenuEvent(mkey, fromcontroller);

		int cnt = mIds.Size();
		int sel = GetSelection();

		if ( mkey == Menu.MKEY_Left )
		{
			if ( sel == -1 )
				sel = 0;
			else if ( --sel < 0 )
				sel = cnt - 1;
		}
		else if ( mkey == Menu.MKEY_Right || mkey == Menu.MKEY_Enter )
		{
			if ( ++sel >= cnt )
				sel = 0;
		}
		else if ( mkey == Menu.MKEY_Clear )
			sel = 0;
		else
			return Super.MenuEvent(mkey, fromcontroller);

		mCVar.SetString(mIds[sel]);
		Menu.MenuSound("menu/change");
		return true;
	}

	override bool Selectable()
	{
		return true;
	}
}

class WF_CustomRunMenu : OptionMenu
{
	// split a long line into pieces that fit the menu
	void AddWrapped(OptionMenuDescriptor desc, String text, int maxLen)
	{
		while ( text.Length() > maxLen )
		{
			int cut = maxLen;
			// break at a space if there is one
			for ( int i = maxLen; i > maxLen / 2; i-- )
			{
				if ( text.Mid(i, 1) == " " )
				{
					cut = i;
					break;
				}
			}
			let line = new("OptionMenuItemStaticText");
			line.InitDirect(text.Left(cut), Font.CR_GRAY);
			desc.mItems.Push(line);
			text = text.Mid(cut + 1);
		}
		let last = new("OptionMenuItemStaticText");
		last.InitDirect(text, Font.CR_GRAY);
		desc.mItems.Push(last);
	}

	void AddHeader(OptionMenuDescriptor desc, String text)
	{
		let item = new("OptionMenuItemStaticText");
		item.Init(text, 1);
		desc.mItems.Push(item);
	}

	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		// the list depends on what is installed, so it is built every time the menu opens
		desc.mItems.Clear();

		AddWrapped(desc, StringTable.Localize("$WF_MENU_RUN_INFO1"), 60);
		AddWrapped(desc, StringTable.Localize("$WF_MENU_RUN_INFO2"), 60);

		let spacer = new("OptionMenuItemStaticText");
		spacer.Init(" ", 0);
		desc.mItems.Push(spacer);

		for ( int i = 1; i <= 16; i++ )
		{
			let slot = new("WF_RunSlotItem");
			slot.Init(StringTable.Localize("$WF_MENU_RUN_SLOT").." "..i, String.Format("wf_run_slot%d", i));
			desc.mItems.Push(slot);
		}

		// what WadFusion found at start-up: outside campaigns, replaced slots, texture warnings
		let h = WadFusionStaticHandler(StaticEventHandler.Find("WadFusionStaticHandler"));
		if ( h && h.WFNoteCount() > 0 )
		{
			let gap = new("OptionMenuItemStaticText");
			gap.Init(" ", 0);
			desc.mItems.Push(gap);
			AddHeader(desc, StringTable.Localize("$WF_MENU_RUN_REPORT"));
			for ( int n = 0; n < h.WFNoteCount(); n++ )
				AddWrapped(desc, h.WFNoteAt(n), 60);
		}

		Super.Init(parent, desc);
	}
}
