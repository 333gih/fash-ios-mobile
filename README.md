# Fash iOS (Swift)

Native iOS app aligned with **fash-android-mobile** (SwiftUI, MVVM, same API URLs, vi/en i18n, navigation shell).

**This repo builds standalone** — no sibling `fash-android-mobile` checkout is required. Vendored assets live under `env/`, `vendor/android-res/`, and `Fash/Resources/`.

## Requirements (Mac)

- macOS 14+
- Xcode 15+ (iOS 17 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build (no Android)

```bash
cd fash-ios-mobile
./scripts/setup_mac.sh          # xcodegen only
./scripts/build_mac.sh          # xcodegen + simulator build (unsigned)
open Fash.xcodeproj             # scheme Fash-Dev, set Team, Cmd+R
```

In Xcode: scheme **Fash-Dev** or **Fash-Prod**, set **Development Team**, run on simulator or device.

## What is vendored in-repo

| Path | Source (when Android changes) |
|------|-------------------------------|
| `env/dev.env`, `env/prod.env` | Android `env/*.env` |
| `vendor/android-res/**/strings.xml` | Android `res/values*` |
| `Fash/Resources/{vi,en}.lproj/` | Generated from vendor strings |
| `Fash/Localization/L10n.swift` | Generated |
| `Config/*.xcconfig`, `Fash/config/generated/` | Generated from `env/` |
| `Fash/Resources/Fonts/*.ttf` | Android `res/font/` (Be Vietnam Pro) |

## Maintainer sync (optional Android checkout) 

When Android strings or env change:

```bash
# Refresh vendored snapshots (requires fash-android-mobile)
FASH_ANDROID_ROOT=../fash-android-mobile python3 scripts/vendor_from_android.py
python3 scripts/android_strings_to_ios.py
python3 scripts/env_to_xcconfig.py
python3 scripts/generate_swift_from_android.py   # new Kotlin files only
```

Windows prep (no Mac build):

```powershell
.\scripts\sync.ps1
```

## Project layout

| Path | Role |
|------|------|
| `Fash/` | Swift sources (~290 files, mirrors Android packages) |
| `env/` | Dev/prod API URLs and feature flags |
| `project.yml` | XcodeGen spec |
| `scripts/` | Sync, vendor, Mac build |

See **[PARITY.md](PARITY.md)** for Android ↔ iOS feature matrix.

## Architecture

- **UI:** SwiftUI (`FashTheme`, editorial palette, Be Vietnam Pro)
- **State:** `@Observable` ViewModels + `AppRouter`
- **DI:** `AppDependencies`
- **Network:** `URLSession` + `SecuredApiClient`
- **Deep links:** `fash://` + HTTPS paths (see `Info.plist`)

## Signing (TestFlight / App Store)

- Bundle id `com.pc.fash-ios-mobile` / `.dev`
- Push, Sign in with Apple / Google SDKs (stubs in repo — wire before release)
- Associated Domains for Universal Links

## CI (GitLab → GitHub → build iOS)

No Mac required for **compile checks**: push to GitLab (mirrored to GitHub) triggers [GitHub Actions](.github/workflows/ios-build.yml) on `macos-14` + Xcode 15.4.

```text
git push origin develop  →  GitLab mirror  →  GitHub Actions  →  xcodebuild (simulator)
```

Setup, mirror checklist, and troubleshooting: **[docs/CI.md](docs/CI.md)**.

GitLab pipeline (`.gitlab-ci.yml`) only prints a reminder — the real iOS build runs on GitHub.

**Artifacts (GitHub Actions):**

| Workflow | Khi nào | Artifact |
|---|---|---|
| **iOS Build** | Push/PR pass | `fash-ios-simulator-Fash-*` (.zip → `Fash.app` simulator) |
| **iOS Release** | Tag `ios/v*` hoặc Run workflow | `fash-ios-ipa-Fash-Prod-*` (`.ipa` App Store) |

Chi tiết secrets & TestFlight: **[docs/CI.md](docs/CI.md)**.

## Windows

Authoring on Windows is supported; **compile only on Mac or GitHub Actions**. `Fash.xcodeproj` is gitignored — created by `xcodegen generate` locally or in CI.
