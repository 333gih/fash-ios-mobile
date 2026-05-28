# Fash iOS — Architecture (aligned with Android)

This document describes how **fash-ios-mobile** mirrors **fash-android-mobile** so new features can be ported systematically.

**Canonical API specs** remain in the Android repo (`core-service-api.md`, `ANDROID_API_INTEGRATION.md`, …). iOS uses the same URLs from `env/*.env` → `Config/*.xcconfig` → `AppEnvironment`.

---

## 1. Layer overview

```text
SwiftUI Screen (*Screen.swift)
    ↓
@Observable ViewModel (*ViewModel.swift)
    ↓
AppDependencies.shared → *Repository
    ↓
SecuredApiClient / URLSession → auth | core | common | realtime
    ↓
Manual JSON parse → *Models.swift (DTOs)
```

| Layer | Path | Notes |
|-------|------|--------|
| App shell | `Fash/FashApp.swift`, `App/RootView.swift`, `App/AppRouter.swift` | Replaces `MainActivity` + overlay state |
| DI | `App/AppDependencies.swift` | Replaces `FashApplication` service locator |
| Config | `config/AppEnvironment.swift`, `config/generated/` | `apiPath`, `authServicePath`, `commonServicePath` |
| Network | `network/SecuredApiClient.swift`, `PublicBrowseHttp.swift` | JWT refresh, guest browse attestation |
| Data | `data/**` | Repositories + DTOs — see `Fash/data/README.md` |
| UI | `ui/**` | Feature folders match Android `ui/*` |

There is **no** `domain/` use-case layer on either platform.

---

## 2. Backend services

| Service | Env key | Locale prefix on paths |
|---------|---------|-------------------------|
| auth-service | `AUTH_SERVICE_BASE_URL` | Optional `/{vi\|en}/` |
| core-service | `API_BASE_URL` | Optional `/{vi\|en}/` |
| common-service | `COMMON_SERVICE_BASE_URL` | **No** locale prefix |
| realtime-service | `REALTIME_BASE_URL` | WebSocket + JWT |
| payment-service | *(never direct)* | Proxied via core `CorePaymentRepository` |

---

## 3. Navigation model

Android uses a **boolean overlay stack** in `MainActivity`. iOS uses:

- `MainNavScreen` — bottom tabs: Home, Orders, Post, Chat, Profile
- `AppRouter` — `selectedOrderId`, `chatConversationId`, `showExploreOverlay`, seller shop restore context, etc.
- `fullScreenCover` / sheets in `RootView`

Explore is an **overlay on Home**, not a tab (same product behavior as Android).

---

## 4. Auth & session

| Android | iOS |
|---------|-----|
| `AuthSessionStore` (encrypted prefs) | `AuthSessionStore` (Keychain) |
| `AppAuthManager` | `AppAuthManager` |
| `AuthTokenRefreshCoordinator` | `AuthTokenRefreshCoordinator` |
| `SecuredApiClient` interceptors | `SecuredApiClient` + `URLSession` |

Guest browse: `AppDependencies.isGuestBrowseActive` + `PublicBrowseHttp` for core public listings.

---

## 5. Common catalog cache

Android: `FashApplication.aestheticTagCatalog` refreshed at startup.

iOS: load via `commonCatalogRepository.getAestheticTags(all: true)` when implementing parity; bind in ViewModels that show tag labels (`AestheticTagLabels.resolveLabel`).

---

## 6. Realtime & push

| Channel | Android | iOS |
|---------|---------|-----|
| WebSocket | `RealtimeManager` | `RealtimeManager` |
| FCM | `FcmMessagingService` | Firebase Messaging + `PushNotificationCoordinator` |

Contract: Android `INTEGRATION.md` / `ANDROID_CORE_REALTIME_INTEGRATION.md`.

---

## 7. Porting workflow

1. Read Android Kotlin file + row in `PARITY.md`.
2. Ensure DTO exists in `Fash/data/**/**Models.swift`.
3. Port repository parsing or extend existing `*Repository.swift`.
4. Implement ViewModel + Screen under `Fash/ui/<feature>/`.
5. Wire navigation in `AppRouter` / `RootView` if new overlay.

Codegen (new files only):

```bash
FASH_ANDROID_ROOT=../fash-android-mobile python3 scripts/generate_swift_from_android.py
```

---

## 8. Related docs

| Document | Purpose |
|----------|---------|
| `Fash/data/README.md` | Data package index |
| `docs/IOS_BUSINESS_MODELS.md` | DTO catalog Android ↔ iOS |
| `docs/DATA_LAYER.md` | Repository & parsing patterns |
| `docs/common-service-api.md` | common-service for iOS |
| `docs/end-to-end-business-flow.md` | Commerce journeys + iOS screens |
| `PARITY.md` | Feature completion matrix |
| `../fash-android-mobile/ANDROID_END_TO_END_BUSINESS_FLOW.md` | API call order (source of truth) |
