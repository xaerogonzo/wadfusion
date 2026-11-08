<#
 Runs Full Run test cases against an engine and writes a transcript (map sequence, WadFusion's chosen next map and
 ending intermission on the hack maps, error count). Diff two transcripts to check that nothing changed.

 .\tests\fullrun_matrix.ps1 -Exe "D:\...\uzdoom.exe" -Ipk ..\doom_fusion.ipk3 -Cases tests\fullrun_cases.txt -Out out.txt
 Case line:  label | start map | console vars (e.g. +wf_fullrun 1 +wf_fullrun_cast 0)
#>
param(
  [Parameter(Mandatory)][string]$Exe,
  [Parameter(Mandatory)][string]$Ipk,
  [Parameter(Mandatory)][string]$Cases,
  [Parameter(Mandatory)][string]$Out,
  [string]$Packs = '',
  [string]$Widescreen = '',
  [string]$SaveDir = (Join-Path $env:TEMP 'wf_matrix_save'),
  [string]$Only = '',
  [int]$Settle = 3,
  [string]$Fixtures = '',
  [string]$Defaults = ''
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$autoexit = & (Join-Path $here 'build_autoexit.ps1') (Join-Path $env:TEMP 'wf_autoexit.pk3')
New-Item -ItemType Directory -Force $SaveDir | Out-Null
$caseNo = 0
$result = New-Object System.Collections.Generic.List[string]
foreach ($line in Get-Content $Cases) {
  if ($line.Trim() -eq '' -or $line.TrimStart().StartsWith('#')) { continue }
  $p = $line.Split('|') | ForEach-Object { $_.Trim() }
  $label = $p[0]; $map = $p[1]; $vars = if ($p.Count -gt 2) { $p[2] } else { '' }
  # settings every case starts from, so results don't depend on an engine's saved config
  $vars = "$Defaults $vars".Trim()
  $caseFiles = if ($p.Count -gt 3) { $p[3].Replace('%FX%', $Fixtures) } else { '' }
  if ($Only -and $label -notlike $Only) { continue }
  $caseNo++
  # cases that follow the exit (dcxtest_follow) wait for the hand-over map's decision, like cases that start on one
  $hackStart = $map.ToLower().StartsWith('wf_') -or $map.ToLower() -eq 'dcx_handover' -or $vars -match 'dcxtest_follow'
  $log = Join-Path $env:TEMP ("wf_matrix_run_{0}_{1}.txt" -f $PID, $caseNo)
  $files = ''
  if ($Widescreen) { $files += " `"$Widescreen`"" }
  if ($Packs) { $files += " $Packs" }
  if ($caseFiles) { $files += " $caseFiles" }
  $a = "-iwad `"$Ipk`" -file$files `"$autoexit`" -savedir `"$SaveDir`" -stdout +wf_compat_titlepics 0 +dcxtest_exits 1 $vars +map $map"
  $pr = Start-Process $Exe -ArgumentList $a -WorkingDirectory (Split-Path $Exe) -PassThru -RedirectStandardOutput $log -RedirectStandardError "$log.err"
  $t0 = Get-Date; $lastSize = -1; $lastChange = Get-Date; $stateSeen = $false; $stateAt = $null
  while (((Get-Date) - $t0).TotalSeconds -lt 140 -and -not $pr.HasExited) {
    Start-Sleep -Seconds 2
    $size = (Get-Item $log -ErrorAction SilentlyContinue).Length
    if ($size -ne $lastSize) { $lastSize = $size; $lastChange = Get-Date }
    if ($hackStart) {
      # started on a hand-over map: the router's decision is logged on its first tick
      if (Select-String -Path $log -Pattern 'DCXTEST_STATE' -Quiet -ErrorAction SilentlyContinue) {
        if (-not $stateSeen) { $stateSeen = $true; $stateAt = Get-Date }
        elseif (((Get-Date) - $stateAt).TotalSeconds -gt $Settle) { break }
      }
      elseif (((Get-Date) - $t0).TotalSeconds -gt 90) { break }
    }
    else {
      # started on an end map: the exit report says which hand-over map its exit leads to
      if (Select-String -Path $log -Pattern 'DCXTEST exiting' -Quiet -ErrorAction SilentlyContinue) {
        if (-not $stateSeen) { $stateSeen = $true; $stateAt = Get-Date }
        elseif (((Get-Date) - $stateAt).TotalSeconds -gt $Settle) { break }
      }
      elseif (((Get-Date) - $t0).TotalSeconds -gt 90) { break }
    }
  }
  Stop-Process -Id $pr.Id -Force -ErrorAction SilentlyContinue
  [void]$pr.WaitForExit(10000)
  $l = @(Get-Content $log -ErrorAction SilentlyContinue)
  $seq = $l | Where-Object { $_ -match '^[A-Za-z0-9_]+ - ' -or $_ -match '^DCXTEST' }
  $errs = ($l | Where-Object { $_ -match 'Script error|VM execution|Unknown (class|property|identifier)|Could not' -and $_ -notmatch 'ACS:' } | Measure-Object).Count
  $result.Add("== $label  [$map $vars]")
  foreach ($s in $seq) { $result.Add('   ' + $s) }
  $result.Add("   errors=$errs")
  Write-Host ("{0,-28} {1}" -f $label, (($seq | Where-Object { $_ -match '^[A-Za-z0-9_]+ - ' } | ForEach-Object { ($_ -split ' - ')[0] }) -join ' > '))
}
Set-Content $Out $result
"Wrote $Out"
