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
$project = Join-Path $PSScriptRoot 'src\StonewardsFOVControl\StonewardsFOVControl.csproj'
$pluginDir = Join-Path $ProfileDir 'BepInEx\plugins\StonewardsFOVControl'

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

Write-Host 'Building Stonewards FOV Control (Release)...'
& dotnet build $project --configuration Release "-p:GameDir=$GameDir" "-p:ProfileDir=$ProfileDir"
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build failed (exit code $LASTEXITCODE)."
}

$dll = Join-Path $PSScriptRoot 'src\StonewardsFOVControl\bin\Release\netstandard2.1\StonewardsFOVControl.dll'
if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) {
    throw "Build output missing: $dll"
}

New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
Copy-Item -LiteralPath $dll -Destination (Join-Path $pluginDir 'StonewardsFOVControl.dll') -Force

Write-Host ''
Write-Host 'Installed:' -ForegroundColor Green
Write-Host (Join-Path $pluginDir 'StonewardsFOVControl.dll')
Write-Host 'Open the game's native FOV slider in Settings; its maximum should be 150.'
