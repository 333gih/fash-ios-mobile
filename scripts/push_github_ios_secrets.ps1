# Push iOS release secrets from secrets/ios-release.env to GitHub Actions.
# Usage: .\scripts\push_github_ios_secrets.ps1 [-EnvFile secrets\ios-release.env] [-Repo owner/repo]
param(
    [string]$EnvFile = "secrets/ios-release.env",
    [string]$Repo = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) not found. Install: https://cli.github.com/ then run: gh auth login"
}

if (-not (Test-Path $EnvFile)) {
    Write-Error "Missing $EnvFile - copy secrets/ios-release.env.example to secrets/ios-release.env and fill in."
}

function Read-DotEnv([string]$Path) {
    $map = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $key = $line.Substring(0, $eq).Trim()
        $val = $line.Substring($eq + 1).Trim()
        $dq = [char]34
        if ($val.StartsWith($dq) -and $val.EndsWith($dq)) {
            $val = $val.Substring(1, $val.Length - 2).Replace('\n', "`n")
        }
        $map[$key] = $val
    }
    return $map
}

function To-Base64File([string]$RelativePath) {
    $full = Join-Path $Root ($RelativePath -replace "/", "\")
    if (-not (Test-Path $full)) {
        Write-Error "File not found: $full"
    }
    return [Convert]::ToBase64String([IO.File]::ReadAllBytes($full))
}

$envMap = Read-DotEnv $EnvFile
$repoArg = @()
if ($Repo -ne "") { $repoArg = @("-R", $Repo) }

function Set-GhSecret([string]$Name, [string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "skip $Name (empty)"
        return
    }
    Write-Host "set  $Name"
    $Value | gh secret set $Name @repoArg
}

# Plain text secrets
Set-GhSecret "APPLE_TEAM_ID" $envMap["APPLE_TEAM_ID"]
Set-GhSecret "IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" $envMap["IOS_DISTRIBUTION_CERTIFICATE_PASSWORD"]
Set-GhSecret "IOS_PROVISIONING_PROFILE_SPECIFIER" $envMap["IOS_PROVISIONING_PROFILE_SPECIFIER"]
Set-GhSecret "APP_STORE_CONNECT_ISSUER_ID" $envMap["APP_STORE_CONNECT_ISSUER_ID"]
Set-GhSecret "APP_STORE_CONNECT_API_KEY_ID" $envMap["APP_STORE_CONNECT_API_KEY_ID"]

# Certificate base64
$certB64 = $envMap["IOS_DISTRIBUTION_CERTIFICATE_BASE64"]
if ([string]::IsNullOrWhiteSpace($certB64) -and $envMap["IOS_DISTRIBUTION_CERTIFICATE_PATH"]) {
    $certB64 = To-Base64File $envMap["IOS_DISTRIBUTION_CERTIFICATE_PATH"]
}
Set-GhSecret "IOS_DISTRIBUTION_CERTIFICATE_BASE64" $certB64

# Profile base64
$profileB64 = $envMap["IOS_PROVISIONING_PROFILE_BASE64"]
if ([string]::IsNullOrWhiteSpace($profileB64) -and $envMap["IOS_PROVISIONING_PROFILE_PATH"]) {
    $profileB64 = To-Base64File $envMap["IOS_PROVISIONING_PROFILE_PATH"]
}
Set-GhSecret "IOS_PROVISIONING_PROFILE_BASE64" $profileB64

# App Store Connect .p8
$p8 = $envMap["APP_STORE_CONNECT_API_PRIVATE_KEY"]
if ([string]::IsNullOrWhiteSpace($p8) -and $envMap["APP_STORE_CONNECT_API_PRIVATE_KEY_PATH"]) {
    $p8Path = Join-Path $Root ($envMap["APP_STORE_CONNECT_API_PRIVATE_KEY_PATH"] -replace "/", "\")
    if (Test-Path $p8Path) { $p8 = Get-Content -Raw $p8Path }
}
Set-GhSecret "APP_STORE_CONNECT_API_PRIVATE_KEY" $p8

# Firebase GoogleService-Info.plist (FCM push in TestFlight builds)
$plistB64 = $envMap["GOOGLE_SERVICE_INFO_PLIST_BASE64"]
if ([string]::IsNullOrWhiteSpace($plistB64) -and $envMap["GOOGLE_SERVICE_INFO_PLIST_PATH"]) {
    $plistB64 = To-Base64File $envMap["GOOGLE_SERVICE_INFO_PLIST_PATH"]
}
Set-GhSecret "GOOGLE_SERVICE_INFO_PLIST_BASE64" $plistB64

Write-Host ""
Write-Host "Done. Verify: gh secret list @repoArg"
Write-Host "Then: Actions -> iOS Release -> Run workflow"
