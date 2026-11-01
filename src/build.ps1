[CmdletBinding()]
param(
    [switch]$Installer
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputRoot = Join-Path $sourceRoot 'dist'
$addonRoot = Join-Path $sourceRoot 'CharProfiles'

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
$zipPath = Join-Path $outputRoot 'CharProfiles-TBC-Classic.zip'
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path $addonRoot -DestinationPath $zipPath
Write-Host "Addon package created: $zipPath"

if ($Installer) {
    $iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if (-not $iscc) { throw 'ISCC.exe (Inno Setup 6) was not found on PATH.' }
    & $iscc.Source (Join-Path $sourceRoot 'installer\CharProfiles.iss')
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed with exit code $LASTEXITCODE." }
}
