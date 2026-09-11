---
name: fash-ios-mobile
description: >-
  Develop and release the Fash iOS app (SwiftUI) without a local Mac. Use when
  editing fash-ios-mobile, fixing iOS UX, API wiring to core-service, bumping
  build numbers, or pushing TestFlight via GitHub Actions on releases/* branches.
  After every user-requested product fix on this repo, commit + push and follow
  gh until TestFlight upload succeeds.
---

# Fash iOS Mobile (no-Mac workflow)

## Context

- **Repo:** `fash-ios-mobile` — SwiftUI, iOS 17+, XcodeGen (`project.yml`).
- **Backend:** `core-service` — REST under `api/v1/`.
- **No Mac locally:** compile/archive only on **GitHub Actions** (`macos-26`, Xcode 26.4).
- **Release branch:** `releases/1.0` → push triggers **iOS Release** → TestFlight (Fash-Prod).
- **Working CI remote (preferred):** `github333` → `333gih/fash-ios-mobile` (also push `origin` GitLab).

## Mandatory release loop (every product change)

When the user asks to fix / ship iOS (or “commit push TestFlight”):

1. **Bump** `project.yml` `CURRENT_PROJECT_VERSION` (never reuse a build number). Keep `MARKETING_VERSION` unless asked.
2. **Preflight** (Ubuntu-equivalent):
   ```bash
   python scripts/validate_swift_syntax.py
   ```
3. **Commit** with message style `fix(ios): <summary> (build NNN)`.
4. **Push both:**
   ```bash
   git push origin releases/1.0
   git push github333 releases/1.0
   ```
5. **Follow gh until TestFlight succeeds** (do not stop after push):
   ```bash
   gh run list -R 333gih/fash-ios-mobile --workflow "iOS Release" --branch releases/1.0 --limit 3
   gh run watch <run-id> -R 333gih/fash-ios-mobile --exit-status
   ```
6. If CI fails: read logs, fix, **bump build again**, commit, push, `gh run watch` again until **Upload to TestFlight** is green.
7. Report the Actions URL + build number to the user.

## Before every push

1. Bump **`project.yml`**: `CURRENT_PROJECT_VERSION` (build must increase for TestFlight).
2. Run Ubuntu preflight (same as CI):
   ```bash
   python scripts/validate_swift_syntax.py
   bash scripts/ci_swift_compile_preflight.sh   # if WSL/bash available
   bash scripts/ci_validate_i18n.sh
   ```
3. Read [docs/BUILD_CHECKLIST.md](../../docs/BUILD_CHECKLIST.md) and [docs/CI.md](../../docs/CI.md).

## API / chat patterns

- Guest Home must use **public browse** (`PublicBrowseHttp` + sticky `preferPublicBrowse`) — never JWT routes when logged out.
- Listing detail: `RepositoryHttp.executeCoreGet` (locale + fallback URLs).
- Message / “Nhắn tin”: if inbox already has a thread for the listing, show **Mở chat** (`notification_action_open_chat`) and open that conversation; preview Message must start/open chat (not PDP). Index: `AppDependencies.chatListingConversationIds`.

## GitHub Actions troubleshooting

| Symptom | Fix |
|---------|-----|
| Preflight fails on Ubuntu | Fix Swift syntax / i18n keys |
| `payments have failed` / spending limit | GitHub Billing → re-run **iOS Release** |
| Archive Swift errors | Artifact `fash-ios-release-logs-*` |
| TestFlight `90382` rate limit | Re-run upload later or install IPA artifact |
| Wrong remote | Prefer `github333` (`333gih/fash-ios-mobile`) for working macOS CI |

## Key paths

| Area | Path |
|------|------|
| Home feed | `Fash/ui/home/HomeViewModel.swift` |
| Public browse | `Fash/network/PublicBrowseHttp.swift` |
| Chat inbox index | `Fash/App/AppDependencies.swift`, `Fash/ui/chat/ChatViewModel.swift` |
| Preview Message | `Fash/ui/explore/ListingPreviewOverlay.swift` |
| PDP Message | `Fash/ui/listing/ProductDetailScreen.swift` |
| CI | `.github/workflows/ios-release.yml` |
| Version | `project.yml` |
