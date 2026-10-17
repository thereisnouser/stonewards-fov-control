[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir,

    [Parameter(Mandatory = $true)]
    [string]$ProfileDir
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$GameDir = (Resolve-Path -LiteralPath $GameDir).Path
$ProfileDir = (Resolve-Path -LiteralPath $ProfileDir).Path

$managedDir = Join-Path $GameDir 'Stonewards_Data\Managed'
$coreDir = Join-Path $ProfileDir 'BepInEx\core'
$project = Join-Path $PSScriptRoot 'src\StonewardsFOVPlus\StonewardsFOVPlus.csproj'
$pluginDir = Join-Path $ProfileDir 'BepInEx\plugins\StonewardsFOVPlus'

foreach ($required in @(
    (Join-Path $managedDir 'UnityEngine.dll'),
    (Join-Path $managedDir 'UnityEngine.CoreModule.dll'),
    (Join-Path $coreDir 'BepInEx.dll'),
    (Join-Path $coreDir '0Harmony.dll')
)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Missing dependency: $required"
    }
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'dotnet SDK not found. Install .NET SDK 8 or newer.'
}

Write-Host 'Building Stonewards FOV Plus (Release)...'
& dotnet build $project --configuration Release "-p:GameDir=$GameDir" "-p:ProfileDir=$ProfileDir"
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build failed (exit code $LASTEXITCODE)."
}

$dll = Join-Path $PSScriptRoot 'src\StonewardsFOVPlus\bin\Release\netstandard2.1\StonewardsFOVPlus.dll'
if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) {
    throw "Build output missing: $dll"
}

# Remove the v0.1.0 prototype DLL if the old name was installed in this same profile.
# Two copies would patch the same FOV getter.
$legacyDir = Join-Path $ProfileDir 'BepInEx\plugins\StonewardsFOVControl'
$legacyDll = Join-Path $legacyDir 'StonewardsFOVControl.dll'
if (Test-Path -LiteralPath $legacyDll -PathType Leaf) {
    Remove-Item -LiteralPath $legacyDll -Force
    Write-Host "Removed previous DLL: $legacyDll"
    if (@(Get-ChildItem -LiteralPath $legacyDir -Force).Count -eq 0) {
        Remove-Item -LiteralPath $legacyDir -Force
    }
}

New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
Copy-Item -LiteralPath $dll -Destination (Join-Path $pluginDir 'StonewardsFOVPlus.dll') -Force

Write-Host ''
Write-Host 'Installed:' -ForegroundColor Green
Write-Host (Join-Path $pluginDir 'StonewardsFOVPlus.dll')
Write-Host "Open the game's native FOV slider in Settings; its maximum should be 150."
