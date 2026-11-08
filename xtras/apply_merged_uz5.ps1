<#
 Builds the merged Xtras pack (Xtras main + the unique parts of the Revised beta) for UZDoom 5 / LZDoom.

 Inputs are the two ORIGINAL archives; they are only read. Order of operations (always the same):
   1. verify both inputs against the content fingerprints in xtras/xtras_sources.json (a GitHub download of that commit matches)
   2. build the patched Main pack with apply_main_uz5.ps1 (our UZDoom 5 fixes, Jaguar/Absolution WFRUN, ...)
   3. import the files listed in xtras/merge_imports.txt from the Revised pack (Main wins: nothing in Main is replaced)
   4. append the definition snippets in xtras/Wadfusion-Xtras-merged_uz5/_append/ to the matching Main files
   5. copy the whole-file overlays in xtras/Wadfusion-Xtras-merged_uz5/ (code and menus we merged by hand)
   6. write <Out>.build.json (input hashes, imports, appends, overlays, output hash)
 The output is built next to the destination and only moved over it when every step succeeded.

 Usage: .\xtras\apply_merged_uz5.ps1 -Main "...\Wadfusion-Xtras-main.zip" -Revised "...\Wadfusion-Xtras-Revised_beta.pk3" -Out "...\Wadfusion-Xtras-Merged_UZ5.pk3"
#>
param(
  [Parameter(Mandatory)][string]$Main,
  [Parameter(Mandatory)][string]$Revised,
  [Parameter(Mandatory)][string]$Out
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$here = $PSScriptRoot
$sources = Get-Content (Join-Path $here 'xtras_sources.json') -Raw | ConvertFrom-Json

# A fingerprint of an archive's contents (file names and CRC-32s, without the top folder), so a download from GitHub
# matches the original zip even though the zip file itself differs.
function Get-Fingerprint($path) {
  $z = [IO.Compression.ZipFile]::OpenRead($path)
  try {
    $files = @($z.Entries | Where-Object { $_.FullName -notmatch '/$' })
    $root = $files[0].FullName.Split('/')[0] + '/'
    [string[]]$lines = @($files | Where-Object { $_.FullName.StartsWith($root) } | ForEach-Object { '{0}|{1:x8}' -f $_.FullName.Substring($root.Length), $_.Crc32 })
    [Array]::Sort($lines, [StringComparer]::Ordinal)
    $sha = [Security.Cryptography.SHA256]::Create()
    return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($lines -join "`n")))) -replace '-', '').ToLower()
  } finally { $z.Dispose() }
}
function Test-Input($path, $src, $label) {
  if (-not (Test-Path -LiteralPath $path)) { throw "$label not found: $path" }
  $h = Get-Fingerprint $path
  if ($h -ne $src.fingerprint) {
    throw "$label is not the version this script was made for (commit $($src.commit.Substring(0,7)) of $($src.repo)). Download exactly that one: $($src.download)"
  }
  return $h
}
$mainHash = Test-Input $Main $sources.main 'Xtras main'
$revHash  = Test-Input $Revised $sources.revised 'Xtras Revised beta'

$tmp = "$Out.building"
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }

# 2. patched Main
& (Join-Path $here 'apply_main_uz5.ps1') -Zip $Main -Out $tmp | Out-Null

$log = [ordered]@{ imports = @(); appends = @(); overlays = @(); skipped = @() }
$arc = [IO.Compression.ZipFile]::Open($tmp, 'Update')
$rev = [IO.Compression.ZipFile]::OpenRead($Revised)
try {
  $mainRoot = (($arc.Entries | Where-Object { $_.FullName -notmatch '/$' } | Select-Object -First 1).FullName -split '/')[0] + '/'
  $revRoot = (($rev.Entries | Where-Object { $_.FullName -notmatch '/$' } | Select-Object -First 1).FullName -split '/')[0] + '/'
  $have = @{}
  foreach ($e in $arc.Entries) { $have[$e.FullName.ToLower()] = $true }
  $revIndex = @{}
  foreach ($e in $rev.Entries) {
    $n = $e.FullName
    if ($n.StartsWith($revRoot)) { $n = $n.Substring($revRoot.Length) }
    $low = $n.ToLower()
    $revIndex[$low] = @{ Entry = $e; Name = $n }
  }

  # 3. imports: "<revised path>" or "<revised path> => <destination path>" (paths relative to the pack root)
  $importList = Join-Path $here 'merge_imports.txt'
  if (Test-Path $importList) {
    foreach ($line in Get-Content $importList) {
      $l = $line.Trim()
      if ($l -eq '' -or $l.StartsWith('#')) { continue }
      $src, $dst = $l, $null
      if ($l.Contains('=>')) { $p = $l -split '=>'; $src = $p[0].Trim(); $dst = $p[1].Trim() }
      $r = $revIndex[$src.ToLower()]
      if (-not $r) { throw "import source not in Revised pack: $src" }
      if (-not $dst) { $dst = $r.Name }
      $full = $mainRoot + $dst
      if ($have.ContainsKey($full.ToLower())) { $log.skipped += "$dst (exists in Main, Main wins)"; continue }
      $ne = $arc.CreateEntry($full, [IO.Compression.CompressionLevel]::Optimal)
      $in = $r.Entry.Open(); $outs = $ne.Open(); $in.CopyTo($outs); $outs.Dispose(); $in.Dispose()
      $have[$full.ToLower()] = $true
      $log.imports += $dst
    }
  }

  # 4. definition snippets appended to Main files: _append/<path>
  $appendDir = Join-Path $here 'Wadfusion-Xtras-merged_uz5\_append'
  if (Test-Path $appendDir) {
    foreach ($f in Get-ChildItem $appendDir -Recurse -File) {
      $rel = $f.FullName.Substring($appendDir.Length + 1).Replace('\', '/')
      $old = $arc.Entries | Where-Object { $_.FullName -ieq ($mainRoot + $rel) } | Select-Object -First 1
      if (-not $old) { throw "append target not found in pack: $rel" }
      $sr = New-Object IO.StreamReader($old.Open(), [Text.Encoding]::GetEncoding(1252)); $text = $sr.ReadToEnd(); $sr.Dispose()
      $name = $old.FullName; $old.Delete()
      $add = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::GetEncoding(1252))
      if (-not $text.EndsWith("`n")) { $text += "`r`n" }
      $text += $add
      $ne = $arc.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
      $sw = New-Object IO.StreamWriter($ne.Open(), [Text.Encoding]::GetEncoding(1252)); $sw.Write($text); $sw.Dispose()
      $log.appends += $rel
    }
  }

  # 4b. new definition lumps (for example SNDINFO.RevisedMerge): _new/<path>, must not exist yet
  $newDir = Join-Path $here 'Wadfusion-Xtras-merged_uz5\_new'
  if (Test-Path $newDir) {
    foreach ($f in Get-ChildItem $newDir -Recurse -File) {
      $rel = $f.FullName.Substring($newDir.Length + 1).Replace('\', '/')
      if ($have.ContainsKey(($mainRoot + $rel).ToLower())) { throw "new lump already exists in Main: $rel" }
      [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arc, $f.FullName, $mainRoot + $rel, [IO.Compression.CompressionLevel]::Optimal)
      $have[($mainRoot + $rel).ToLower()] = $true
      $log.appends += "new:$rel"
    }
  }

  # 5. whole-file overlays
  $ov = Join-Path $here 'Wadfusion-Xtras-merged_uz5'
  if (Test-Path $ov) {
    foreach ($f in Get-ChildItem $ov -Recurse -File) {
      if ($f.FullName.StartsWith((Join-Path $ov '_append')) -or $f.FullName.StartsWith((Join-Path $ov '_new'))) { continue }
      $rel = $f.FullName.Substring($ov.Length + 1).Replace('\', '/')
      $old = $arc.Entries | Where-Object { $_.FullName -ieq ($mainRoot + $rel) } | Select-Object -First 1
      $name = if ($old) { $old.FullName } else { $mainRoot + $rel }
      if ($old) { $old.Delete() }
      [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($arc, $f.FullName, $name, [IO.Compression.CompressionLevel]::Optimal)
      $log.overlays += $rel
    }
  }
} finally { $rev.Dispose(); $arc.Dispose() }

$outHash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLower()
$info = [ordered]@{ built = (Get-Date).ToString('s'); inputs = [ordered]@{ main = $mainHash; revised = $revHash }; output_sha256 = $outHash;
                    imports = $log.imports; appends = $log.appends; overlays = $log.overlays; skipped = $log.skipped }
($info | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath "$Out.build.json" -Encoding UTF8
if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out -Force }
Move-Item -LiteralPath $tmp -Destination $Out
"built $Out  imports=$($log.imports.Count) appends=$($log.appends.Count) overlays=$($log.overlays.Count) skipped=$($log.skipped.Count)"
