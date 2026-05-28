# Generates Fash/Assets.xcassets/AppIcon.appiconset/*.png (brand hanger, matches Android launcher).
# Run: powershell -ExecutionPolicy Bypass -File scripts/generate_app_icon.ps1
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$coral = [System.Drawing.Color]::FromArgb(255, 240, 93, 94) # #F05D5E
$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)

function New-HangerIconBitmap {
    param([int]$size)
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.Clear($white)
    $brush = New-Object System.Drawing.SolidBrush($coral)
    $s = $size / 108.0

    $hookW = 14 * $s
    $hookH = 14 * $s
    $hookX = (54 * $s) - ($hookW / 2)
    $hookY = 12 * $s
    $g.FillEllipse($brush, $hookX, $hookY, $hookW, $hookH)

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pts = @(
        [System.Drawing.PointF]::new(40 * $s, 34 * $s),
        [System.Drawing.PointF]::new(30 * $s, 52 * $s),
        [System.Drawing.PointF]::new(28 * $s, 72 * $s),
        [System.Drawing.PointF]::new(36 * $s, 92 * $s),
        [System.Drawing.PointF]::new(54 * $s, 82 * $s),
        [System.Drawing.PointF]::new(72 * $s, 92 * $s),
        [System.Drawing.PointF]::new(80 * $s, 72 * $s),
        [System.Drawing.PointF]::new(78 * $s, 52 * $s),
        [System.Drawing.PointF]::new(68 * $s, 34 * $s)
    )
    $path.AddClosedCurve($pts, 0.35)
    $g.FillPath($brush, $path)

    $tw = 12 * $s
    $th = 16 * $s
    $tx = (54 * $s) - ($tw / 2)
    $ty = 42 * $s
    $g.FillEllipse($brush, $tx, $ty, $tw, $th)

    $g.Dispose()
    return $bmp
}

$root = Split-Path $PSScriptRoot -Parent
$outDir = Join-Path $root "Fash\Assets.xcassets\AppIcon.appiconset"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

function Save-Png([string]$name, [int]$px) {
    $bmp = New-HangerIconBitmap -size $px
    $path = Join-Path $outDir $name
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Wrote $path ($px x $px)"
}

# App Store + actool (single-slot catalog still needs the file on disk).
Save-Png "AppIcon-1024.png" 1024
# Legacy slots referenced by App Store validation when actool expands the set.
Save-Png "AppIcon-120.png" 120
Save-Png "AppIcon-180.png" 180

Write-Host "Done. Commit PNGs under AppIcon.appiconset before iOS Release."
