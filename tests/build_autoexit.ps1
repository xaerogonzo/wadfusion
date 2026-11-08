# Builds the throwaway auto-exit test pack used by the Full Run tests.
param([string]$Out = (Join-Path $PSScriptRoot 'autoexit.pk3'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $Out) { Remove-Item $Out }
[IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $PSScriptRoot 'autoexit'), $Out)
$Out
