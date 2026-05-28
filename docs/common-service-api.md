# Common Service — iOS integration

iOS clients use **URLSession** + manual JSON (not Retrofit). Behavior matches Android `CommonServiceRepository` / `PublicCommonCatalogRepository`.

**Full route reference (Kotlin-oriented but authoritative):**  
`../fash-android-mobile/ANDROID_API_INTEGRATION.md`

---

## Base URL

From `env/dev.env` or `env/prod.env`:

```text
COMMON_SERVICE_BASE_URL=https://<host>/common-service
```

Swift builder:

```swift
AppEnvironment.commonServicePath("api/v1/addresses/tree")
// → {COMMON_SERVICE_BASE_URL}/api/v1/addresses/tree
```

**No** `/{vi|en}/` prefix on common-service (unlike core-service).

---

## Auth

| Client | Headers |
|--------|---------|
| Secured catalog (addresses, category image setup) | `Authorization: Bearer <JWT>` |
| Public catalog | `Accept-Language`, `X-Fash-Lang` (`vi` / `en`) only |
| Health | none |

Never ship `X-Internal-Secret` in the app.

---

## Public catalog (`PublicCommonCatalogRepository`)

| Resource | Path | Models |
|----------|------|--------|
| Category tree | `GET api/v1/public/categories/tree` | `[CategoryTreeNode]` |
| Brands | `GET api/v1/public/brands` | `BrandsPage` |
| Aesthetic tags | `GET api/v1/public/aesthetic-tags` | `[CommonAestheticTagDto]` |
| Countries | `GET api/v1/public/countries` | `[CommonCountryDto]` |
| Safe meetup zones | `GET api/v1/public/safe-meetup-zones` | `[SafeMeetupZoneDto]` |
| Review badges | `GET api/v1/public/review-badges?all=true` | `[ReviewBadgeDto]` |

Used by: Explore filters (guest + authed), post flow tags, deal review, meetup location picker.

---

## Secured catalog (`CommonServiceRepository`)

| Resource | Path | Notes |
|----------|------|--------|
| Address tree | `GET api/v1/addresses/tree` | VN provinces → districts → wards |
| Address list | `GET api/v1/addresses?level=&parent_id=` | Fallback when tree walk needed |
| Listing image setup | `GET api/v1/categories/{id}/listing-image-setup` | Post wizard steps |
| Health | `GET health` | Plain `"ok"` string body |

Delegates brands/categories/tags/countries to public repo for read paths.

---

## Swift files

| File | Role |
|------|------|
| `Fash/data/common/CommonServiceModels.swift` | All DTOs |
| `Fash/data/common/CommonServiceRepository.swift` | Secured GET |
| `Fash/data/common/PublicCommonCatalogRepository.swift` | Public GET |
| `Fash/data/common/AestheticTagLabels.swift` | Locale labels |

---

## Pagination

Query `offset` (default 0) and `limit` (default 20, max 100). Response may include `total`, `has_more`.

---

## Errors

JSON envelope:

```json
{ "code": 400, "error": "validation_failed: …" }
```

Parse with `CoreServiceErrors.parseMessage`.
