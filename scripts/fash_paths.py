"""Resolve paths for iOS repo; Android sibling is optional (maintainer sync only)."""
from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS_ENV = ROOT / "env"
ANDROID_SIBLING = ROOT.parent / "fash-android-mobile"


def android_root() -> Path | None:
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
    android = android_root()
    if android:
        live = android / "app/src/main/res/values/strings.xml"
        if live.is_file():
            return live
    vendored = ROOT / "vendor" / "android-res" / "values" / "strings.xml"
    if vendored.is_file():
        return vendored
    return None


def android_strings_en() -> Path | None:
    android = android_root()
    if android:
        live = android / "app/src/main/res/values-en/strings.xml"
        if live.is_file():
            return live
    vendored = ROOT / "vendor" / "android-res" / "values-en" / "strings.xml"
    if vendored.is_file():
        return vendored
    return None
