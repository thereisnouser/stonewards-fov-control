[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameDir,
    [Parameter(Mandatory = $true)][string]$ProfileDir,
    [string]$IconPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = $PSScriptRoot
$project = Join-Path $root 'src\StonewardsFOVPlus\StonewardsFOVPlus.csproj'
$source = Join-Path $root 'src\StonewardsFOVPlus\FovPlusPlugin.cs'
$metadata = Join-Path $root 'thunderstore'
$manifestPath = Join-Path $metadata 'manifest.json'
$readmePath = Join-Path $metadata 'README.md'
$changelogPath = Join-Path $metadata 'CHANGELOG.md'
if ([string]::IsNullOrWhiteSpace($IconPath)) {
    $IconPath = Join-Path $metadata 'icon.png'
}

foreach ($path in @($project, $source, $manifestPath, $readmePath, $changelogPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required release file is missing: $path"
    }
}
if (-not (Test-Path -LiteralPath $IconPath -PathType Leaf)) {
    throw "FOV+ icon not found: $IconPath. Extract the release assets ZIP into the repository root so thunderstore\icon.png exists."
}

# Validate the actual, selected image. Never silently replace it with a placeholder.
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($IconPath)
try {
    if ($img.Width -ne 256 -or $img.Height -ne 256) {
        throw "FOV+ icon must be exactly 256x256 PNG; got $($img.Width)x$($img.Height)."
    }
    if ($img.RawFormat.Guid -ne [System.Drawing.Imaging.ImageFormat]::Png.Guid) {
        throw 'FOV+ icon must be a PNG.'
    }
}
finally {
    $img.Dispose()
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$version = [string]$manifest.version_number
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid manifest version: $version"
}
if ($manifest.name -ne 'FOV_Plus') {
    throw "Unexpected package name: $($manifest.name)"
}
$pluginCode = Get-Content -LiteralPath $source -Raw -Encoding UTF8
if (-not $pluginCode.Contains('private const string PluginVersion = "' + $version + '";')) {
    throw "Plugin version does not match manifest $version."
}
if (-not $pluginCode.Contains('private const int ExtendedMaximumFov = 150;')) {
    throw 'Unexpected FOV limit in the source.'
}

$GameDir = (Resolve-Path -LiteralPath $GameDir).Path
$ProfileDir = (Resolve-Path -LiteralPath $ProfileDir).Path
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'dotnet SDK not found.'
}

Write-Host "Building FOV Plus $version..." -ForegroundColor Cyan
& dotnet build $project --configuration Release "-p:GameDir=$GameDir" "-p:ProfileDir=$ProfileDir"
if ($LASTEXITCODE -ne 0) {
    throw "dotnet build failed (exit code $LASTEXITCODE)."
}

$dll = Join-Path $root 'src\StonewardsFOVPlus\bin\Release\netstandard2.1\StonewardsFOVPlus.dll'
if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) {
    throw "Compiled DLL missing: $dll"
}

$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'thunderstore-staging'
$archive = Join-Path $dist ("FOV_Plus-" + $version + '.zip')

New-Item -ItemType Directory -Path $dist -Force | Out-Null
if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}

try {
    $pluginDir = Join-Path $stage 'plugins\StonewardsFOVPlus'
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null

    Copy-Item -LiteralPath $dll -Destination (Join-Path $pluginDir 'StonewardsFOVPlus.dll')
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $stage 'manifest.json')
    Copy-Item -LiteralPath $readmePath -Destination (Join-Path $stage 'README.md')
    Copy-Item -LiteralPath $changelogPath -Destination (Join-Path $stage 'CHANGELOG.md')
    Copy-Item -LiteralPath $IconPath -Destination (Join-Path $stage 'icon.png')

    if (Test-Path -LiteralPath $archive) {
        Remove-Item -LiteralPath $archive -Force
    }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -CompressionLevel Optimal

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $entries = @($zip.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
        foreach ($required in @(
            'manifest.json', 'README.md', 'CHANGELOG.md', 'icon.png',
            'plugins/StonewardsFOVPlus/StonewardsFOVPlus.dll'
        )) {
            if ($entries -notcontains $required) {
                throw "Package ZIP is missing: $required"
            }
        }
    }
    finally {
        $zip.Dispose()
    }
}
finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}

Write-Host ''
Write-Host "Thunderstore upload ZIP: $archive" -ForegroundColor Green
Write-Host 'Contains the selected FOV+ icon, manifest, README, changelog and compiled plugin.'
