#Requires -Version 5.1
<#
.SYNOPSIS
  LOCAL ONLY — sync from fash-android-mobile into this repo, then COMMIT before push/CI.

  GitHub Actions does NOT run this. TestFlight uses committed:
    vendor/android-res/
    Fash/Resources/*.lproj/
    Fash/Localization/L10n.swift
    Fash/Assets.xcassets/AppIcon.appiconset/
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$python = $null
foreach ($cmd in @("python3", "python")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $python = $cmd
        break
    }
}
if (-not $python) {
    Write-Error "Python 3 not found. Install from https://www.python.org/downloads/"
}

$androidRoot = $env:FASH_ANDROID_ROOT
if (-not $androidRoot) {
    $sibling = Join-Path (Split-Path $Root -Parent) "fash-android-mobile"
    if (Test-Path $sibling) {
        $androidRoot = $sibling
        $env:FASH_ANDROID_ROOT = $androidRoot
    }
}
if (-not $androidRoot) {
    Write-Error "Set FASH_ANDROID_ROOT to fash-android-mobile (required for local sync)."
}

Write-Host "LOCAL sync from: $androidRoot"
& $python (Join-Path $Root "scripts\sync_from_android.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $python (Join-Path $Root "scripts\env_to_xcconfig.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Done. COMMIT before push (CI uses committed files only):"
Write-Host "  vendor/android-res/"
Write-Host "  Fash/Resources/*.lproj/Localizable.strings"
Write-Host "  Fash/Localization/L10n.swift"
Write-Host "  Fash/Assets.xcassets/AppIcon.appiconset/*.png"
Write-Host "  Config/*.xcconfig (if env changed)"
