# Đẩy secrets lên GitHub Actions (repo CI TestFlight)

```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo medicalconsultationapplication-hue/fash-ios-mobile
```

Cần `secrets/ios-release.env` (có `GOOGLE_SERVICE_INFO_PLIST_PATH=secrets/GoogleService-Info.plist`) và `gh auth login`.

Kiểm tra:

```powershell
gh secret list -R medicalconsultationapplication-hue/fash-ios-mobile
```

Phải thấy `GOOGLE_SERVICE_INFO_PLIST_BASE64`. Repo `phuckhoa33/fash-ios-mobile` **không** dùng cho CI hiện tại.
