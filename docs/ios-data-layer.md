# Fash iOS — Data layer

Package mirror of Android `com.pc.fash_android_mobile.data.*`. There is **no separate domain layer**; ViewModels call repositories directly.

## Layout

| Folder | Android equivalent | Models file | Repository |
|--------|-------------------|-------------|------------|
| `auth/` | `data/auth/` | `AuthModels.swift` (+ `AuthSession` in store) | `AuthRepository` |
| `common/` | `data/common/` | `CommonServiceModels.swift` | `CommonServiceRepository`, `PublicCommonCatalogRepository` |
| `user/` | `data/user/` | `UserModels.swift` | `UserRepository` (+ extensions) |
| `listing/` | `data/listing/` | `ListingModels.swift`, `ListingFeedItem` in `ListingFeedJsonParser.swift` | `ListingRepository` |
| `chat/` | `data/chat/` | `ChatModels.swift` | `ChatRepository` |
| `order/` | `data/order/` | `OrderModels.swift`, `OrderDetail.swift` | `OrderRepository` |
| `deal/` | `data/deal/` | `DealModels.swift` | `DealRepository` |
| `payment/` | `data/payment/` | `PaymentModels.swift` | `CorePaymentRepository` |
| `search/` | `data/search/` | `FeaturedSellerModels.swift` | `SearchRepository` |
| `address/` | `data/address/` | `ShippingAddress.swift` | `UserShippingAddressRepository` |
| `recommendation/` | `data/recommendation/` | `UxPersonalizationModels.swift` | `RecommendationRepository` |
| `http/` | `data/http/` | — | `HttpJson`, `CoreServiceErrors` |
| `realtime/` | `data/realtime/` | `RealtimeEvent.swift` | `RealtimeManager` |

## Conventions

1. **DTOs** live in `*Models.swift` (or co-located parser files for feed rows). Match Android field names in comments; parsers accept `snake_case` and PascalCase.
2. **Repositories** return `Result<T, Error>` and use `SecuredApiClient` for JWT routes, or plain `URLSession` for public common-service catalog.
3. **Local stores** (`*Store`, `*Preference`) wrap `UserDefaults` / Keychain — same roles as Android `SharedPreferences` / `EncryptedSharedPreferences`.
4. Wire **create-listing** payloads via `ListingModels.CreateListingRequest`, not ad-hoc dictionaries.

## Common-service (port first)

Catalog data is shared across onboarding, Explore filters, post flow, addresses, and chat meetups. See `docs/common-service-api.md` and Android `ANDROID_API_INTEGRATION.md`.

## Adding a new feature

1. Add DTOs to the matching `*Models.swift` (or create one).
2. Add repository methods under `data/<feature>/`.
3. Register lazy access on `AppDependencies` if a new repository is needed.
4. Update `docs/IOS_BUSINESS_MODELS.md` with the Android ↔ iOS mapping row.
