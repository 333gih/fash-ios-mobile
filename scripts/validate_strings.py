#!/usr/bin/env python3
"""Validate Localizable.strings files for Xcode compatibility."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / "Fash" / "Resources" / "vi.lproj" / "Localizable.strings",
    ROOT / "Fash" / "Resources" / "en.lproj" / "Localizable.strings",
]


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        errors.append("UTF-8 BOM present (remove for Xcode)")
    if b"\r\n" in data:
        errors.append("CRLF line endings (convert to LF)")

    text = data.decode("utf-8")
    for i, line in enumerate(text.splitlines(), 1):
        raw = line.rstrip("\r")
        s = raw.strip()
        if not s or s.startswith("/*") or s.startswith("*") or s == "*/":
            continue
        if not re.match(r'^"[^"\\]*(?:\\.[^"\\]*)*"\s*=\s*".*";\s*$', raw):
            errors.append(f"L{i}: invalid syntax: {raw[:100]!r}")
            continue
        # Unescaped literal newlines inside quoted value
        m = re.match(r'^"[^"]+"\s*=\s*"(.*)";\s*$', raw)
        if m and "\n" in m.group(1):
            errors.append(f"L{i}: literal newline in value")

    return errors


def main() -> int:
    failed = False
    for path in FILES:
        print(f"== {path.relative_to(ROOT)}")
        if not path.exists():
            print("  MISSING")
            failed = True
            continue
        errs = validate(path)
        if errs:
            failed = True
            for e in errs[:30]:
                print(f"  {e}")
            if len(errs) > 30:
                print(f"  ... and {len(errs) - 30} more")
        else:
            print("  OK")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
