<#
 Builds a UZDoom 5 compatible copy of Wadfusion-Xtras-main.zip.
 Usage: .\xtras\apply_main_uz5.ps1 -Zip "...\Wadfusion-Xtras-main.zip" -Out "...\Wadfusion-Xtras-main_UZ5.pk3"
 Replaces the 4 changed files inside a copy of the original zip (the original is not modified).
#>
param([Parameter(Mandatory)][string]$Zip, [Parameter(Mandatory)][string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$src = Join-Path $PSScriptRoot 'Wadfusion-Xtras-main_uz5'
Copy-Item -LiteralPath $Zip -Destination $Out -Force
$arc = [IO.Compression.ZipFile]::Open($Out, 'Update')
try {
  foreach ($f in Get-ChildItem $src -Recurse -File) {
    $rel = $f.FullName.Substring($src.Length + 1).Replace('\', '/')
    $old = $arc.Entries | Where-Object { $_.FullName -ieq "Wadfusion-Xtras-main/$rel" } | Select-Object -First 1
    $name = if ($old) { $old.FullName } else { "Wadfusion-Xtras-main/$rel" }
    if ($old) { $old.Delete() }
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arc, $f.FullName, $name, [IO.Compression.CompressionLevel]::Optimal)
    "patched $name"
  }
} finally { $arc.Dispose() }
