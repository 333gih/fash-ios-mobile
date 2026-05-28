#!/usr/bin/env python3
"""CI: vendor/android-res must match committed iOS Localizable.strings (vi + en)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

VENDOR_VI = ROOT / "vendor/android-res/values/strings.xml"
VENDOR_EN = ROOT / "vendor/android-res/values-en/strings.xml"
IOS_VI = ROOT / "Fash/Resources/vi.lproj/Localizable.strings"
IOS_EN = ROOT / "Fash/Resources/en.lproj/Localizable.strings"

XML_KEY = re.compile(r'<string\s+name="([^"]+)"')
STR_KEY = re.compile(r'"([^"]+)"\s*=')


def xml_keys(path: Path) -> set[str]:
    return set(XML_KEY.findall(path.read_text(encoding="utf-8")))


def strings_keys(path: Path) -> set[str]:
    return set(STR_KEY.findall(path.read_text(encoding="utf-8")))


def main() -> int:
    missing = [p for p in (VENDOR_VI, VENDOR_EN, IOS_VI, IOS_EN) if not p.is_file()]
    if missing:
        for p in missing:
            print(f"MISSING: {p.relative_to(ROOT)}", file=sys.stderr)
        return 1

    vendor_vi = xml_keys(VENDOR_VI)
    vendor_en = xml_keys(VENDOR_EN)
    ios_vi = strings_keys(IOS_VI)
    ios_en = strings_keys(IOS_EN)

    print(f"vendor vi: {len(vendor_vi)} keys")
    print(f"vendor en: {len(vendor_en)} keys")
    print(f"iOS vi:    {len(ios_vi)} keys")
    print(f"iOS en:    {len(ios_en)} keys")

    failed = False
    if vendor_vi != vendor_en:
        print(
            f"ERROR: vendor vi/en key mismatch ({len(vendor_vi)} vs {len(vendor_en)})",
            file=sys.stderr,
        )
        failed = True
    if vendor_vi != ios_vi:
        only_v = sorted(vendor_vi - ios_vi)[:8]
        only_i = sorted(ios_vi - vendor_vi)[:8]
        print(f"ERROR: vendor vi != iOS vi (vendor-only={only_v} ios-only={only_i})", file=sys.stderr)
        failed = True
    if vendor_en != ios_en:
        only_v = sorted(vendor_en - ios_en)[:8]
        only_i = sorted(ios_en - vendor_en)[:8]
        print(f"ERROR: vendor en != iOS en (vendor-only={only_v} ios-only={only_i})", file=sys.stderr)
        failed = True

    if failed:
        print(
            "Fix locally: FASH_ANDROID_ROOT=../fash-android-mobile python3 scripts/sync_from_android.py",
            file=sys.stderr,
        )
        print("Then commit vendor/ + Fash/Resources/ + Fash/Localization/L10n.swift", file=sys.stderr)
        return 1

    print("OK: committed vendor == iOS Localizable.strings (vi/en)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
