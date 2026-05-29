# Fash iOS — Agent instructions (Cursor / AI)

> **Read this file first** before editing `fash-ios-mobile`. Humans develop on **Windows + Cursor**; **no local Xcode**. Builds run on **GitHub Actions macOS** (limited minutes).

## Non-negotiables

1. **Never push to `releases/*` to “try a build”.** Validate locally first (see below), then push once.
2. **Run all pre-push checks** before asking the user to push (or push yourself).
3. **Match existing code** in the same folder — naming, `@MainActor`, parsers, SwiftUI patterns.
4. **Minimize diff scope** — fix only what the task requires; no drive-by refactors.
5. **Android parity** — when porting UI/logic, read the matching Kotlin file in `fash-android-mobile` first.
6. **Do not commit** `secrets/`, `.env` keys, or `run.md`-style local notes.

## Pre-push gate (Windows — no Mac)

From repo root `fash-ios-mobile/`:

```powershell
.\scripts\check_before_push.ps1
```

Or manually:

```bash
python scripts/validate_swift_syntax.py
bash scripts/ci_validate_i18n.sh
bash scripts/ci_swift_compile_preflight.sh
```

All must exit `0`. If bash is missing on Windows, use Git Bash or WSL.

## Branch strategy (save CI budget)

| Branch | Push when | CI workflow | Cost |
|--------|-----------|-------------|------|
| `develop` | Feature complete, checks pass | iOS Build (simulator) | macOS minutes |
| PR → `develop` | Preferred for review | iOS Build on PR | macOS minutes |
| `releases/*` | **TestFlight / App Store only** | iOS Release (archive + TF) | **Highest** |

**Rule:** Batch work on `develop` (or feature branches → PR). Only merge/push `releases/*` after green checks + user asks for TestFlight.

## Where to look

| Topic | Doc |
|-------|-----|
| Full Cursor workflow | [docs/CURSOR_DEVELOPMENT.md](docs/CURSOR_DEVELOPMENT.md) |
| Swift / SwiftUI rules | [docs/CODE_CONVENTIONS.md](docs/CODE_CONVENTIONS.md) |
| CI minutes & branching | [docs/CI_BUDGET.md](docs/CI_BUDGET.md) |
| Pre-release checklist | [docs/BUILD_CHECKLIST.md](docs/BUILD_CHECKLIST.md) |
| GitHub mirror & TestFlight | [docs/CI.md](docs/CI.md) |
| Architecture | [IOS_ARCHITECTURE.md](IOS_ARCHITECTURE.md) |
| Android ↔ iOS features | [PARITY.md](PARITY.md) |
| Scripts | [scripts/README.md](scripts/README.md) |

## Release version bump

Before TestFlight push, edit `project.yml`:

```yaml
MARKETING_VERSION: "1.0.x"
CURRENT_PROJECT_VERSION: "NN"   # increment every upload; never reuse
```

## Typical task flow

```text
1. Read Android reference (if parity task)
2. Read 1–2 existing Swift files in target module
3. Implement minimal change
4. Run check_before_push.ps1
5. Commit with clear message
6. Push develop (compile CI) OR releases/* (only when user wants TestFlight)
7. Monitor: gh run list --repo techheart-in-my-heart/fash-ios-mobile
```

## GitHub remote

Primary Actions repo: `techheart-in-my-heart/fash-ios-mobile`  
GitLab `origin` mirrors to GitHub; direct push when mirror is slow:

```bash
git push techheart <branch>
```

## When CI fails

1. Open failed run → step **Print xcodebuild errors**
2. Grep log: `\.swift:[0-9]+:[0-9]+: error:`
3. Fix **all** errors in one commit (avoid 49→50→51 retry chains)
4. Bump `CURRENT_PROJECT_VERSION` if retrying release branch
5. Re-run checks locally before push

## Adding strings / assets

CI does **not** sync Android. Commit:

- `vendor/android-res/values/strings.xml` + `values-en/`
- `Fash/Resources/{vi,en}.lproj/Localizable.strings`
- `Fash/Localization/L10n.swift`

See [scripts/README.md](scripts/README.md) for `sync.ps1`.
