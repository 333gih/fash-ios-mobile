# Fash iOS - pre-push gate (Windows / no Mac, no bash required)
# Usage: .\scripts\check_before_push.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Write-Step { param([string]$Name) Write-Host "`n==> $Name" -ForegroundColor Cyan }

function Invoke-PythonStep {
    param([string]$Name, [string[]]$PythonArgs)
    Write-Step $Name
    & python @PythonArgs
    if ($LASTEXITCODE -ne 0) { Fail $Name $LASTEXITCODE }
}

function Fail {
    param([string]$Name, [int]$Code)
    Write-Host "`nFAILED: $Name (exit $Code)" -ForegroundColor Red
    Write-Host "See docs/BUILD_CHECKLIST.md and docs/CURSOR_DEVELOPMENT.md" -ForegroundColor Yellow
    exit $Code
}

function Test-CommittedFiles {
    Write-Step "Committed i18n + AppIcon files"
    $required = @(
        "vendor/android-res/values/strings.xml",
        "vendor/android-res/values-en/strings.xml",
        "Fash/Resources/vi.lproj/Localizable.strings",
        "Fash/Resources/en.lproj/Localizable.strings",
        "Fash/Resources/Base.lproj/Localizable.strings",
        "Fash/Localization/L10n.swift"
    )
    foreach ($rel in $required) {
        if (-not (Test-Path (Join-Path $Root $rel))) {
            Write-Host "error: missing committed file: $rel" -ForegroundColor Red
            Write-Host "  Run: .\scripts\sync.ps1 then commit vendor/, Fash/Resources/, Fash/Localization/" -ForegroundColor Yellow
            exit 1
        }
    }
    foreach ($icon in @("AppIcon-1024.png", "AppIcon-120.png", "AppIcon-152.png")) {
        $p = Join-Path $Root "Fash/Assets.xcassets/AppIcon.appiconset/$icon"
        if (-not (Test-Path $p)) {
            Write-Host "error: missing AppIcon: $icon" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "OK: required i18n + icon files present"
}

function Invoke-BashStep {
    param([string]$Name, [string]$ScriptRel)
    Write-Step $Name

    $gitBash = @(
        "${env:ProgramFiles}\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($gitBash) {
        & $gitBash (Join-Path $Root $ScriptRel)
        if ($LASTEXITCODE -ne 0) { Fail $Name $LASTEXITCODE }
        return
    }

    Write-Host "Note: Git Bash not found - using Python fallback where available." -ForegroundColor Yellow
    if ($ScriptRel -eq "scripts/ci_validate_i18n.sh") {
        Invoke-PythonStep "validate_strings.py" @("$Root/scripts/validate_strings.py")
        Invoke-PythonStep "validate_l10n_swift.py" @("$Root/scripts/validate_l10n_swift.py")
        Invoke-PythonStep "compare_android_ios_strings.py" @("$Root/scripts/compare_android_ios_strings.py")
        return
    }
    if ($ScriptRel -eq "scripts/ci_swift_compile_preflight.sh") {
        Write-Host "SKIP: ci_swift_compile_preflight.sh (install Git for Windows for full preflight)" -ForegroundColor Yellow
        return
    }
    Fail $Name 1
}

Write-Host "Fash iOS pre-push gate" -ForegroundColor Green
Write-Host "Root: $Root"

Invoke-PythonStep "validate_swift_syntax.py" @("$Root/scripts/validate_swift_syntax.py")
Test-CommittedFiles
Invoke-BashStep "ci_validate_i18n (strings + L10n)" "scripts/ci_validate_i18n.sh"
Invoke-BashStep "ci_swift_compile_preflight" "scripts/ci_swift_compile_preflight.sh"

Write-Host ''
Write-Host 'OK: All pre-push checks passed.' -ForegroundColor Green
Write-Host 'Push develop -> iOS Build. TestFlight: bump CURRENT_PROJECT_VERSION, then push releases branch.' -ForegroundColor Gray
