# Android ↔ iOS parity matrix

**Product source of truth:** `fash-android-mobile` (Kotlin / Compose).  
**iOS delivery:** `fash-ios-mobile` — builds **without** an Android checkout (`env/`, `vendor/`, fonts committed).

Last audit: Android `1.0.3` (versionCode 4), iOS `MARKETING_VERSION` 1.0.3 / build 4.

## Standalone build

| Item | Status |
|------|--------|
| `env/dev.env`, `env/prod.env` in iOS repo | ✅ |
| `vendor/android-res/.../strings.xml` | ✅ |
| Fonts `BeVietnamPro-*.ttf` | ✅ |
| `setup_mac.sh` / `build_mac.sh` (no Android path) | ✅ |
| ~290 Swift files / 283 Kotlin files (1:1 tree) | ✅ structure |

## Setup & build

| Android | iOS | Status |
|---------|-----|--------|
| `env/dev.env`, `env/prod.env` | `env/` → `Config/*.xcconfig` | ✅ vendored |
| Flavors `dev` / `prod` | Schemes `Fash-Dev` / `Fash-Prod` | ✅ |
| `BuildConfig.*` | `GeneratedBuildConfig_*` | ✅ |
| Gradle + Compose | XcodeGen + SwiftUI 17+ | ✅ |
| Be Vietnam Pro | `Fash/Resources/Fonts/` + `UIAppFonts` | ✅ |

## Navigation overlays (routes)

All MainActivity overlay types have `FullScreenRoute` + `AppRouter` state:

| Overlay | iOS route | UI depth |
|---------|-----------|----------|
| PDP | `.listing` | ✅ functional |
| Seller shop | `.seller` | 🔶 thin |
| Edit listing | `.editListing` | 🔶 thin |
| Edit profile | `.editProfile` | 🔶 thin |
| Chat | `.chat` | 🔶 thin |
| Orders / order detail | `.orders` / `.order` | 🔶 thin |
| Checkout | `.checkout` | 🔶 thin |
| Addresses | `.shippingAddresses` / `.addAddress` | 🔶 thin |
| Editorial detail | `.homeEditorial` | 🔶 thin |
| Editorial list | `.editorialList` | 🔶 thin (route ✅) |
| UX survey | `.uxSurvey` | 🔶 thin (route ✅) |
| Delivering | `.homeDelivering` | 🔶 thin |
| Seller packages / checkout | `.sellerPackages` / `.sellerPackageCheckout` | 🔶 thin |
| Follow / featured sellers | `.followConnections` / `.featuredSellers` | 🔶 thin |
| Invite / change password | `.inviteFriends` / `.changePassword` | 🔶 thin |
| Chat order overlay | `.chatOrderDetail` | 🔶 uses OrderDetail |

## i18n

| Item | Status |
|------|--------|
| vi ~1917 keys | ✅ synced |
| en ~1870 keys | ✅ |
| `L10n.*` | ✅ generated |
| Locale toggle | ✅ |

## Data / integrations

| Area | Status |
|------|--------|
| Auth OTP + refresh | ✅ |
| Home / Explore feed + PDP | ✅ |
| Notifications inbox API | ✅ partial UI |
| Chat / Orders / Post repos | 🔶 stub — port Kotlin logic next |
| FCM / Google / Facebook | 🔶 SDK TBD |
| Realtime WebSocket | 🔶 connect only |

## Regenerate from Android (maintainers only)

```bash
python3 scripts/vendor_from_android.py
python3 scripts/android_strings_to_ios.py
python3 scripts/env_to_xcconfig.py
python3 scripts/generate_swift_from_android.py
```

## Mac build

```bash
./scripts/setup_mac.sh
open Fash.xcodeproj
```
