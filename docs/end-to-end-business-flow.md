# End-to-end business flows — iOS screen map

API call order and payloads are defined in Android:

**`../fash-android-mobile/ANDROID_END_TO_END_BUSINESS_FLOW.md`**

This document maps those journeys to **iOS screens** under `Fash/ui/` for implementation tracking.

---

## 1. Discovery → PDP

| Step | API (core) | iOS screen / VM |
|------|------------|-----------------|
| Home feed | `GET /listings/home`, recommendations | `HomeFeedContent`, `HomeViewModel` |
| Explore search | `GET /search/listings` | `ExploreScreen`, `ExploreViewModel` |
| PDP | `GET /listings/:id` | `ProductDetailScreen`, `ProductDetailViewModel` |
| Like / save | `POST` wishlist / likes | PDP + grid cards |

**Catalog filters:** `PublicCommonCatalogRepository` → `ExploreFilterPickers` (to implement).

---

## 2. Guest browse

| Step | Behavior | iOS |
|------|----------|-----|
| Browse without login | `PublicBrowseHttp` | `AppDependencies.isGuestBrowseActive` |
| Locked tabs | Orders, Post, Chat, Profile | `GuestTabPlaceholder` in `MainNavScreen` |

---

## 3. Auth → onboarding

| Step | API (auth/core) | iOS |
|------|-----------------|-----|
| OTP / social | auth-service | `LoginScreen`, `OtpVerifyScreen` |
| Setup status | `GET /users/.../setup-status` | `RootView` gate |
| Username, password, photo, prefs, sizing, tags | `PATCH /users/me`, common tags | `ui/onboarding/*` |

---

## 4. Create listing

| Step | API | iOS |
|------|-----|-----|
| Category tree | common-service public | `PostViewModel` |
| Image setup steps | common-service secured | `CreateListingFlowScreen` |
| Upload images | `POST` multipart | `PostViewModel` (partial) |
| Create | `POST /listings` | `ListingRepository.createListing` |

Models: `ListingModels.CreateListingRequest`.

---

## 5. Chat → offer → order OR deal

| Step | API | iOS |
|------|-----|-----|
| Inbox | `GET /chat/conversations` | `ChatScreen`, `ChatViewModel` |
| Thread | `GET /chat/conversations/:id` | `ChatDetailScreen` |
| Send offer | `POST /chat/offers` | Chat detail (partial) |
| Accept (escrow) | `POST /chat/offers/accept` | Feature flag: env `CHAT_USE_SOFT_OFFER_ACCEPT` |
| Soft accept (C2C) | `POST /chat/offers/accept-in-chat` | Same |
| Checkout | `POST /orders`, payment proxy | `CheckoutScreen` (stub) |
| Offline deal | deals API | `DealRepository` |

Meetup: `MeetingAppointmentPayload`, `SafeMeetupZoneDto` — see Android `C2C_CHAT_MEETINGS_DEALS_CHANGELOG_SPEC.md`.

---

## 6. Orders & fulfillment

| Step | API | iOS |
|------|-----|-----|
| Order list | `GET /orders` | `OrdersScreen` |
| Order detail | `GET /orders/:id` | `OrderDetailScreen` (stub UI) |
| Meetup check-in | `POST …/check-in` | `OrderDetailViewModel` (to port) |
| Payment pending | payment status poll | `PendingPaymentViewModel` |

Models: `OrderModels.OrderDetailPayload`.

---

## 7. Profile & social

| Step | API | iOS |
|------|-----|-----|
| Me / seller profile | `GET /users/me`, `GET /users/:id` | `ProfileScreen`, `SellerProfileScreen` |
| Followers | `GET /users/.../followers` | `FollowConnectionsScreen` |
| Notifications | inbox APIs | `NotificationScreen` |

---

## 8. Realtime & push

After REST mutations, server may emit WebSocket events — handle in `RealtimeManager` and refresh ViewModels. Push deep links: `deeplink/*` + `AppRouter`.

See Android `INTEGRATION.md` and `PUSH_NOTIFICATIONS.md` (iOS).

---

## QA checklist (per release)

- [ ] Guest can browse home/explore and open PDP
- [ ] Login → onboarding gate → main tabs
- [ ] Post flow uses category + image steps from common-service
- [ ] Chat send/receive; offer states match server flag
- [ ] Order list → detail for escrow path
- [ ] Locale `vi`/`en` on core + common public headers
