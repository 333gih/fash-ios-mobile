# Data layer guide (iOS)

Patterns copied from **fash-android-mobile** repositories. Android often uses `org.json`; iOS uses `[String: Any]` + `RepositoryHttp`.

---

## Repository template

```swift
final class ExampleRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    func getThing(id: String) async -> Result<ThingDto, Error> {
        do {
            let url = AppEnvironment.apiPath("listings/\(id)")
            let data = try await client.get(urlString: url)
            let obj = try RepositoryHttp.jsonObject(data)
            return .success(parseThing(obj))
        } catch {
            return .failure(error)
        }
    }
}
```

- **Authenticated core routes:** `AppEnvironment.apiPath("…")` — may try `/{vi|en}/api/v1/…` then legacy URL.
- **Common-service:** `AppEnvironment.commonServicePath("api/v1/…")` — no locale segment.
- **Public catalog:** `PublicCommonCatalogRepository` — no Bearer; sets `Accept-Language` / `X-Fash-Lang`.
- **Guest browse:** `PublicBrowseHttp` + core `/api/v1/public/…`.

---

## Error handling

| Android | iOS |
|---------|-----|
| `CoreServiceHttpException` | `CoreServiceHttpException` |
| `CoreServiceErrors.parseErrorMessage()` | `CoreServiceErrors.parseMessage(data:statusCode:)` |

Surface errors in ViewModels; global session clear via `SecuredApiClient` → `AppDependencies.handleSessionCleared`.

---

## Parsing rules

1. Prefer `RepositoryHttp.optString(_:keys...)` for snake_case and PascalCase.
2. Arrays: `obj["items"]` with fallbacks (`brands`, `tags`, `tree`, …) — match Android tolerance.
3. Money: `Int64` VND fields (`price_vnd`, `amount_vnd`).
4. Optional nested objects: guard with `as? [String: Any]`.
5. Keep **parse functions private** at bottom of repository file unless shared → `*Parsing.swift` or `*JsonParser.swift`.

---

## Local persistence

| Android | iOS | Typical keys |
|---------|-----|--------------|
| `AuthSessionStore` | `AuthSessionStore` | access/refresh token, userId |
| `OnboardingLocalStore` | `OnboardingLocalStore` | skip flags |
| `AddressLocalStore` | `AddressLocalStore` | draft VN admin selection |
| `BrowseSessionStore` | `BrowseSessionStore` | explore location prefs |
| `AppThemePreference` | `AppThemePreference` | light/dark |

---

## Multipart uploads

Listing images and avatar uploads use multipart from repository methods (see Android `ListingRepository` / `UserRepository`). iOS should use `URLSession.upload` with the same field names as documented in `android-listings-api.md`.

---

## Testing a new endpoint

1. Confirm path in Android repo or `core-service-api.md`.
2. Add DTO in `*Models.swift`.
3. Implement repository method returning `Result`.
4. Call from ViewModel; log `CoreServiceHttpException.message` on failure.
5. Add row to `docs/IOS_BUSINESS_MODELS.md`.
