# Android ↔ iOS parity matrix

**Product source of truth:** `fash-android-mobile` (Kotlin / Compose).  
**iOS delivery:** `fash-ios-mobile` — builds **without** an Android checkout (`env/`, `vendor/`, fonts committed).

Last audit: **2026-05-27** — iOS `MARKETING_VERSION` 1.0.7 / build 12, Android 1.0.3.

## Standalone build

| Item | Status |
|------|--------|
| `env/dev.env`, `env/prod.env` in iOS repo | ✅ |
| `vendor/android-res/.../strings.xml` | ✅ |
| Fonts `BeVietnamPro-*.ttf` | ✅ |
| `setup_mac.sh` / `build_mac.sh` (no Android path) | ✅ |
| ~290 Swift files / 283 Kotlin files (1:1 tree) | ✅ structure |
| TestFlight via `.github/workflows/ios-release.yml` | ✅ |

## Navigation (structural note)

| Android tabs | iOS tabs | Parity |
|--------------|----------|--------|
| Home, **Orders**, Post, Chat, Profile | Home, **Explore**, Post, Chat, Profile | 🔶 Explore is a dedicated tab on iOS; Orders opens from top bar / settings overlay |

Explore on Android is a **full-screen overlay** from Home search; on iOS it is a **bottom tab**. Screen content should still match when reached.

## Screen-by-screen parity (UI + API)

| Screen | Route | UI parity | API / data | Notes |
|--------|-------|-----------|------------|-------|
| Splash / waiting | Root | ✅ | ✅ | |
| Setup gate retry | Root | ✅ | ✅ | |
| Login / OTP | Root | ✅ | ✅ | Auth `data` wrapper unwrapped |
| Onboarding (6 steps) | Root | 🔶 shell | 🔶 partial | Steps exist; logic thin |
| **Home feed** | Tab | 🔶 ~40% | ✅ | Sections API wired; missing tabs/journey/promo rail vs Android |
| **Explore** | Tab | 🔶 ~35% | ✅ | Browse/search API; missing filters, sellers tab, chips |
| Post / create listing | Tab | 🔶 stub | 🔶 stub | Steps ported as data only |
| **Chat inbox** | Tab | 🔶 ~45% | ✅ | List API; missing filters, grouped seller inbox |
| **Profile** | Tab | 🔶 ~40% | ✅ | `GET users/me`; missing tabs, listings grid, hero polish |
| Notifications | Sheet | 🔶 ~60% | ✅ | Inbox API; detail stub |
| Settings | Sheet | 🔶 ~50% | 🔶 partial | |
| **Orders** | Overlay | 🔶 ~45% | ✅ | Buying/selling list API |
| Order detail | Overlay | 🔶 stub | 🔶 stub | |
| PDP / listing | Overlay | 🔶 ~55% | ✅ | Detail + preview |
| Seller shop | Overlay | 🔶 stub | 🔶 stub | |
| Checkout | Overlay | 🔶 stub | 🔶 stub | |
| Addresses | Overlay | 🔶 stub | 🔶 stub | |
| Editorial / UX survey | Overlay | 🔶 stub | 🔶 stub | |
| Guest browse | Root | ✅ | ✅ | Public browse attestation |

Legend: ✅ functional · 🔶 partial / stub · ❌ missing

## Data / API layer (2026-05-27)

| Repository | Android | iOS (after audit) |
|------------|---------|-------------------|
| AuthRepository | ✅ full | ✅ OTP/refresh/social; login/password TBD |
| UserRepository | ✅ full | 🔶 setup-status, locale, **getMeProfile**, notifications |
| ListingRepository | ✅ full | 🔶 home, detail, preview |
| SearchRepository | ✅ full | ✅ listings search/browse, trending, autocomplete |
| RecommendationRepository | ✅ full | ✅ explore-listings, home-sections |
| ChatRepository | ✅ full | 🔶 conversations list, unread |
| OrderRepository | ✅ full | 🔶 list buying/selling |
| CommonServiceRepository | ✅ full | 🔶 stub |
| Payment / Deal / Address / Editorial / UX | ✅ full | 🔶 stub |

### API fixes applied

1. Auth login response unwraps `{ data: { access_token } }`
2. Guest explore uses `public/browse/recommendations/explore-listings` (not authenticated home feed)
3. `coreApiCandidateURLs()` fallback for locale-prefixed paths
4. `AuthRefreshPolicy` — transient network errors no longer force logout
5. Shared `RepositoryHttp` helper for secured + public browse GETs

## UI / UX design system (2026-05-27)

| Layer | Android source | iOS status |
|-------|----------------|------------|
| Spacing (4–48, editorial 24/16, radii) | `Spacing.kt` | ✅ synced |
| Typography (M3 scale, Be Vietnam Pro) | `Type.kt` | ✅ synced |
| Brand typography (mark 18/22/34) | `FashBrandTypography.kt` | ✅ synced |
| Gradients (primary CTA 135°) | `FashGradients.kt` | ✅ synced |
| Shimmer loading | `FashModifiers.kt` | ✅ synced |
| `FashAsyncImage` + avatar 48 | `FashImage.kt` | ✅ synced |
| `FashPrimaryButton` 48pt / r12 | `FashButtons.kt` | ✅ synced |
| `ListingGridCard` overlay 3:4 | `ListingGridCard.kt` | ✅ rewritten |
| `FashEmptyState` 72/36 | `FashEmptyState.kt` | ✅ synced |
| `FashSkeleton` grid | `FashSkeleton.kt` | ✅ basic grid |
| `MainNavBottomBar` 72 / FAB 52 | `MainNavBottomBar.kt` | ✅ ported |
| `FashScreenTitle` mark 18 + suffix 22 | `MainNavScreen.kt` | ✅ ported |

Screens with updated UI parity this sprint: **Home, Explore, Login, Profile, Chat, Orders**, top/bottom chrome.

Still need full Android port: Home feed tabs/journey/promo, Explore filters, PDP, onboarding, post wizard, notification detail.

| Item | Status |
|------|--------|
| vi ~1917 keys | ✅ synced |
| en ~1870 keys | ✅ |
| `L10n.*` | ✅ generated |
| Locale toggle | ✅ |

## Integrations still TBD

| Area | Status |
|------|--------|
| FCM push (real device token) | ✅ SDK + register API wired; cần GoogleService-Info.plist + APNs key trên Firebase |
| Google / Facebook login | ✅ Google (SDK + UI); Facebook TBD |
| Realtime WebSocket (inbox refresh) | 🔶 connect only |
| Payment / checkout flow | 🔶 stub |

## Next parity sprint (recommended order)

1. **Home** — port `HomeFeedTabHost`, journey row, promo slider, feed tabs (hunt_today / for_you / following)
2. **Explore** — filter sheet, trending chips, sellers section, pagination
3. **Post** — wire `CreateListingFlowScreen` steps 0–10 + image upload API
4. **Chat detail** — messages, offers, meetings
5. **Order detail + checkout** — full lifecycle
6. **Profile** — selling/buying tabs, listings grid, follow actions
7. **Common catalog** — categories, brands, aesthetic tags for filters

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
