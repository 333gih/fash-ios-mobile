#!/usr/bin/env python3
"""
One-shot maintainer script: copy Android env + strings into fash-ios-mobile so
the iOS repo builds without a sibling fash-android-mobile checkout.

Usage (from fash-ios-mobile):
  FASH_ANDROID_ROOT=../fash-android-mobile python3 scripts/vendor_from_android.py
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from fash_paths import android_root  # noqa: E402


def main() -> int:
    android = android_root()
    if not android:
        print(
            "error: set FASH_ANDROID_ROOT or clone fash-android-mobile next to fash-ios-mobile",
            file=sys.stderr,
        )
        return 1

    env_src = android / "env"
    for name in ("dev.env", "prod.env"):
        src = env_src / name
        if not src.is_file():
            print(f"error: missing {src}", file=sys.stderr)
            return 1
        dst = ROOT / "env" / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"copied {src} -> {dst}")

    for sub in ("values", "values-en"):
        src = android / "app/src/main/res" / sub / "strings.xml"
        if not src.is_file():
            print(f"warning: missing {src}", file=sys.stderr)
            continue
        dst = ROOT / "vendor" / "android-res" / sub / "strings.xml"
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        print(f"copied {src} -> {dst}")

    font_dir = android / "app/src/main/res/font"
    out_fonts = ROOT / "Fash" / "Resources" / "Fonts"
    out_fonts.mkdir(parents=True, exist_ok=True)
    FONT_MAP = {
        "be_vietnam_pro_regular.ttf": "BeVietnamPro-Regular.ttf",
        "be_vietnam_pro_semibold.ttf": "BeVietnamPro-SemiBold.ttf",
        "be_vietnam_pro_bold.ttf": "BeVietnamPro-Bold.ttf",
    }
    if font_dir.is_dir():
        for ttf in font_dir.glob("*.ttf"):
            dest_name = FONT_MAP.get(ttf.name.lower(), ttf.name)
            shutil.copy2(ttf, out_fonts / dest_name)
            print(f"copied font {ttf.name} -> {dest_name}")
    else:
        print("warning: no res/font/ — add Be Vietnam Pro .ttf manually", file=sys.stderr)

    print("\nRun: python3 scripts/android_strings_to_ios.py && python3 scripts/env_to_xcconfig.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
