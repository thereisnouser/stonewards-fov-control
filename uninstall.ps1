[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileDir
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ProfileDir = (Resolve-Path -LiteralPath $ProfileDir).Path
$pluginDir = Join-Path $ProfileDir 'BepInEx\plugins\StonewardsFOVPlus'
$legacyDir = Join-Path $ProfileDir 'BepInEx\plugins\StonewardsFOVControl'
$removed = $false

foreach ($path in @($pluginDir, $legacyDir)) {
    if (Test-Path -LiteralPath $path -PathType Container) {
        Remove-Item -LiteralPath $path -Recurse -Force
        Write-Host "Removed: $path"
        $removed = $true
    }
}
if (-not $removed) {
    Write-Host 'Stonewards FOV Plus is not installed in this profile.'
}

Write-Host 'User settings were left intact in BepInEx\config.'
