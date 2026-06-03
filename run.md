# Đẩy secrets lên GitHub Actions (repo CI TestFlight)

```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo fashandcurious14052026-dotcom/fash-ios-mobile
```

Cần `secrets/ios-release.env` (có `GOOGLE_SERVICE_INFO_PLIST_PATH=secrets/GoogleService-Info.plist`) và `gh auth login` (tài khoản `fashandcurious14052026-dotcom`).

Kiểm tra:

```powershell
gh secret list -R fashandcurious14052026-dotcom/fash-ios-mobile
gh run list -R fashandcurious14052026-dotcom/fash-ios-mobile --branch releases/1.0 --limit 3
```

Remote CI (`git remote github`): `https://github.com/fashandcurious14052026-dotcom/fash-ios-mobile.git`. Push nhánh `releases/1.0` để trigger **iOS Release**.

Chạy lại TestFlight thủ công:

```powershell
gh workflow run ios-release.yml -R fashandcurious14052026-dotcom/fash-ios-mobile --ref releases/1.0 -f scheme=Fash-Prod -f upload_testflight=true
gh run watch -R fashandcurious14052026-dotcom/fash-ios-mobile --exit-status
```
