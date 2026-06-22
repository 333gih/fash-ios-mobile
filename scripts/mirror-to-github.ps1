# Mirror fash-ios-mobile → GitHub (triggers Actions after push).
#
# Prerequisites:
#   gh auth login   # account fashandcurious14052026-dotcom (write access)
#
# Usage:
#   .\scripts\mirror-to-github.ps1
#   .\scripts\mirror-to-github.ps1 -Branches develop,releases/1.0
#   .\scripts\mirror-to-github.ps1 -PushSecrets
#   .\scripts\mirror-to-github.ps1 -PushTags
param(
    [string]$Repo = "fashandcurious14052026-dotcom/fash-ios-mobile",
    [string]$Branches = "develop,main,releases/1.0",
    [switch]$PushSecrets,
    [switch]$PushTags
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "Install GitHub CLI: https://cli.github.com/ then run: gh auth login"
}

$ghUser = (gh api user -q .login 2>$null)
if (-not $ghUser) {
    Write-Error "Not logged in. Run: gh auth login"
}
Write-Host "GitHub CLI user: $ghUser"

gh repo view $Repo 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Repo $Repo not found or no access. Create on GitHub or fix gh auth login."
}

$remoteUrl = "https://github.com/$Repo.git"
if ((git remote) -notcontains "github") {
    git remote add github $remoteUrl
} else {
    git remote set-url github $remoteUrl
}

gh auth setup-git 2>$null | Out-Null

$branchList = $Branches -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
foreach ($b in $branchList) {
    if (-not (git rev-parse --verify "refs/heads/$b" 2>$null)) {
        Write-Warning "Skip branch (not local): $b"
        continue
    }
    Write-Host "Pushing branch: $b"
    git push -u github "refs/heads/${b}:refs/heads/${b}"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git push failed for $b — login as fashandcurious14052026-dotcom (current: $ghUser)"
    }
}

if ($PushTags) {
    git tag -l "ios/v*" | ForEach-Object {
        git push github "refs/tags/${_}:refs/tags/${_}"
    }
}

if ($PushSecrets) {
    $secretsScript = Join-Path $Root "scripts\push_github_ios_secrets.ps1"
    if ((Test-Path $secretsScript) -and (Test-Path "secrets\ios-release.env")) {
        & $secretsScript -Repo $Repo
    } else {
        Write-Warning "Skip secrets — need secrets\ios-release.env and push_github_ios_secrets.ps1"
    }
}

Write-Host ""
Write-Host "Done. Check Actions:"
Write-Host "  gh run list -R $Repo --limit 5"
Write-Host ""
Write-Host "Manual TestFlight:"
Write-Host "  gh workflow run ios-release.yml -R $Repo --ref releases/1.0 -f scheme=Fash-Prod -f upload_testflight=true"
