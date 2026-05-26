#!/usr/bin/env python3
"""Static checks for common Swift compile failures (Swift 5.9 / Xcode 16.2)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FASH = ROOT / "Fash"

TRAILING_COMMA = re.compile(r",\s*\n\s*\)", re.MULTILINE)
INVALID_TYPOGRAPHY = re.compile(
    r"FashTypography\.(?:titleSmall|bodySmall|labelSmall|headlineSmall|displaySmall)"
)
INVALID_COLORS = re.compile(
    r"FashColors\.(?:primary|onPrimary|secondary|background|surface|surfaceContainerLow)\b"
)


def check_file(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")

    for m in TRAILING_COMMA.finditer(text):
        line = text[: m.start()].count("\n") + 1
        errors.append(f"{path.relative_to(ROOT)}:{line}: trailing comma before ')' (Swift 5.9)")

    for m in INVALID_TYPOGRAPHY.finditer(text):
        line = text[: m.start()].count("\n") + 1
        errors.append(f"{path.relative_to(ROOT)}:{line}: invalid FashTypography token")

    for m in INVALID_COLORS.finditer(text):
        line = text[: m.start()].count("\n") + 1
        errors.append(f"{path.relative_to(ROOT)}:{line}: invalid FashColors token")

    # Rough brace balance for init blocks (catches common SecuredApiClient-style typos)
    opens = text.count("{")
    closes = text.count("}")
    if opens != closes:
        errors.append(
            f"{path.relative_to(ROOT)}: unbalanced braces ({opens} '{{' vs {closes} '}}')"
        )

    return errors


def main() -> int:
    all_errors: list[str] = []
    for path in sorted(FASH.rglob("*.swift")):
        all_errors.extend(check_file(path))

    if all_errors:
        print("Swift validation failed:\n", file=sys.stderr)
        for err in all_errors:
            print(f"  {err}", file=sys.stderr)
        return 1

    print(f"OK: {len(list(FASH.rglob('*.swift')))} Swift files passed static checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
