# Đẩy secrets lên GitHub Actions (repo CI TestFlight)

```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo phuc20251012tpe5-max/fash-ios-mobile
```

Cần `secrets/ios-release.env` (có `GOOGLE_SERVICE_INFO_PLIST_PATH=secrets/GoogleService-Info.plist`) và `gh auth login` (tài khoản `hochanhphuc7-hue`).

Kiểm tra:

```powershell
gh secret list -R phuc20251012tpe5-max/fash-ios-mobile
gh run list -R phuc20251012tpe5-max/fash-ios-mobile --branch releases/1.0 --limit 3
```

Remote CI: `https://github.com/phuc20251012tpe5-max/fash-ios-mobile.git`. Push nhánh `releases/1.0` để trigger **iOS Release**.
