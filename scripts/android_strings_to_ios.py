#!/usr/bin/env python3
"""Convert Android strings.xml to iOS Localizable.strings + type-safe L10n.swift."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from fash_paths import android_strings_en, android_strings_vi  # noqa: E402
OUT_VI = ROOT / "Fash" / "Resources" / "vi.lproj"
OUT_EN = ROOT / "Fash" / "Resources" / "en.lproj"
OUT_L10N = ROOT / "Fash" / "Localization"


def parse_strings_xml(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    entries: dict[str, str] = {}
    # <string name="key">value</string> and formatted strings
    pattern = re.compile(
        r'<string\s+name="([^"]+)"(?:\s+[^>]*)?>(.*?)</string>',
        re.DOTALL,
    )
    for name, raw in pattern.findall(text):
        value = raw.strip()
        value = value.replace("\\'", "'")
        value = value.replace("\\n", "\n")
        value = value.replace("\\t", "\t")
        value = value.replace("&amp;", "&")
        value = value.replace("&lt;", "<")
        value = value.replace("&gt;", ">")
        value = value.replace("&quot;", '"')
        value = value.replace("&#39;", "'")
        # Android %1$s -> iOS %@
        value = re.sub(r"%(\d+)\$[sd]", r"%@", value)
        value = value.replace("%%", "%")
        entries[name] = value
    return entries


def escape_strings_value(value: str) -> str:
    """Escape a value for a single-line iOS Localizable.strings entry."""
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r\n", "\n")
        .replace("\r", "\n")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )


def to_strings_file(entries: dict[str, str]) -> str:
    lines = ['/* Generated from vendor/android-res — do not edit by hand. */', ""]
    for key in sorted(entries.keys()):
        val = escape_strings_value(entries[key])
        lines.append(f'"{key}" = "{val}";')
    lines.append("")
    return "\n".join(lines)


def swift_ident(key: str) -> str:
    parts = key.split("_")
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


def generate_l10n(vi: dict[str, str], en: dict[str, str]) -> str:
    keys = sorted(set(vi.keys()) | set(en.keys()))
    lines = [
        "import Foundation",
        "",
        "/// Type-safe localization mirroring Android `R.string.*`.",
        "enum L10n {",
        "    // Resolved via L10nBundle.swift + vi/en .lproj",
        "",
    ]
    for key in keys:
        ident = swift_ident(key)
        # detect format args
        sample = vi.get(key) or en.get(key) or ""
        arg_count = sample.count("%@")
        if arg_count == 0:
            lines.append(f"    static var {ident}: String {{ t(\"{key}\") }}")
        elif arg_count == 1:
            lines.append(f"    static func {ident}(_ a1: CVarArg) -> String {{")
            lines.append(f"        String(format: t(\"{key}\"), a1)")
            lines.append("    }")
        elif arg_count == 2:
            lines.append(f"    static func {ident}(_ a1: CVarArg, _ a2: CVarArg) -> String {{")
            lines.append(f"        String(format: t(\"{key}\"), a1, a2)")
            lines.append("    }")
        else:
            lines.append(f"    static var {ident}: String {{ t(\"{key}\") }}")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    vi_path = android_strings_vi()
    en_path = android_strings_en()
    if not vi_path:
        print(
            "Missing strings source. Run scripts/vendor_from_android.py or set FASH_ANDROID_ROOT.",
            file=sys.stderr,
        )
        return 1
    vi = parse_strings_xml(vi_path)
    en = parse_strings_xml(en_path) if en_path and en_path.exists() else vi
    OUT_VI.mkdir(parents=True, exist_ok=True)
    OUT_EN.mkdir(parents=True, exist_ok=True)
    OUT_L10N.mkdir(parents=True, exist_ok=True)
    (OUT_VI / "Localizable.strings").write_bytes(to_strings_file(vi).encode("utf-8"))
    (OUT_EN / "Localizable.strings").write_bytes(to_strings_file(en).encode("utf-8"))
    (OUT_L10N / "L10n.swift").write_text(generate_l10n(vi, en), encoding="utf-8")
    print(f"vi: {len(vi)} keys, en: {len(en)} keys -> {OUT_VI}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
