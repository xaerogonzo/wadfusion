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

extend class WadFusionHandler
{
	// The DOOM II sold today has the swastikas in the Wolfenstein secret levels replaced with a different symbol.
	// If doom2_original.wad (the original v1.9) was present when WadFusion built this IPK3, the original
	// textures (ZOWOLF*) are in it, and they are used here unless "Censored Wolfenstein textures" is on.
	
	void DoWolfensteinTextureReplacements()
	{
		if ( CVar.FindCVar("wf_wolf_censored").GetBool() )
			return;
		
		// WadFusion Xtras has its own Wolfenstein texture setting. Leave the textures alone
		// when it is set to something other than "Original", so that it still works.
		CVar xtras = CVar.FindCVar("W3D_Text_toggle");
		if ( xtras && xtras.GetInt() != 0 )
			return;
		
		// the original textures are only present if the IPK3 was built with doom2_original.wad
		if ( !TexMan.CheckForTexture("ZOWOLF2", TexMan.Type_Wall).IsValid() )
			return;
		
		Level.ReplaceTextures("ZZWOLF2" , "ZOWOLF2" , TexMan.NOT_FLAT);
		Level.ReplaceTextures("ZZWOLF3" , "ZOWOLF3" , TexMan.NOT_FLAT);
		Level.ReplaceTextures("ZZWOLF4" , "ZOWOLF4" , TexMan.NOT_FLAT);
		Level.ReplaceTextures("ZZWOLF6" , "ZOWOLF6" , TexMan.NOT_FLAT);
		Level.ReplaceTextures("ZZWOLF7" , "ZOWOLF7" , TexMan.NOT_FLAT);
		Level.ReplaceTextures("ZZWOLF11", "ZOWOLF11", TexMan.NOT_FLAT);
		Level.ReplaceTextures("ZZWOLF13", "ZOWOLF13", TexMan.NOT_FLAT);
	}
}
