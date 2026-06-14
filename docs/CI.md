# CI: GitLab → GitHub → Build iOS

> **Trước khi push:** xem [BUILD_CHECKLIST.md](./BUILD_CHECKLIST.md) — checklist tránh lỗi compile / archive / TestFlight.

Project **Fash iOS** không build trên GitLab Free (runner Linux). Luồng khuyến nghị:

```text
Windows / bất kỳ máy nào
        │
        ▼ git push
   GitLab (origin)
        │
        ▼ mirror (đã cấu hình)
   GitHub
        │
        ▼ GitHub Actions (macOS + Xcode — xem mục 3)
   Build iOS Simulator (Fash-Dev + Fash-Prod)
```

## 1. GitLab mirror → GitHub

Trên GitLab (**Settings → Repository → Mirroring repositories**):

| Field | Giá trị |
|---|---|
| Git repository URL | `https://github.com/<user>/<repo>.git` |
| Mirror direction | Push |
| Authentication | GitHub PAT (`repo` scope) hoặc deploy key |

Branch mirror thường dùng: `main`, `master`, `develop` — khớp với trigger trong `.github/workflows/ios-build.yml`.

Sau mỗi `git push` lên GitLab, đợi mirror sync (vài giây–phút) rồi kiểm tra GitHub **Actions**.

## 2. Bật GitHub Actions

Trên GitHub repo:

1. **Settings → Actions → General** → Allow actions.
2. Push branch có file `.github/workflows/ios-build.yml` (đã có trong repo).
3. Tab **Actions** → workflow **iOS Build**.

Trigger:

- `push` / `pull_request` vào `main`, `master`, `develop`
- **Run workflow** thủ công (chọn scheme `Fash-Dev`, `Fash-Prod`, hoặc `both`)

Scheme theo branch (tự động):

| Branch | Scheme build |
|---|---|
| `develop` | **Fash-Dev** |
| `main` / `master` | **Fash-Prod** |
| PR vào `develop` | **Fash-Dev** |
| PR vào `main` / `master` | **Fash-Prod** |
| PR vào `release/**` / `releases/**` | **Fash-Prod** (simulator compile check) |
| Push `release/**` / `releases/**` | *(không chạy iOS Build — xem iOS Release)* |
| Run workflow thủ công | Chọn scheme (hoặc `both`) |

## 3. Workflow làm gì?

### iOS Build (`ios-build.yml`) — push (develop/main) + PR

**Không chạy khi push `release/**` hoặc `releases/**`** — nhánh đó chỉ dùng **iOS Release** (tránh 2 job macOS trùng việc).

Giống `./scripts/build_mac.sh` trên Mac cloud:

1. `scripts/ci_ios_prepare.sh` — validate, **XcodeGen**, resolve Kingfisher
2. `xcodebuild` cho **iOS Simulator** (iPhone 15, iOS 17.5)
3. `CODE_SIGNING_ALLOWED=NO` — verify compile
4. **Upload artifact** — file `.zip` chứa `Fash.app` (simulator)

**Tải build trên GitHub (build pass):**

1. **Actions** → workflow **iOS Build** → run thành công
2. Cuối trang → **Artifacts**
3. Tên: `fash-ios-simulator-Fash-Dev-<run>` hoặc `fash-ios-simulator-Fash-Prod-<run>`
4. Giải nén → `Fash.app` (chỉ chạy Simulator, không cài iPhone thật)

Build fail → artifact `xcodebuild-log-Fash-Dev` / `Fash-Prod`.

### iOS Release (`ios-release.yml`) — App Store / TestFlight

Khi đã có **Apple Developer** + GitHub Secrets (mục 6):

1. **Archive** thiết bị thật (`iphoneos`) + ký **Apple Distribution**
2. **Export IPA** (`app-store`)
3. **Artifact:** `fash-ios-ipa-Fash-Prod-<run>` — file `.ipa` tải về hoặc upload App Store Connect thủ công
4. **Upload TestFlight** — tự động khi push `releases/**` / `release/**`, hoặc **Run workflow** thủ công (checkbox mặc định bật). Cần 3 secrets App Store Connect API (mục 6).

Trigger release:

| Cách | Hành vi |
|---|---|
| **Actions → iOS Release → Run workflow** | Chọn scheme; TestFlight mặc định **bật** (Fash-Prod) |
| Push `releases/**` hoặc `release/**` | Archive **Fash-Prod** + artifact IPA + **upload TestFlight** |
| Push `main`/`master` hoặc tag `ios/v*` | Archive + IPA artifact (không auto TestFlight) |

Khuyến nghị tag prefix **`ios/v*`** để không trùng tag Android (`v1.0.8`).

Mỗi push CI chỉ build **một scheme** theo branch (`develop` → Dev, `main`/`master` → Prod).

| Workflow | Runner | Xcode | Mục đích |
|---|---|---|---|
| **iOS Build** (`ios-build.yml`) | `macos-14` | **16.2** | Simulator compile (`iPhone 15`, iOS 17.5), `CODE_SIGNING_ALLOWED=NO` |
| **iOS Release** (`ios-release.yml`) | `macos-26` | **26.4** | Archive `iphoneos` + IPA + TestFlight |

Cả hai đều chạy `scripts/ci_ios_prepare.sh` (validate strings/Swift → XcodeGen → resolve SPM). `project.yml` pin `projectFormat: xcode15_0` (tương thích Xcode 15–16); release job hạ `objectVersion` về 60 nếu XcodeGen tạo > 60.

## 4. Chi phí GitHub

| Loại repo | macOS runner |
|---|---|
| **Public** | Miễn phí (không giới hạn phút như Linux) |
| **Private** | ~200 phút macOS/tháng (gói Free), sau đó trả phí |

Nếu build thường xuyên và repo private, cân nhắc public repo hoặc GitHub Team.

## 5. GitLab pipeline

File `.gitlab-ci.yml` chỉ **thông báo** — job chạy trên runner Linux, không build iOS. Giúp team biết build thật nằm trên GitHub Actions.

## 6. App Store / TestFlight — GitHub Secrets

### Cách 1 — File local (gitignored) + script đẩy lên GitHub (khuyến nghị)

GitHub Actions **không đọc** file trên máy bạn khi chạy CI. File local chỉ để **lưu + đồng bộ** secrets lên GitHub một lần.

1. Copy template:

```bash
cp secrets/ios-release.env.example secrets/ios-release.env
```

2. Đặt file binary vào `secrets/` (đã gitignore):

| File | Nguồn |
|---|---|
| `AppleDistribution.p12` | Keychain Access → export **Apple Distribution** |
| `Fash_AppStore.mobileprovision` | Apple Developer → Profiles → Download |
| `AuthKey_XXXX.p8` | App Store Connect → Users and Access → Keys |

3. Điền `secrets/ios-release.env` (`APPLE_TEAM_ID`, mật khẩu `.p12`, tên profile, …).

4. Cài [GitHub CLI](https://cli.github.com/) và login: `gh auth login`

5. Đẩy secrets lên repo:

```powershell
# Windows
.\scripts\push_github_ios_secrets.ps1
# hoặc repo khác:
.\scripts\push_github_ios_secrets.ps1 -Repo phuckhoa33/fash-ios-mobile
```

```bash
# Mac / Linux
chmod +x scripts/push_github_ios_secrets.sh
./scripts/push_github_ios_secrets.sh
```

Script map sang GitHub Secrets:

| Trong `ios-release.env` | GitHub Secret |
|---|---|
| `APPLE_TEAM_ID` | `APPLE_TEAM_ID` |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` |
| `IOS_PROVISIONING_PROFILE_SPECIFIER` | `IOS_PROVISIONING_PROFILE_SPECIFIER` |
| `IOS_DISTRIBUTION_CERTIFICATE_PATH` → base64 | `IOS_DISTRIBUTION_CERTIFICATE_BASE64` |
| `IOS_PROVISIONING_PROFILE_PATH` → base64 | `IOS_PROVISIONING_PROFILE_BASE64` |
| `APP_STORE_CONNECT_*` | cùng tên |
| `GOOGLE_SERVICE_INFO_PLIST_PATH` → base64 | `GOOGLE_SERVICE_INFO_PLIST_BASE64` |
| `GOOGLE_SERVICE_INFO_DEV_PLIST_PATH` → base64 (tuỳ chọn) | `GOOGLE_SERVICE_INFO_DEV_PLIST_BASE64` |

Plist **prod** (`BUNDLE_ID` = `com.pc.fash-ios-mobile`) bắt buộc cho **Fash-Prod** / TestFlight — thiếu secret thì job **fail** (không còn build IPA im lặng không có FCM). CI decode vào `Fash/GoogleService-Info.plist` trước `xcodegen`. Sau export, `scripts/ci_verify_ipa_push.sh` kiểm tra plist trong `.app` và `aps-environment` trong entitlements đã ký.

Provisioning profile phải có **Push Notifications**; job chạy `ci_verify_provisioning_push.sh` trước archive.

### Cách 2 — Dán thủ công trên GitHub

**Settings → Secrets and variables → Actions** (repo GitHub):

| Secret | Mô tả |
|---|---|
| `APPLE_TEAM_ID` | Team ID (10 ký tự), ví dụ `AB12CD34EF` |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | File `.p12` **Apple Distribution**, encode base64 |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Mật khẩu export `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Profile **App Store** cho `com.pc.fash-ios-mobile`, encode base64 |
| `IOS_PROVISIONING_PROFILE_SPECIFIER` | **Tên** profile trong Apple Developer (đúng chữ, có space) |

**TestFlight tự động (tuỳ chọn):**

| Secret | Mô tả |
|---|---|
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID từ App Store Connect → Users and Access → Keys |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Nội dung file `.p8` (giữ nguyên `-----BEGIN PRIVATE KEY-----`) |

**FCM push trên TestFlight (Fash-Prod):**

| Secret | Mô tả |
|---|---|
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `GoogleService-Info.plist` prod (`com.pc.fash-ios-mobile`), base64 — **bắt buộc** Fash-Prod |
| `GOOGLE_SERVICE_INFO_DEV_PLIST_BASE64` | Plist dev (`com.pc.fash-ios-mobile.dev`) — chỉ khi archive **Fash-Dev** |

Sau khi thêm secrets:

```text
Actions → iOS Release → Run workflow
  Scheme: Fash-Prod
  Upload TestFlight: ✓ (nếu đã có API key)
```

Hoặc push tag:

```bash
git tag ios/v1.0.7
git push origin ios/v1.0.7
```

Tải IPA: **Artifacts** → `fash-ios-ipa-Fash-Prod-<run>`.

Provisioning profile phải khớp bundle id **ProdRelease**: `com.pc.fash-ios-mobile` (xem `project.yml`).

## 7. Troubleshooting

| Triệu chứng | Cách xử lý |
|---|---|
| Push GitLab nhưng GitHub không build | Kiểm tra mirror sync; branch có trong workflow trigger? |
| Workflow không xuất hiện | File `.github/workflows/ios-build.yml` đã lên GitHub chưa? |
| Build fail Kingfisher / Swift | Xem log artifact `xcodebuild-log-*`; cần Xcode 15+ |
| Không thấy artifact simulator | Build phải **pass**; tên `fash-ios-simulator-*` |
| iOS Release fail signing | Kiểm tra secrets mục 6; profile name khớp `IOS_PROVISIONING_PROFILE_SPECIFIER` |
| Archive: `Multiple commands produce .../Fash.app/README.md` | Không đặt `README.md` / `*.md` trong `Fash/` — doc ở `docs/`; `project.yml` exclude `**/*.md`; CI fail sớm nếu pbxproj vẫn tham chiếu README |
| TestFlight `90022` / `90713` / `90023` missing app icon | `Assets.xcassets` trong `sources` (actool); sync từ Android: `scripts/sync_app_icon_from_android.ps1` → commit `AppIcon-*.png` (gồm iPad 152px) |
| Hết phút macOS (private repo) | Đổi repo public hoặc nâng gói GitHub |
| **Preflight** fail `validate_swift_syntax.py` | Chạy local trước push; sửa lỗi cú pháp Swift |
| **Preflight** fail `ci_swift_compile_preflight.sh` | Import/type lỗi — không cần Mac, script dùng `swiftc -typecheck` partial |
| PDP / edit listing lỗi mạng ngẫu nhiên | `ListingRepository` phải dùng `executeCoreGet` + retry — **không** `AppEnvironment.apiPath` một URL |
| Agent skill iOS (no Mac) | Đọc `.cursor/skills/fash-ios-mobile/SKILL.md` trước khi sửa Swift/CI |

## 8. Build local (Mac)

```bash
./scripts/build_mac.sh              # Fash-Dev
./scripts/build_mac.sh Fash-Prod    # Fash-Prod
```

Yêu cầu local: macOS 14.7+ , Xcode 16.2+ (khớp iOS Build CI) hoặc Xcode mới hơn cho archive release.
