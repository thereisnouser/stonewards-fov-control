[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameDir,
    [Parameter(Mandatory = $true)][string]$ProfileDir
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = $PSScriptRoot
$manifestPath = Join-Path $root 'thunderstore\manifest.json'
$readmePath = Join-Path $root 'thunderstore\README.md'
$changelogPath = Join-Path $root 'thunderstore\CHANGELOG.md'
$iconPath = Join-Path $root 'thunderstore\icon.png'
$project = Join-Path $root 'src\StonewardsFOVControl\StonewardsFOVControl.csproj'

foreach ($file in @($manifestPath, $readmePath, $changelogPath, $project)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing required file: $file" }
}

$GameDir = (Resolve-Path -LiteralPath $GameDir).Path
$ProfileDir = (Resolve-Path -LiteralPath $ProfileDir).Path
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw 'dotnet SDK is required.' }

& dotnet build $project --configuration Release "-p:GameDir=$GameDir" "-p:ProfileDir=$ProfileDir"
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed: packaging aborted.' }

$dll = Join-Path $root 'src\StonewardsFOVControl\bin\Release\netstandard2.1\StonewardsFOVControl.dll'
if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) { throw "Missing compiled DLL: $dll" }

# Generate a clean 256x256 icon when the repository does not include a custom one.
# System.Drawing is available in Windows PowerShell on Windows.
Add-Type -AssemblyName System.Drawing
if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
    $bitmap = [System.Drawing.Bitmap]::new(256, 256)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.Clear([System.Drawing.Color]::FromArgb(21, 29, 41))
        $outerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(110, 178, 187), 5)
        $innerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(211, 175, 106), 6)
        $font = [System.Drawing.Font]::new('Arial', 48, [System.Drawing.FontStyle]::Bold)
        $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(239, 236, 226))
        try {
            $graphics.DrawEllipse($outerPen, 36, 36, 184, 184)
            $graphics.DrawArc($innerPen, 60, 60, 136, 136, -120, 240)
            $graphics.DrawLine($innerPen, 128, 128, 218, 69)
            $graphics.DrawLine($innerPen, 128, 128, 218, 187)
            $graphics.DrawString('FOV', $font, $brush, 63, 95)
            $bitmap.Save($iconPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $brush.Dispose()
            $font.Dispose()
            $innerPen.Dispose()
            $outerPen.Dispose()
        }
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$bitmapCheck = [System.Drawing.Image]::FromFile($iconPath)
try {
    if ($bitmapCheck.Width -ne 256 -or $bitmapCheck.Height -ne 256) {
        throw 'Icon must be 256x256 pixels.'
    }
}
finally { $bitmapCheck.Dispose() }

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.version_number -ne '0.2.0') { throw 'Unexpected manifest version.' }
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'thunderstore-staging'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $stage 'plugins\StonewardsFOVControl') -Force | Out-Null
Copy-Item -LiteralPath $dll -Destination (Join-Path $stage 'plugins\StonewardsFOVControl\StonewardsFOVControl.dll')
foreach ($name in @('manifest.json', 'README.md', 'CHANGELOG.md', 'icon.png')) {
    Copy-Item -LiteralPath (Join-Path $root "thunderstore\$name") -Destination (Join-Path $stage $name)
}
$archive = Join-Path $dist ("FOV_Control-" + $manifest.version_number + '.zip')
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -CompressionLevel Optimal
Remove-Item -LiteralPath $stage -Recurse -Force
Write-Host "Thunderstore upload package: $archive" -ForegroundColor Green
