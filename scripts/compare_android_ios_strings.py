#!/usr/bin/env python3
"""Compare Android strings.xml vs iOS Localizable.strings key parity."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from fash_paths import android_strings_en, android_strings_vi  # noqa: E402

XML_KEY = re.compile(r'<string\s+name="([^"]+)"')
STR_KEY = re.compile(r'"([^"]+)"\s*=')


def xml_keys(path: Path) -> set[str]:
    return set(XML_KEY.findall(path.read_text(encoding="utf-8")))


def strings_keys(path: Path) -> set[str]:
    return set(STR_KEY.findall(path.read_text(encoding="utf-8")))


def main() -> int:
    vi_xml = android_strings_vi()
    en_xml = android_strings_en()
    vi_ios = ROOT / "Fash/Resources/vi.lproj/Localizable.strings"
    en_ios = ROOT / "Fash/Resources/en.lproj/Localizable.strings"

    if not vi_xml or not vi_xml.is_file():
        print("Missing Android vi strings source", file=sys.stderr)
        return 1

    vi_a = xml_keys(vi_xml)
    en_a = xml_keys(en_xml) if en_xml and en_xml.is_file() else set()
    vi_i = strings_keys(vi_ios) if vi_ios.is_file() else set()
    en_i = strings_keys(en_ios) if en_ios.is_file() else set()

    print(f"Android vi: {len(vi_a)} keys")
    print(f"Android en: {len(en_a)} keys")
    print(f"iOS vi:     {len(vi_i)} keys")
    print(f"iOS en:     {len(en_i)} keys")
    print(f"Android en missing vs vi: {len(vi_a - en_a)}")
    print(f"iOS-only (not in Android vi): {len(vi_i - vi_a)}")
    if vi_i - vi_a:
        for k in sorted(vi_i - vi_a)[:20]:
            print(f"  ios-only: {k}")
    print(f"Android-only (not in iOS vi): {len(vi_a - vi_i)}")
    if vi_a - vi_i:
        for k in sorted(vi_a - vi_i)[:20]:
            print(f"  android-only: {k}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
