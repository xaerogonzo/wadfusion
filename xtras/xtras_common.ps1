# Shared helpers of the Xtras scripts (dot-sourced; needs PowerShell 7).
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

if ($PSVersionTable.PSVersion.Major -lt 7) {
  throw "These scripts need PowerShell 7 or newer (this is $($PSVersionTable.PSVersion)). Install it with: winget install Microsoft.PowerShell   then run the script from 'pwsh'."
}

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

# throws unless $path is the pinned version described by $src (an entry of xtras_sources.json)
function Test-Input($path, $src, $label) {
  if (-not (Test-Path -LiteralPath $path)) { throw "$label not found: $path" }
  $h = Get-Fingerprint $path
  if ($h -ne $src.fingerprint) {
    throw "$label is not the version this script was made for (commit $($src.commit.Substring(0,7)) of $($src.repo)). Download exactly that one: $($src.download)"
  }
  return $h
}
