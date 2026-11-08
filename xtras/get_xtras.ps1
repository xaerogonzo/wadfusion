<#
 One command to get the Xtras packs: downloads the exact upstream versions this fork's patches were made for,
 checks them, and builds the merged pack (and the Unofficial one) next to the IPK3.

 The Xtras packs are by Someguyman and are not distributed with WadFusion. The downloads come straight from their
 GitHub repositories (about 440 MB in total); nothing of theirs is modified, the packs are built from copies.

 Usage (PowerShell 7):   pwsh -File .\xtras\get_xtras.ps1 [-OutDir <folder>] [-SkipUnofficial] [-DownloadDir <folder>]
   -OutDir          where the built packs go (default: the folder above xtras\)
   -DownloadDir     where the downloads are kept (default: <OutDir>\xtras_downloads); a file that is already there and
                    matches is not downloaded again
   -SkipUnofficial  leave out the Unofficial Xtras (Doom Zero, Freedoom, Hell to Pay, ...)
#>
param(
  [string]$OutDir = (Split-Path $PSScriptRoot -Parent),
  [string]$DownloadDir = '',
  [switch]$SkipUnofficial
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'xtras_common.ps1')
$sources = Get-Content (Join-Path $PSScriptRoot 'xtras_sources.json') -Raw | ConvertFrom-Json
if (-not $DownloadDir) { $DownloadDir = Join-Path $OutDir 'xtras_downloads' }
New-Item -ItemType Directory -Force -Path $OutDir, $DownloadDir | Out-Null

function Get-Pinned($key, $label) {
  $src = $sources.$key
  $file = Join-Path $DownloadDir "$key.zip"
  if (Test-Path -LiteralPath $file) {
    try { [void](Test-Input $file $src $label); Write-Host "${label}: already downloaded and verified."; return $file } catch { Write-Host "${label}: the existing file does not match, downloading again." }
  }
  Write-Host "${label}: downloading commit $($src.commit.Substring(0,7)) of $($src.repo) ..."
  $tmp = "$file.part"
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri $src.download -OutFile $tmp
  Move-Item -LiteralPath $tmp -Destination $file -Force
  [void](Test-Input $file $src $label)
  Write-Host "${label}: verified."
  return $file
}

$main = Get-Pinned 'main' 'Xtras main'
$revised = Get-Pinned 'revised' 'Xtras Revised beta'
$merged = Join-Path $OutDir 'Wadfusion-Xtras-Merged_UZ5.pk3'
& (Join-Path $PSScriptRoot 'apply_merged_uz5.ps1') -Main $main -Revised $revised -Out $merged

$files = @($merged)
if (-not $SkipUnofficial) {
  $unofficial = Get-Pinned 'unofficial' 'Unofficial Xtras'
  $unoffOut = Join-Path $OutDir 'WadFusion-Unofficial-Xtras-main_UZ5.pk3'
  & (Join-Path $PSScriptRoot 'apply_unofficial_uz5.ps1') -Zip $unofficial -Out $unoffOut | Out-Null
  Write-Host "built $unoffOut"
  $files += $unoffOut
}

Write-Host ''
Write-Host 'Done. Add these to your launch line after doom_fusion.ipk3:'
Write-Host ('  -file doom_fusion_widescreen_gfx.pk3 ' + (($files | ForEach-Object { '"' + $_ + '"' }) -join ' '))
Write-Host 'The folder xtras_downloads can be deleted once the packs are built.'
