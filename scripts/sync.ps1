#Requires -Version 5.1
<#
.SYNOPSIS
  Sync i18n strings and build config from Android (Windows/macOS/Linux).
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

Write-Host "Syncing strings and build config..."
& $python (Join-Path $Root "scripts\android_strings_to_ios.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $python (Join-Path $Root "scripts\env_to_xcconfig.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Done. Generated:"
Write-Host "  - Fash/Resources/*.lproj/Localizable.strings"
Write-Host "  - Fash/Localization/L10n.swift"
Write-Host "  - Config/*.xcconfig"
Write-Host "  - Fash/config/generated/GeneratedBuildConfig_*.swift"
Write-Host ""
Write-Host "Next (Mac only): ./scripts/build_mac.sh"
