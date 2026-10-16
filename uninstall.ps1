[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfileDir
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ProfileDir = (Resolve-Path -LiteralPath $ProfileDir).Path
$pluginDir = Join-Path $ProfileDir 'BepInEx\plugins\StonewardsFOVControl'

if (Test-Path -LiteralPath $pluginDir -PathType Container) {
    Remove-Item -LiteralPath $pluginDir -Recurse -Force
    Write-Host "Removed: $pluginDir"
} else {
    Write-Host 'Stonewards FOV Control is not installed in this profile.'
}

Write-Host 'User settings were left intact in BepInEx\config.'
