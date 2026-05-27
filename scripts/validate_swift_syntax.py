#!/usr/bin/env python3
"""Static checks for common Swift compile failures (Swift 5.9 / Xcode 16.2)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FASH = ROOT / "Fash"

TRAILING_COMMA = re.compile(r",\s*\n\s*\)", re.MULTILINE)
TYPOGRAPHY_USE = re.compile(r"FashTypography\.(\w+)")
COLOR_USE = re.compile(r"FashColors\.(\w+)\b")
STATIC_LET = re.compile(r"static (?:var|let) (\w+)")
GUARD_MISSING_ELSE = re.compile(
    r"^\s*guard\b(?:(?!.*\belse\b).)*\{",
    re.MULTILINE,
)
FUNC_DECL = re.compile(
    r"^\s+(?:@\w+(?:\([^)]*\))?\s+)*(?:private |fileprivate |public |internal )?"
    r"func (\w+)\(([^)]*)\)",
    re.MULTILINE,
)
TYPE_DECL = re.compile(r"^(?:final\s+)?(?:class|struct|enum|actor)\s+(\w+)", re.MULTILINE)


def tokens_from_enum(path: Path) -> set[str]:
    if not path.is_file():
        return set()
    return set(STATIC_LET.findall(path.read_text(encoding="utf-8")))


def load_valid_typography() -> set[str]:
    return tokens_from_enum(FASH / "ui" / "theme" / "FashTypography.swift")


def load_valid_colors() -> set[str]:
    return tokens_from_enum(FASH / "ui" / "theme" / "Color.swift")


def check_file(
    path: Path,
    *,
    valid_typography: set[str],
    valid_colors: set[str],
) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")

    for m in GUARD_MISSING_ELSE.finditer(text):
        line = text[: m.start()].count("\n") + 1
        errors.append(
            f"{path.relative_to(ROOT)}:{line}: guard is missing 'else' before '{{'"
        )

    for m in TRAILING_COMMA.finditer(text):
        line = text[: m.start()].count("\n") + 1
        errors.append(f"{path.relative_to(ROOT)}:{line}: trailing comma before ')' (Swift 5.9)")

    for m in TYPOGRAPHY_USE.finditer(text):
        token = m.group(1)
        if token not in valid_typography:
            line = text[: m.start()].count("\n") + 1
            errors.append(f"{path.relative_to(ROOT)}:{line}: invalid FashTypography token '{token}'")

    for m in COLOR_USE.finditer(text):
        token = m.group(1)
        if token not in valid_colors:
            line = text[: m.start()].count("\n") + 1
            errors.append(f"{path.relative_to(ROOT)}:{line}: invalid FashColors token '{token}'")

    opens = text.count("{")
    closes = text.count("}")
    if opens != closes:
        errors.append(
            f"{path.relative_to(ROOT)}: unbalanced braces ({opens} '{{' vs {closes} '}}')"
        )

    scope = "file"
    depth = 0
    sigs: dict[str, int] = {}
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.endswith("{"):
            depth += 1
            m = TYPE_DECL.match(line)
            if m and depth == 1:
                scope = m.group(1)
                sigs = {}
        if stripped == "}":
            depth = max(0, depth - 1)
            if depth == 0:
                scope = "file"
                sigs = {}
        m = FUNC_DECL.match(line)
        if m and depth >= 1:
            name, params = m.group(1), re.sub(r"\s+", "", m.group(2).split("->")[0])
            key = f"{scope}::{name}({params})"
            sigs[key] = sigs.get(key, 0) + 1
            if sigs[key] > 1:
                line_no = text[: text.find(line)].count("\n") + 1
                errors.append(
                    f"{path.relative_to(ROOT)}:{line_no}: duplicate func {name} in {scope}"
                )

    return errors


def main() -> int:
    valid_typography = load_valid_typography()
    valid_colors = load_valid_colors()
    all_errors: list[str] = []
    for path in sorted(FASH.rglob("*.swift")):
        all_errors.extend(
            check_file(
                path,
                valid_typography=valid_typography,
                valid_colors=valid_colors,
            )
        )

    if all_errors:
        print("Swift validation failed:\n", file=sys.stderr)
        for err in all_errors:
            print(f"  {err}", file=sys.stderr)
        return 1

    print(f"OK: {len(list(FASH.rglob('*.swift')))} Swift files passed static checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
