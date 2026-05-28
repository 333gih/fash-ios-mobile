# Sync iOS AppIcon.appiconset from fash-android-mobile launcher assets (no separate iOS generator).
# Usage: .\scripts\sync_app_icon_from_android.ps1 [-AndroidRoot D:\Project\fash\fash-android-mobile]
param(
    [string]$AndroidRoot = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "fash-android-mobile")
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$outDir = Join-Path $Root "Fash\Assets.xcassets\AppIcon.appiconset"

$candidates = @(
    (Join-Path $AndroidRoot "app\src\main\res\drawable\ic_launcher_brand.png"),
    (Join-Path $AndroidRoot "app\src\main\res\drawable-xxhdpi\ic_launcher_brand.png"),
    (Join-Path $AndroidRoot "app\src\main\res\drawable-xxxhdpi\ic_launcher_brand.png"),
    (Join-Path $AndroidRoot "app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"),
    (Join-Path $AndroidRoot "app\src\main\res\mipmap-xxhdpi\ic_launcher.png")
)

$srcPath = $null
foreach ($c in $candidates) {
    if (Test-Path $c) { $srcPath = $c; break }
}

if (-not $srcPath) {
    $gen = Join-Path $AndroidRoot "tools\generate_launcher_mipmap.ps1"
    if (Test-Path $gen) {
        Write-Host "Android mipmap missing - running $gen"
        & $gen
        $srcPath = Join-Path $AndroidRoot "app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
    }
}

if (-not (Test-Path $srcPath)) {
    Write-Error @"
Android launcher icon not found. Expected one of:
  drawable/ic_launcher_brand.png
  mipmap-xxxhdpi/ic_launcher.png
Run in fash-android-mobile: powershell -File tools/generate_launcher_mipmap.ps1
"@
}

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

Add-Type -AssemblyName System.Drawing
# Matches Android ic_launcher_background (#F04170). App Store requires opaque RGB (no alpha).
$bgColor = [System.Drawing.Color]::FromArgb(255, 0xF0, 0x41, 0x70)

function Save-AppIconPng {
    param([string]$name, [int]$px, [System.Drawing.Image]$src)
    $canvas = New-Object System.Drawing.Bitmap $px, $px, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.Clear($bgColor)
    $scale = [Math]::Min($px / $src.Width, $px / $src.Height)
    $newW = [int][Math]::Round($src.Width * $scale)
    $newH = [int][Math]::Round($src.Height * $scale)
    $x = [int][Math]::Round(($px - $newW) / 2.0)
    $y = [int][Math]::Round(($px - $newH) / 2.0)
    $g.DrawImage($src, $x, $y, $newW, $newH)
    $path = Join-Path $outDir $name
    $canvas.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $canvas.Dispose()
    Write-Host ('  ' + $name + ' (' + $px + 'x' + $px + ')')
}

$src = [System.Drawing.Image]::FromFile($srcPath)
Write-Host ('Source: ' + $srcPath + ' (' + $src.Width + 'x' + $src.Height + ')')
Write-Host "Writing AppIcon.appiconset:"
Save-AppIconPng "AppIcon-40.png" 40 $src
Save-AppIconPng "AppIcon-58.png" 58 $src
Save-AppIconPng "AppIcon-60.png" 60 $src
Save-AppIconPng "AppIcon-80.png" 80 $src
Save-AppIconPng "AppIcon-87.png" 87 $src
Save-AppIconPng "AppIcon-120.png" 120 $src
Save-AppIconPng "AppIcon-152.png" 152 $src
Save-AppIconPng "AppIcon-167.png" 167 $src
Save-AppIconPng "AppIcon-180.png" 180 $src
Save-AppIconPng "AppIcon-1024.png" 1024 $src
$src.Dispose()

$contents = @'
{
  "images" : [
    { "filename" : "AppIcon-40.png", "idiom" : "iphone", "scale" : "2x", "size" : "20x20" },
    { "filename" : "AppIcon-60.png", "idiom" : "iphone", "scale" : "3x", "size" : "20x20" },
    { "filename" : "AppIcon-58.png", "idiom" : "iphone", "scale" : "2x", "size" : "29x29" },
    { "filename" : "AppIcon-87.png", "idiom" : "iphone", "scale" : "3x", "size" : "29x29" },
    { "filename" : "AppIcon-80.png", "idiom" : "iphone", "scale" : "2x", "size" : "40x40" },
    { "filename" : "AppIcon-120.png", "idiom" : "iphone", "scale" : "3x", "size" : "40x40" },
    { "filename" : "AppIcon-120.png", "idiom" : "iphone", "scale" : "2x", "size" : "60x60" },
    { "filename" : "AppIcon-180.png", "idiom" : "iphone", "scale" : "3x", "size" : "60x60" },
    { "filename" : "AppIcon-152.png", "idiom" : "ipad", "scale" : "2x", "size" : "76x76" },
    { "filename" : "AppIcon-167.png", "idiom" : "ipad", "scale" : "2x", "size" : "83.5x83.5" },
    { "filename" : "AppIcon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
'@
Set-Content -Path (Join-Path $outDir "Contents.json") -Value $contents -Encoding UTF8
Write-Host 'Done. Commit Fash/Assets.xcassets/AppIcon.appiconset/*.png'
