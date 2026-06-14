---
name: fash-ios-mobile
description: >-
  Develop and release the Fash iOS app (SwiftUI) without a local Mac. Use when
  editing fash-ios-mobile, fixing iOS UX, API wiring to core-service, bumping
  build numbers, or pushing TestFlight via GitHub Actions on releases/* branches.
---

# Fash iOS Mobile (no-Mac workflow)

## Context

- **Repo:** `fash-ios-mobile` — SwiftUI, iOS 17+, XcodeGen (`project.yml`).
- **Backend:** `core-service` (Go) — REST under `api/v1/`.
- **No Mac locally:** compile/archive only on **GitHub Actions** (`macos-26`, Xcode 26.4).
- **Release branch:** `releases/1.0` → push triggers **iOS Release** → TestFlight (Fash-Prod).

## Before every push

1. Bump **`project.yml`**: `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` (build must increase for TestFlight).
2. Run Ubuntu preflight (same as CI):
   ```bash
   python3 scripts/validate_swift_syntax.py
   bash scripts/ci_swift_compile_preflight.sh
   bash scripts/ci_validate_i18n.sh
   ```
3. Read [docs/BUILD_CHECKLIST.md](../../docs/BUILD_CHECKLIST.md) and [docs/CI.md](../../docs/CI.md).

## API patterns (must follow)

- **Never** use single `AppEnvironment.apiPath` for GET listing detail — use `RepositoryHttp.executeCoreGet` (tries locale-prefixed + fallback URLs).
- Listing detail: `GET api/v1/listings/{id}` — one payload for PDP and edit.
- Profile tabs paginate: `GET api/v1/users/me/listings?status=active&limit=20&offset=N`.
- Profile / Seller screens: **`useStaggeredMasonryGrid` / `masonryEagerLayout` must appear before `showGridLoading`** in `ProfileCollapsingScrollLayout(...)` — Swift memberwise init order.

## Performance conventions

| Screen | Rule |
|--------|------|
| **Edit listing** | Fetch listing detail **in parallel** with catalog (brands/countries/tags). Show form when detail returns. |
| **PDP** | Set `isLoading = false` after detail; discovery rails + `recordView` in background `Task`. |
| **Profile grid** | `ListingStaggeredMasonryView` + `masonryEagerLayout: true` for own profile; paginate with `FeedLoadMoreFooter`. |
| **Home load-more** | Preserve scroll anchor via `HomeFeedScrollCoordinator`; batch append in VM. |

## GitHub Actions troubleshooting

| Symptom | Fix |
|---------|-----|
| Preflight fails on Ubuntu | Fix Swift syntax / i18n keys — read workflow log step **Swift syntax + compile preflight**. |
| `payments have failed` / spending limit | GitHub Billing → add payment → re-run **iOS Release**. |
| Archive Swift errors | Download artifact `fash-ios-release-logs-*` or expand **Print xcodebuild errors**. |
| TestFlight `90382` rate limit | Archive OK; re-run upload after ~24h or install IPA artifact manually. |
| Missing signing secrets | See `docs/CI.md` § App Store release — `IOS_DISTRIBUTION_*`, `APPLE_TEAM_ID`, ASC API key. |
| GoogleService-Info BUNDLE_ID mismatch | Prod secret must match `com.pc.fash-ios-mobile`. |

## Commit & TestFlight

```bash
git add -A
git commit -m "fix(ios): <summary> (build NNN)"
git push origin releases/1.0
```

Monitor: GitHub → Actions → **iOS Release** → TestFlight processing ~5–30 min.

## Key paths

| Area | Path |
|------|------|
| Listing detail API client | `Fash/data/listing/ListingRepository.swift` |
| PDP VM | `Fash/ui/listing/ProductDetailViewModel.swift` |
| Edit VM | `Fash/ui/listing/EditListingViewModel.swift` |
| Profile tabs | `Fash/ui/main/tabs/ProfileViewModel.swift`, `ProfileCollapsingScrollLayout.swift` |
| Home feed | `Fash/ui/home/HomeFeedContent.swift`, `HomeViewModel.swift` |
| CI workflow | `.github/workflows/ios-release.yml` |
| Version | `project.yml` |

## core-service coordination

- iOS changes often need **no** core-service deploy if API contract unchanged.
- If adding endpoints, implement in `core-service` on `develop`, deploy, then wire iOS.
- Listing read path: `internal/delivery/http/handlers/listing.handler.go` → `GetListing`.
