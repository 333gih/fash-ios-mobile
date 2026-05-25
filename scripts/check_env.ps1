#Requires -Version 5.1
<#
.SYNOPSIS
  Check whether this machine can build the Fash iOS app.
.DESCRIPTION
  iOS/SwiftUI apps require macOS + Xcode. On Windows this script validates
  prep steps (Python sync) and reports blockers for a full build.
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function Write-Status([string]$Label, [bool]$Ok, [string]$Detail = "") {
    $icon = if ($Ok) { "[OK]" } else { "[!!]" }
    $line = "$icon $Label"
    if ($Detail) { $line += ": $Detail" }
    Write-Host $line
}

Write-Host ""
Write-Host "Fash iOS - environment check"
Write-Host "Root: $Root"
Write-Host ""

$isMac = ($env:OS -eq "Darwin") -or (Test-Path "/Applications/Xcode.app")
$isWindows = $env:OS -match "Windows"

Write-Status "Platform" $true $(if ($isMac) { "macOS" } elseif ($isWindows) { "Windows" } else { "Other" })

# Python (sync scripts)
$pythonOk = $false
$pythonCmd = $null
foreach ($cmd in @("python3", "python")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $pythonCmd = $cmd
        $pythonOk = $true
        break
    }
}
$pythonDetail = if ($pythonOk) { (& $pythonCmd --version 2>&1) } else { "not found (install Python 3.10+)" }
Write-Status "Python" $pythonOk $pythonDetail

# Swift (informational on Windows; required on Mac via Xcode toolchain)
$swiftOk = $false
$swiftDetail = "not found"
if (Get-Command swift -ErrorAction SilentlyContinue) {
    try {
        $swiftOut = & swift --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $swiftOut) {
            $swiftOk = $true
            $swiftDetail = ($swiftOut | Select-Object -First 1).ToString()
        } else {
            $swiftDetail = "installed but swift --version failed (exit $LASTEXITCODE); use Xcode on Mac"
        }
    } catch {
        $swiftDetail = "installed but crashes; iOS build needs macOS + Xcode"
    }
}
Write-Status "Swift CLI" $swiftOk $swiftDetail

# Xcode (required for iOS build)
$xcodeOk = $false
$xcodeDetail = "not found (required for iOS build)"
if (Get-Command xcodebuild -ErrorAction SilentlyContinue) {
    try {
        $xb = & xcodebuild -version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $xcodeOk = $true
            $xcodeDetail = ($xb | Select-Object -First 1).ToString()
        }
    } catch {
        $xcodeDetail = "xcodebuild present but failed"
    }
}
Write-Status "Xcode (xcodebuild)" $xcodeOk $xcodeDetail

# XcodeGen
$xgenOk = $false
$xgenDetail = "not found (install: brew install xcodegen)"
if (Get-Command xcodegen -ErrorAction SilentlyContinue) {
    $xgenOk = $true
    $xgenDetail = (& xcodegen --version 2>&1 | Select-Object -First 1).ToString()
}
Write-Status "XcodeGen" $xgenOk $xgenDetail

# Generated Xcode project
$projOk = Test-Path (Join-Path $Root "Fash.xcodeproj")
$projDetail = if ($projOk) { "present" } else { "missing (run xcodegen on Mac or ./scripts/setup_mac.sh)" }
Write-Status "Fash.xcodeproj" $projOk $projDetail

# Env (vendored in-repo; Android sibling optional for maintainer sync)
$envOk = (Test-Path (Join-Path $Root "env\dev.env")) -and (Test-Path (Join-Path $Root "env\prod.env"))
$envDetail = if ($envOk) { "env/dev.env + env/prod.env (standalone)" } else { "missing env/ — run scripts/vendor_from_android.py" }
Write-Status "iOS env/*.env" $envOk $envDetail

# Fonts (manual copy)
$fontsDir = Join-Path $Root "Fash\Resources\Fonts"
$fontFiles = @(
    "BeVietnamPro-Regular.ttf",
    "BeVietnamPro-SemiBold.ttf",
    "BeVietnamPro-Bold.ttf"
)
$missingFonts = @($fontFiles | Where-Object { -not (Test-Path (Join-Path $fontsDir $_)) })
$fontsOk = ($missingFonts.Count -eq 0)
$fontsDetail = if ($fontsOk) { "all present" } else { "missing: $($missingFonts -join ', ') (copy from Android res/font/)" }
Write-Status "Be Vietnam Pro fonts" $fontsOk $fontsDetail

Write-Host ""
Write-Host "Summary"
Write-Host "-------"

if ($isMac -and $xcodeOk -and $xgenOk) {
    if (-not $projOk) {
        Write-Host "Ready for setup. Run:  ./scripts/build_mac.sh"
    } else {
        Write-Host "Ready to build. Run:  ./scripts/build_mac.sh"
    }
} elseif ($isWindows) {
    Write-Host "Full iOS build is NOT supported on Windows (needs macOS + Xcode)."
    Write-Host "On this machine you CAN run prep/sync:"
    Write-Host "  .\scripts\sync.ps1"
    Write-Host "Then on a Mac:"
    Write-Host "  ./scripts/build_mac.sh"
} else {
    Write-Host "Install Xcode + XcodeGen on macOS, then run ./scripts/build_mac.sh"
}

Write-Host ""
$canBuild = $isMac -and $xcodeOk -and $xgenOk
if (-not $canBuild) { exit 1 }
exit 0
