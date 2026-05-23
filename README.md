# Fash iOS (Swift)

Native iOS port of [`fash-android-mobile`](../fash-android-mobile): SwiftUI, MVVM, same env URLs, vi/en i18n, and navigation shell.

## Requirements (Mac)

- macOS 14+
- Xcode 15+ (iOS 17 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## First-time setup on Mac

```bash
cd fash-ios-mobile

# Sync strings + build config from Android
python3 scripts/android_strings_to_ios.py
python3 scripts/env_to_xcconfig.py
python3 scripts/generate_swift_from_android.py   # optional: refresh scaffolds

# Fonts: copy Be Vietnam Pro into Fash/Resources/Fonts/
# (Android: app/src/main/res/font/*.ttf — add if missing in repo)
#   BeVietnamPro-Regular.ttf, BeVietnamPro-SemiBold.ttf, BeVietnamPro-Bold.ttf

# Generate Xcode project
xcodegen generate

open Fash.xcodeproj
```

In Xcode:

1. Select scheme **Fash-Dev** or **Fash-Prod**
2. Set your **Team** under Signing & Capabilities
3. Build & Run on simulator or device (`Cmd+R`)

## Project layout

| Path | Role |
|------|------|
| `Fash/` | Swift sources (mirrors Android package tree) |
| `Fash/Resources/vi.lproj`, `en.lproj` | All `strings.xml` keys as `Localizable.strings` |
| `Fash/Localization/L10n.swift` | Type-safe `L10n.*` (generated) |
| `Fash/config/generated/` | `GeneratedBuildConfig_Dev/Prod.swift` from `env/*.env` |
| `Config/*.xcconfig` | Flavor build settings |
| `project.yml` | XcodeGen spec |
| `scripts/` | i18n + scaffold generators |

## Architecture (parity with Android)

- **UI:** SwiftUI (`FashTheme`, editorial colors, Be Vietnam Pro)
- **State:** `@Observable` ViewModels + `AppRouter` (MainActivity navigation state)
- **DI:** `AppDependencies` (manual, like `FashApplication`)
- **Network:** `URLSession` + `SecuredApiClient` (Bearer + 401 refresh)
- **Guest:** `PublicBrowseHttp` when `PUBLIC_BROWSE_CLIENT_TOKEN` is set
- **Deep links:** `fash://` + HTTPS `/p/l/`, `/p/u/`, invite (see `Info.plist` URL types)

See **[PARITY.md](PARITY.md)** for full Android ↔ iOS feature matrix and port status.

## Port status (summary)

| Area | Status |
|------|--------|
| i18n (vi + en, ~1690 keys) | Done — auto-sync from Android `strings.xml` |
| Build config (dev/prod env) | Done — `GeneratedBuildConfig_*` |
| Theme / typography / spacing | Done — editorial Vina-Pink palette |
| Navigation shell (5 tabs + overlays) | Done — `AppRouter` + `fullScreenCover` |
| Auth (OTP request/verify, refresh) | Done |
| Home / Explore feed + PDP | Done — listing grid + detail |
| Onboarding flow (6 steps) | Shell + copy wired; full UI port in progress |
| Chat / Orders / Post / Settings | Scaffold screens (compile-safe); logic TBD |
| Push / Google / Facebook sign-in | Entitlements stub; SDK integration TBD |
| Realtime WebSocket | Stub |

**276 Swift files** mirror Android package structure. After `xcodegen generate`, open **Fash-Dev** scheme and set your Apple Team.

When Android strings or env change:

```bash
python3 scripts/android_strings_to_ios.py
python3 scripts/env_to_xcconfig.py
```

When new Kotlin files are added:

```bash
python3 scripts/generate_swift_from_android.py
```

Then re-implement UI logic in the matching `.swift` file (scaffolds are compile-safe stubs).

## Signing & capabilities (production)

Before App Store / TestFlight:

- Apple Developer team + bundle id `com.pc.fash-ios-mobile` / `.dev`
- Push Notifications + Background Modes (remote-notification)
- Sign in with Apple / Google (add URL schemes and SDKs; Android uses Google + Facebook)
- Associated Domains for Universal Links (`fashandcurious.com` — match Android App Links host)

## Windows note

This repo is authored on Windows; **build only on Mac**. Generated `Fash.xcodeproj` is gitignored — run `xcodegen generate` locally.
