"""Resolve paths for iOS repo; vendor/android-res is the committed string source for CI/build."""
from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS_ENV = ROOT / "env"
ANDROID_SIBLING = ROOT.parent / "fash-android-mobile"
VENDOR_VI = ROOT / "vendor" / "android-res" / "values" / "strings.xml"
VENDOR_EN = ROOT / "vendor" / "android-res" / "values-en" / "strings.xml"


def android_root() -> Path | None:
    """Live Android checkout — maintainer sync only (sync_from_android.py)."""
    override = os.environ.get("FASH_ANDROID_ROOT", "").strip()
    if override:
        p = Path(override).expanduser().resolve()
        return p if p.is_dir() else None
    return ANDROID_SIBLING if ANDROID_SIBLING.is_dir() else None


def env_dir() -> Path:
    if (IOS_ENV / "dev.env").is_file() and (IOS_ENV / "prod.env").is_file():
        return IOS_ENV
    android = android_root()
    if android and (android / "env" / "dev.env").is_file():
        return android / "env"
    return IOS_ENV


def android_strings_vi() -> Path | None:
    """Committed vendor first — CI and archive use this, not a sibling checkout."""
    if VENDOR_VI.is_file():
        return VENDOR_VI
    android = android_root()
    if android:
        live = android / "app/src/main/res/values/strings.xml"
        if live.is_file():
            return live
    return None


def android_strings_en() -> Path | None:
    if VENDOR_EN.is_file():
        return VENDOR_EN
    android = android_root()
    if android:
        live = android / "app/src/main/res/values-en/strings.xml"
        if live.is_file():
            return live
    return None
