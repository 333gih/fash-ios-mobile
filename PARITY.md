# Android ↔ iOS parity matrix

Source of truth: [`fash-android-mobile`](../fash-android-mobile).  
iOS target: [`fash-ios-mobile`](.) — **only this repo is modified**.

Last audit: aligned with Android `1.0.3` (versionCode 4), env `dev`/`prod`.

## Setup & build

| Android | iOS | Status |
|---------|-----|--------|
| `env/dev.env`, `env/prod.env` | Same files → `scripts/env_to_xcconfig.py` | ✅ |
| Product flavors `dev` / `prod` | Schemes `Fash-Dev` / `Fash-Prod`, bundle `.dev` suffix | ✅ |
| `BuildConfig.*` (~40 fields) | `GeneratedBuildConfig_*` + `BuildConfig.swift` | ✅ |
| `BusinessFlowConfig` | `config/BusinessFlowConfig.swift` | ✅ |
| `AppEnvironment` path helpers | `config/AppEnvironment.swift` | ✅ |
| Gradle + Compose | XcodeGen + SwiftUI (iOS 17+) | ✅ native |
| Release keystore | Xcode Automatic + Team (manual on Mac) | ⚙️ manual |
| Be Vietnam Pro fonts | `Info.plist` + copy to `Resources/Fonts/` | ⚙️ add files |

## Architecture

| Android | iOS | Status |
|---------|-----|--------|
| `FashApplication` | `AppDependencies` | ✅ wired (all repos) |
| `AppAuthManager` | `AppAuthManager.swift` | ✅ |
| `AuthTokenRefreshCoordinator` | `AuthTokenRefreshCoordinator.swift` | ✅ |
| `SecuredApiClient` | `SecuredApiClient.swift` | ✅ |
| `PublicBrowseHttp` | `PublicBrowseHttp.swift` | ✅ |
| MVVM + `StateFlow` | `@Observable` ViewModels | ✅ native |
| Manual DI (no Hilt) | Manual `AppDependencies` | ✅ |

## Repositories (FashApplication)

| Repository | iOS | API logic |
|------------|-----|-----------|
| UserRepository | ✅ | setup-status only — **profile CRUD TBD** |
| ListingRepository | ✅ | home feed + PDP |
| ChatRepository | 🔶 stub | wire from Kotlin |
| OrderRepository | 🔶 stub | wire from Kotlin |
| SearchRepository | 🔶 stub | Explore calls API directly |
| RecommendationRepository | 🔶 stub | |
| CommonServiceRepository | 🔶 wired shell | |
| PublicCommonCatalogRepository | 🔶 stub | |
| AdvertisingRepository | 🔶 wired shell | |
| SellerProductPackageRepository | 🔶 wired shell | |
| AppPromoInterstitialRepository | 🔶 wired shell | |
| EditorialGuideRepository | 🔶 stub | |
| DealRepository | 🔶 wired shell | |
| UserShippingAddressRepository | 🔶 wired shell | |
| CorePaymentRepository | 🔶 wired shell | use `ASWebAuthenticationSession` |
| BrowseSessionStore | ✅ UserDefaults | |
| AddressLocalStore / OnboardingLocalStore | ✅ | |
| OrderCancelCoordinator | 🔶 wired shell | |
| RealtimeManager | 🔶 WS connect | expand event handling |
| FcmTokenRegistrar | 🔶 | needs APNs + Firebase iOS |

## Navigation (MainActivity)

| Feature | iOS | Status |
|---------|-----|--------|
| 5 tabs | `MainTab` + `MainNavScreen` | ✅ |
| Guest shell + login sheet | `GuestMainShell` + `GuestLoginSheet` | ✅ |
| OTP login | ✅ | Google/Facebook **TBD** |
| Onboarding 6 steps | routes ✅, API **TBD** | 🔶 |
| All full-screen overlays | `FullScreenRoute` + `OverlayScreens` | ✅ routes (UI partial) |
| Settings sheet | `SettingsScreen` (lang, theme, logout) | ✅ |
| Notifications sheet | `NotificationScreen` | 🔶 |
| Deep links `fash://` + HTTPS | `DeepLinkRouter` + Associated Domains | ✅ |
| Feature tour / promo overlay | router fields exist | 🔶 UI TBD |
| Pending deep link consumption | `AppDependencies.consumePendingDeepLinks` | ✅ |

## i18n

| Item | Status |
|------|--------|
| vi ~1692 keys | ✅ synced from Android |
| en ~1666 keys | ✅ (gap vs vi = Android same) |
| `L10n.*` type-safe | ✅ generated |
| Runtime locale toggle | ✅ login + Settings |

## Integrations (iOS-native choices)

| Android | iOS approach | Status |
|---------|--------------|--------|
| Coil | Kingfisher (`FashAsyncImage`) | ✅ |
| Custom Tabs | `SFSafariViewController` / universal links | 🔶 payment TBD |
| Google Sign-In | GoogleSignIn-iOS SDK | 🔶 |
| Facebook Login | FBSDKLoginKit or disabled via env | 🔶 |
| FCM | APNs + optional Firebase iOS | 🔶 |
| WebSocket realtime | `URLSessionWebSocketTask` | 🔶 basic connect |

## Screen UI depth

- **Done (functional):** Splash, login OTP, home/explore grid, PDP basic, settings, guest placeholders.
- **Routed + placeholder copy:** Post flow, chat, orders, addresses, seller shop, packages, editorial, delivering, follow, featured sellers, change password.
- **Port next (highest impact):** `CreateListingFlowScreen`, `ChatDetailScreen`, `OrdersScreen`, `NotificationScreen` inbox API.

## Regenerate after Android changes

```bash
python3 scripts/android_strings_to_ios.py
python3 scripts/env_to_xcconfig.py
python3 scripts/generate_swift_from_android.py   # new Kotlin files only
```

## Mac build

```bash
./scripts/setup_mac.sh
# Set Development Team in Xcode → Run Fash-Dev
```
