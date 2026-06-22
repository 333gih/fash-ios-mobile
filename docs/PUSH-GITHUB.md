# Push iOS app lên GitHub (Actions CI / TestFlight)

## Trạng thái hiện tại

| Item | Giá trị |
|------|---------|
| GitHub repo | `fashandcurious14052026-dotcom/fash-ios-mobile` (đã tồn tại) |
| Remote | `git remote github` |
| Workflows | `ios-build.yml` (simulator), `ios-release.yml` (IPA + TestFlight) |

## Bước 1 — Đăng nhập GitHub CLI

```powershell
gh auth login
# Tài khoản: fashandcurious14052026-dotcom
gh auth setup-git
gh auth status
```

Lỗi `Permission denied to 333gih` → `gh auth logout` rồi login lại đúng org account.

## Bước 2 — Push code lên GitHub

```powershell
cd fash-ios-mobile
.\scripts\mirror-to-github.ps1
# Hoặc chỉ nhánh release:
.\scripts\mirror-to-github.ps1 -Branches releases/1.0
```

Thủ công:

```powershell
git push -u github develop
git push -u github releases/1.0
```

## Bước 3 — Secrets (TestFlight)

```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo fashandcurious14052026-dotcom/fash-ios-mobile
# Hoặc:
.\scripts\mirror-to-github.ps1 -PushSecrets
```

```powershell
gh secret list -R fashandcurious14052026-dotcom/fash-ios-mobile
```

## Bước 4 — Chạy CI / TestFlight

| Trigger | Workflow | Kết quả |
|---------|----------|---------|
| Push `develop` | iOS Build | Simulator compile |
| Push `releases/**` | iOS Release | IPA + **TestFlight** (auto) |
| Manual | iOS Release | Chọn scheme + upload TestFlight |

```powershell
gh workflow run ios-release.yml -R fashandcurious14052026-dotcom/fash-ios-mobile --ref releases/1.0 -f scheme=Fash-Prod -f upload_testflight=true
gh run list -R fashandcurious14052026-dotcom/fash-ios-mobile --limit 5
gh run watch -R fashandcurious14052026-dotcom/fash-ios-mobile
```

Chi tiết: [CI.md](./CI.md), [run.md](../run.md).
