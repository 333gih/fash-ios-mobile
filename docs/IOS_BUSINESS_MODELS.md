# iOS business models — Android mapping

DTOs live under `Fash/data/<domain>/`. Parsers stay in `*Repository.swift` unless shared (e.g. `ListingFeedJsonParser`).

**Status legend:** ✅ wired in repo/parsers · 📋 struct ready · 🔲 stub / empty enum to implement

---

## common-service (`data/common/`)

| Model | Android | iOS file | Status |
|-------|---------|----------|--------|
| `AddressTreeNode` | `CommonServiceModels.kt` | `CommonServiceModels.swift` | 📋 |
| `CommonAddressDto` | same | same | ✅ |
| `CommonBrandDto`, `BrandsPage` | same | same | ✅ |
| `CategoryTreeNode`, `CommonCategoryDto` | same | same | ✅ |
| `CommonAestheticTagDto` | same | same | ✅ |
| `CommonCountryDto` | same | same | ✅ |
| `ListingImageStepCatalog`, `ListingImageSetupDto` | same | same | ✅ |
| `SafeMeetupZoneDto` | same | same | 📋 |
| `ReviewBadgeDto` | same | same | 📋 |
| `AestheticTagLabels` helpers | `AestheticTagLabels.kt` | `AestheticTagLabels.swift` | ✅ |

**Repositories:** `CommonServiceRepository`, `PublicCommonCatalogRepository`

---

## Listings (`data/listing/`)

| Model | Android | iOS file | Status |
|-------|---------|----------|--------|
| `ListingFeedItem` | `ListingModels.kt` | `ListingFeedJsonParser.swift` | ✅ |
| `ListingDetail` | `ListingModels.kt` | `ListingModels.swift` | 📋 |
| `ListingShippingAddress`, `AestheticTagRef` | same | `ListingModels.swift` | 📋 |
| `CreateListingRequest`, `ListingImageStepPayload` | `ListingRepository.kt` | `ListingModels.swift` | ✅ |
| `CreateListingResponse`, `UpdateListingRequest` | same | `ListingModels.swift` | 📋 / 📋 |
| `ListingPreviewDetail` | UI helper | `ListingPreviewDetail.swift` | ✅ |

---

## User (`data/user/`)

| Model | Android | iOS file | Status |
|-------|---------|----------|--------|
| `ProfileInfo` | `UserRepository.kt` | `UserModels.swift` | ✅ |
| `UserAccessStatus`, `ProfilePatch` | same | `UserModels.swift` | 📋 |
| `UserSearchResult`, `FollowListPage` | same | `UserModels.swift` | 📋 |
| `SizingReferenceRequest`, `AestheticTagPutItem` | same | `UserModels.swift` | 📋 |
| `InboxNotificationItem` | `InboxNotification.kt` | `InboxNotification.swift` | partial |
| `SellerListingFocus` | `SellerListingFocus.kt` | `SellerListingFocus.swift` | partial |

---

## Chat & deals

| Model | Android | iOS file | Status |
|-------|---------|----------|--------|
| `ConversationItem` | `ChatRepository.kt` | `ChatModels.swift` | ✅ |
| `ConversationDetail`, `ChatMessage` | same | `ChatModels.swift` | ✅ |
| `PriceOffer`, `MeetingAppointmentPayload` | same | `ChatModels.swift` | 📋 |
| `DealRecord`, `ReviewBadgeRefPayload` | `DealRepository.kt` | `DealModels.swift` | 📋 |

---

## Orders & payments

| Model | Android | iOS file | Status |
|-------|---------|----------|--------|
| `OrderItem` | `OrderRepository.kt` | `OrderModels.swift` | ✅ |
| `OrderDetail` (payload) | `OrderDetail.kt` | `OrderModels.swift` (`OrderDetailPayload`) | 📋 |
| `OrderMeetingAppointment`, `OrderMeetingGrace` | same | `OrderModels.swift` | 📋 |
| `PendingPayment*` | `PendingPaymentApiModels.kt` | `PendingPaymentApiModels.swift` | 🔲 |
| `PaymentGatewayOption`, `PaymentInitiateResult` | `CorePaymentRepository.kt` | `PaymentModels.swift` | 📋 |

---

## Discovery & home

| Model | Android | iOS file | Status |
|-------|---------|----------|--------|
| `FeaturedSellerItem` | `FeaturedSellerModels.kt` | `FeaturedSellerModels.swift` | partial |
| `HomeUxPersonalization` | `UxPersonalizationModels.kt` | `UxPersonalizationModels.swift` | partial |
| `HomeDiscoveryBundle` | `HomeDiscoveryRepository.kt` | `HomeDiscoveryRepository.swift` | 🔲 |
| `AdvertisingModels` | `AdvertisingModels.kt` | `AdvertisingModels.swift` | partial |

---

## Auth

| Model | Android | iOS file | Status |
|-------|---------|----------|--------|
| `AuthSession` | `AuthSession.kt` | `AuthSessionStore.swift` | ✅ |
| OTP / social payloads | `AuthRepository.kt` | `AuthModels.swift` | 📋 |

---

## When adding a field

1. Add property to the Swift struct with a sensible default.
2. Extend the repository `parse*` helper (tolerant keys via `RepositoryHttp.optString`).
3. Update this table and the Android model comment if the API doc changed.
