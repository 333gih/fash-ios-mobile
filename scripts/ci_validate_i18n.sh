#!/usr/bin/env bash
# CI / TestFlight: validate committed i18n + AppIcon. Never sync from Android on CI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Validate committed assets (vendor vi/en + Localizable.strings + L10n + AppIcon)"

for f in \
  vendor/android-res/values/strings.xml \
  vendor/android-res/values-en/strings.xml \
  Fash/Resources/vi.lproj/Localizable.strings \
  Fash/Resources/en.lproj/Localizable.strings \
  Fash/Localization/L10n.swift
do
  if [[ ! -f "$f" ]]; then
    echo "error: missing committed file: $f" >&2
    echo "  Local: .\\scripts\\sync.ps1  then commit vendor/, Fash/Resources/, Fash/Localization/" >&2
    exit 1
  fi
done

for icon in AppIcon-1024.png AppIcon-120.png AppIcon-152.png; do
  if [[ ! -f "Fash/Assets.xcassets/AppIcon.appiconset/${icon}" ]]; then
    echo "error: missing committed AppIcon: ${icon}" >&2
    echo "  Local: .\\scripts\\sync.ps1  then commit Fash/Assets.xcassets/AppIcon.appiconset/*.png" >&2
    exit 1
  fi
done

python3 scripts/validate_strings.py
python3 scripts/validate_l10n_swift.py
python3 scripts/compare_android_ios_strings.py

echo "==> OK: vi/en strings + AppIcon committed (CI needs no Android checkout)"
