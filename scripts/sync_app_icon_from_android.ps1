# Sync iOS App Store icon from Android launcher (mipmap-xxxhdpi).
# Usage: .\scripts\sync_app_icon_from_android.ps1 [-AndroidRoot D:\Project\fash\fash-android-mobile]
param(
    [string]$AndroidRoot = "D:\Project\fash\fash-android-mobile"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$srcPath = Join-Path $AndroidRoot "app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
$dstPath = Join-Path $Root "Fash\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png"

if (-not (Test-Path $srcPath)) {
    Write-Error "Android icon not found: $srcPath"
}

Add-Type -AssemblyName System.Drawing
# Matches Android ic_launcher_background (#F04170). App Store requires opaque RGB (no alpha).
$bgColor = [System.Drawing.Color]::FromArgb(255, 0xF0, 0x41, 0x70)
$src = [System.Drawing.Image]::FromFile($srcPath)
$srcW = $src.Width
$srcH = $src.Height
$canvas = New-Object System.Drawing.Bitmap 1024, 1024, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.Clear($bgColor)
$scale = [Math]::Min(1024.0 / $srcW, 1024.0 / $srcH)
$newW = [int][Math]::Round($srcW * $scale)
$newH = [int][Math]::Round($srcH * $scale)
$x = [int][Math]::Round((1024 - $newW) / 2.0)
$y = [int][Math]::Round((1024 - $newH) / 2.0)
$g.DrawImage($src, $x, $y, $newW, $newH)
$canvas.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $canvas.Dispose(); $src.Dispose()
Write-Host "Wrote $dstPath (1024x1024 RGB, no alpha) from $srcPath (${srcW}x${srcH})"
