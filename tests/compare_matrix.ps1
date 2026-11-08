<#
 Compares two transcripts written by fullrun_matrix.ps1 case by case (router decisions, hook results, errors).
 .\tests\compare_matrix.ps1 -Baseline tests\baseline_uzdoom_503.txt -New out.txt
#>
param([Parameter(Mandatory)][string]$Baseline, [Parameter(Mandatory)][string]$New)
function Get-Results($f) {
  $h = [ordered]@{}; $c = ''
  foreach ($l in Get-Content $f) {
    if ($l -match '^== (\S+)') { $c = $matches[1]; $h[$c] = New-Object System.Collections.Generic.List[string] }
    elseif ($c -and $l -match 'DCXTEST_STATE|DCXTEST exiting|errors=') { $h[$c].Add(($l.Trim() -replace '^DCXTEST exiting ', 'EXIT ')) }
  }
  $h
}
$b = Get-Results $Baseline; $n = Get-Results $New
"baseline cases: $($b.Count)  new cases: $($n.Count)"
$diff = 0
foreach ($k in $b.Keys) {
  $x = $b[$k] -join ' | '
  $y = if ($n.Contains($k)) { $n[$k] -join ' | ' } else { '(missing)' }
  if ($x -ne $y) { $diff++; "DIFF $k`n   base: $x`n   new : $y" }
}
"differing cases: $diff"
exit $diff
