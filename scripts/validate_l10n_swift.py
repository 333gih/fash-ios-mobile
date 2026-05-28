#!/usr/bin/env python3
"""Ensure L10n.swift API matches Swift call sites (func vs var, arity)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FASH = ROOT / "Fash"
L10N_API_FILES = (
    FASH / "Localization" / "L10n.swift",
    FASH / "Localization" / "L10nBundle.swift",
)

STATIC_VAR = re.compile(r"static var (\w+): String")
STATIC_FUNC = re.compile(r"static func (\w+)\(([^)]*)\)")
CALL = re.compile(r"L10n\.(\w+)\(")


def extract_call(text: str, start: int) -> tuple[str, str, int] | None:
    """From index at 'L10n.', return (name, args, end_index)."""
    m = re.match(r"L10n\.(\w+)\(", text[start:])
    if not m:
        return None
    name = m.group(1)
    i = start + m.end()
    depth = 1
    arg_start = i
    while i < len(text) and depth > 0:
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return name, text[arg_start:i], i + 1
        i += 1
    return None


def parse_l10n(path: Path) -> dict[str, int | None]:
    """Return symbol -> arg count (None for var)."""
    text = path.read_text(encoding="utf-8")
    out: dict[str, int | None] = {}
    for m in STATIC_VAR.finditer(text):
        out[m.group(1)] = None
    for m in STATIC_FUNC.finditer(text):
        params = m.group(2).strip()
        if not params:
            out[m.group(1)] = 0
        else:
            out[m.group(1)] = len([p for p in params.split(",") if p.strip()])
    return out


def count_call_args(arg_text: str) -> int:
    depth = 0
    count = 0
    chunk = ""
    for ch in arg_text:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth = max(0, depth - 1)
        elif ch == "," and depth == 0:
            if chunk.strip():
                count += 1
            chunk = ""
            continue
        chunk += ch
    if chunk.strip():
        count += 1
    return count


def load_l10n_api() -> dict[str, int | None]:
    api: dict[str, int | None] = {}
    for path in L10N_API_FILES:
        if not path.is_file():
            print(f"Missing {path}", file=sys.stderr)
            raise FileNotFoundError(path)
        for name, arity in parse_l10n(path).items():
            api[name] = arity
    return api


def main() -> int:
    try:
        api = load_l10n_api()
    except FileNotFoundError:
        return 1

    errors: list[str] = []
    skip_names = {p.name for p in L10N_API_FILES}

    for swift in sorted(FASH.rglob("*.swift")):
        if swift.name in skip_names:
            continue
        rel = swift.relative_to(ROOT)
        text = swift.read_text(encoding="utf-8")
        pos = 0
        while pos < len(text):
            idx = text.find("L10n.", pos)
            if idx < 0:
                break
            parsed = extract_call(text, idx)
            if not parsed:
                pos = idx + 5
                continue
            name, args, end = parsed
            line = text[:idx].count("\n") + 1
            arity = count_call_args(args.strip()) if args.strip() else 0
            pos = end
            if name not in api:
                errors.append(f"{rel}:{line}: L10n.{name}(...) — symbol missing from L10n API")
                continue
            expected = api[name]
            if expected is None:
                errors.append(
                    f"{rel}:{line}: L10n.{name}(...) called with {arity} arg(s) but L10n defines static var"
                )
            elif expected != arity:
                errors.append(
                    f"{rel}:{line}: L10n.{name}(...) arity {arity} != L10n func expecting {expected}"
                )

    if errors:
        print("L10n call-site validation failed:", file=sys.stderr)
        for err in errors[:40]:
            print(f"  {err}", file=sys.stderr)
        if len(errors) > 40:
            print(f"  ... and {len(errors) - 40} more", file=sys.stderr)
        return 1

    print(f"OK: L10n API matches call sites ({len(api)} symbols)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
