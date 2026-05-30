# Đẩy secrets lên GitHub Actions (repo CI TestFlight)

```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo hochanhphuc7-hue/fash-ios-mobile
```

Cần `secrets/ios-release.env` (có `GOOGLE_SERVICE_INFO_PLIST_PATH=secrets/GoogleService-Info.plist`) và `gh auth login` (tài khoản `hochanhphuc7-hue`).

Kiểm tra:

```powershell
gh secret list -R hochanhphuc7-hue/fash-ios-mobile
gh run list -R hochanhphuc7-hue/fash-ios-mobile --branch releases/1.0 --limit 3
```

Remote CI: `techheart` → `https://github.com/hochanhphuc7-hue/fash-ios-mobile.git`. Push nhánh `releases/1.0` để trigger **iOS Release**.
