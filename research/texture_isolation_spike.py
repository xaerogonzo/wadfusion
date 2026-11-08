"""
Throwaway research script (not part of the build): proves that private copies of Fusion's textures and flats can bring
Fusion's look back on a Fusion map while an outside mod (Back to Saturn X) is loaded. It reads the built doom_fusion.ipk3
and BSX1.pk3, lists the texture names a Plutonia map shares with the mod, writes private true-colour copies (FZT/FZP/FZF
names) plus a ZScript handler that calls Level.ReplaceTextures on that map, and packs them into isospike.pk3.
Edit the paths at the top (S = a scratch folder holding new_fusion.ipk3) before running it.
"""
