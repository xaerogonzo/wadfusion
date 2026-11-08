<#
 Builds a Full Run enabled copy of WadFusion-Unoffical-Xtras-main.zip: the original zip plus a WFRUN file that
 describes its campaigns (Doom Zero, Evil Unleashed, Freedoom 1 and 2, Hell to Pay, Perdition's Gate, Plutonia 2,
 TNT: Revilution) so they appear in the Custom Full Run menu. Load it together with Wadfusion-Xtras-main.
 Usage: .\xtras\apply_unofficial_uz5.ps1 -Zip "...\WadFusion-Unoffical-Xtras-main.zip" -Out "...\WadFusion-Unofficial-Xtras-main_UZ5.pk3"
#>
param([Parameter(Mandatory)][string]$Zip, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$src = Join-Path $PSScriptRoot 'Wadfusion-Unofficial-Xtras-main_uz5'
Copy-Item -LiteralPath $Zip -Destination $Out -Force
$arc = [IO.Compression.ZipFile]::Open($Out, 'Update')
try {
  $root = (($arc.Entries | Where-Object { $_.FullName -notmatch '/$' } | Select-Object -First 1).FullName -split '/')[0] + '/'   # Wadfusion-Xtras-main/ in the original zip, Wadfusion-Xtras-<commit>/ in a GitHub download
  foreach ($f in Get-ChildItem $src -Recurse -File) {
    $rel = $f.FullName.Substring($src.Length + 1).Replace('\', '/')
    $name = "$root$rel"
    $old = $arc.Entries | Where-Object { $_.FullName -ieq $name } | Select-Object -First 1
    if ($old) { $old.Delete() }
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arc, $f.FullName, $name, [IO.Compression.CompressionLevel]::Optimal)
    "patched $name"
  }
} finally { $arc.Dispose() }
