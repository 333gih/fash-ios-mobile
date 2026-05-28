#!/usr/bin/env python3
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
pat = re.compile(r'"([^"]+)"\s*=\s*"(.*)";\s*$')

def parse(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        m = pat.match(line.strip())
        if m:
            out[m.group(1)] = m.group(2)
    return out

vi = parse(ROOT / "Fash/Resources/vi.lproj/Localizable.strings")
en = parse(ROOT / "Fash/Resources/en.lproj/Localizable.strings")
missing = sorted(set(vi) - set(en))
out_path = ROOT / "scripts" / "missing_en_keys.txt"
lines = [f"missing in en: {len(missing)}", ""]
for k in missing:
    lines.append(f"{k}\t{vi[k][:120]}")
out_path.write_text("\n".join(lines), encoding="utf-8")
print(f"Wrote {out_path} ({len(missing)} keys)")
