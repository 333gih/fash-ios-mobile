# Scripts (`fash-ios-mobile/scripts`)

## GitHub Actions / TestFlight (committed source only)

CI **does not** checkout `fash-android-mobile` and **does not** run sync.

| Script | Role |
|--------|------|
| `ci_ios_prepare.sh` | Entry: validate i18n + icon → XcodeGen → SPM |
| `ci_validate_i18n.sh` | `vendor/` + `Localizable.strings` + `L10n.swift` present & matching |
| `validate_strings.py` | `.strings` file syntax |
| `validate_l10n_swift.py` | `L10n.*` matches Swift call sites |
| `compare_android_ios_strings.py` | `vendor vi/en` keys == `iOS vi/en` keys |
| `validate_swift_syntax.py` | Static Swift checks |
| `ci_patch_release_signing.sh` | Patch signing for release archive |
| `ci_verify_ipa_version.sh` | IPA version == `project.yml` |

**Must be committed before push:**

- `vendor/android-res/values/strings.xml`
- `vendor/android-res/values-en/strings.xml`
- `Fash/Resources/vi.lproj/Localizable.strings`
- `Fash/Resources/en.lproj/Localizable.strings`
- `Fash/Localization/L10n.swift`
- `Fash/Assets.xcassets/AppIcon.appiconset/*.png`

---

## Local only — sync from Android (then commit)

| Script | Role |
|--------|------|
| `sync.ps1` | Windows: run full sync |
| `sync_from_android.py` | Pull Android strings + icon → vendor + iOS files |
| `vendor_from_android.py` | Copy `strings.xml` + env + fonts (used by sync) |
| `android_strings_to_ios.py` | Generate `Localizable.strings` + `L10n.swift` from vendor |
| `sync_app_icon_from_android.ps1` | App icon from `mipmap-xxxhdpi/ic_launcher.png` (Windows) |
| `sync_app_icon_from_android.sh` | Same on macOS (used by `sync_from_android.py`) |
| `env_to_xcconfig.py` | `env/*.env` → `Config/*.xcconfig` |

```powershell
cd fash-ios-mobile
$env:FASH_ANDROID_ROOT="..\fash-android-mobile"
python scripts/sync_from_android.py
# commit vendor/, Fash/Resources/, Fash/Localization/, AppIcon PNGs
```

---

## GitHub secrets (OK to run locally)

| Script | Role |
|--------|------|
| `push_github_ios_secrets.ps1` | Upload signing secrets to GitHub |
| `push_github_ios_secrets.sh` | Same (bash) |

---

## Local Mac dev build

| Script | Role |
|--------|------|
| `setup_mac.sh` | Install XcodeGen |
| `build_mac.sh` | Validate (same as CI) + simulator build |
| `check_env.ps1` | Windows env checklist |

---

## Rare / optional

| Script | Role |
|--------|------|
| `generate_swift_from_android.py` | Kotlin → Swift scaffolds (not i18n; run manually) |
| `fash_paths.py` | Path helpers (imported by Python scripts) |
