#!/usr/bin/env python3
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def xml_keys(path):
    return set(re.findall(r'<string\s+name="([^"]+)"', path.read_text(encoding="utf-8")))

def str_keys(path):
    return set(re.findall(r'"([^"]+)"\s*=', path.read_text(encoding="utf-8")))

android_vi = ROOT.parent / "fash-android-mobile/app/src/main/res/values/strings.xml"
android_en = ROOT.parent / "fash-android-mobile/app/src/main/res/values-en/strings.xml"
ios_vi = ROOT / "Fash/Resources/vi.lproj/Localizable.strings"
ios_en = ROOT / "Fash/Resources/en.lproj/Localizable.strings"

for prefix in ["notification_", "chat_", "notifications"]:
    av = {k for k in xml_keys(android_vi) if k.startswith(prefix)}
    ae = {k for k in xml_keys(android_en) if k.startswith(prefix)}
    iv = {k for k in str_keys(ios_vi) if k.startswith(prefix)}
    ie = {k for k in str_keys(ios_en) if k.startswith(prefix)}
    print(f"=== {prefix}* ===")
    print(f"Android vi: {len(av)}, en: {len(ae)} | iOS vi: {len(iv)}, en: {len(ie)}")
    missing_vi = sorted(av - iv)
    missing_en = sorted(ae - ie)
    if missing_vi:
        print("Missing in iOS vi:", missing_vi)
    if missing_en:
        print("Missing in iOS en:", missing_en)
    extra_vi = sorted(iv - av)
    extra_en = sorted(ie - ae)
    if extra_vi:
        print("Extra in iOS vi:", extra_vi)
    if extra_en:
        print("Extra in iOS en:", extra_en)
    print()
