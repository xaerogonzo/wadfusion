<#
.SYNOPSIS
  Builds the WadFusion release packages on Windows (no 7-Zip needed).

.DESCRIPTION
  Mirrors windows_build.bat, using only PowerShell + Python:
    1. builds doom_fusion_widescreen_gfx.pk3 from ultrawiderpix/
    2. runs PyInstaller with wadfusion.spec  -> wadfusion.exe
    3. packages wadfusion_win.zip (exe, README, CHANGES, licenses.zip,
       widescreen pk3, source_wads/place_wads_here.txt)
    4. packages wadfusion_py.zip (Python source release for macOS / Linux)

  Requires Python 3 with PyInstaller installed in the interpreter given by -Python.

.EXAMPLE
  python -m venv .venv-build
  .venv-build\Scripts\python -m pip install pyinstaller
  .\build_release.ps1 -Python .venv-build\Scripts\python.exe
#>
param(
    [string]$Python = 'python',
    [string]$OutDir = 'release'
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem

function New-ZipFromDir($dir, $zipPath) {
    if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath }
    [IO.Compression.ZipFile]::CreateFromDirectory((Resolve-Path $dir).Path, $zipPath,
        [IO.Compression.CompressionLevel]::Optimal, $false)
}

$proj = 'wadfusion'
$wide = 'doom_fusion_widescreen_gfx.pk3'
$stage = Join-Path $OutDir 'stage'
if (Test-Path $OutDir) { Remove-Item $OutDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutDir, $stage | Out-Null

# 1. widescreen graphics pk3 (ultrawiderpix + its license text)
Write-Host '== Widescreen graphics pk3'
$wideTmp = Join-Path $stage '_wide'
Copy-Item ultrawiderpix $wideTmp -Recurse
Copy-Item licenses\*wide*pix*.txt $wideTmp -ErrorAction SilentlyContinue
New-ZipFromDir $wideTmp (Join-Path $OutDir $wide)
Remove-Item $wideTmp -Recurse -Force

# 2. licenses.zip
New-ZipFromDir licenses (Join-Path $OutDir 'licenses.zip')

# 3. Windows exe
Write-Host '== PyInstaller'
Get-ChildItem omg -Recurse -Directory -Filter __pycache__ | Remove-Item -Recurse -Force
& $Python -m PyInstaller --noconfirm --distpath (Join-Path $stage 'dist') --workpath (Join-Path $stage 'build') "$proj.spec"
if ($LASTEXITCODE -ne 0) { throw 'PyInstaller failed' }

$win = Join-Path $stage 'win'
New-Item -ItemType Directory -Path (Join-Path $win 'source_wads') | Out-Null
Copy-Item (Join-Path $stage "dist\$proj.exe") $win
Copy-Item README.md, CHANGES.md $win
Copy-Item source_wads\place_wads_here.txt (Join-Path $win 'source_wads')
Copy-Item (Join-Path $OutDir $wide), (Join-Path $OutDir 'licenses.zip') $win
New-ZipFromDir $win (Join-Path $OutDir "${proj}_win.zip")

# 4. Python source release
Write-Host '== Python source package'
$py = Join-Path $stage 'py'
New-Item -ItemType Directory -Path (Join-Path $py 'source_wads') | Out-Null
foreach ($d in 'data', 'omg', 'res') { Copy-Item $d (Join-Path $py $d) -Recurse }
Get-ChildItem $py -Recurse -Directory -Filter __pycache__ | Remove-Item -Recurse -Force
Copy-Item README.md, CHANGES.md, "$proj.py" $py
Copy-Item source_wads\place_wads_here.txt (Join-Path $py 'source_wads')
Copy-Item (Join-Path $OutDir $wide), (Join-Path $OutDir 'licenses.zip') $py
New-ZipFromDir $py (Join-Path $OutDir "${proj}_py.zip")

Remove-Item $stage -Recurse -Force
Write-Host "`nDone. Release files in '$OutDir':"
Get-ChildItem $OutDir | ForEach-Object { '{0,-36} {1,10:N1} MiB' -f $_.Name, ($_.Length / 1MB) }
