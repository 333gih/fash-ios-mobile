#!/usr/bin/env python3
"""
Generate Swift UI/Data scaffolds from fash-android-mobile Kotlin sources.
Creates matching file names under Fash/ — full Compose→SwiftUI port is done incrementally;
scaffolds ensure the Xcode target compiles and every Android module has an iOS counterpart.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID_JAVA = ROOT.parent / "fash-android-mobile/app/src/main/java/com/pc/fash_android_mobile"
FASH = ROOT / "Fash"

SKIP = {"MainActivity.kt", "FashApplication.kt"}


def kotlin_to_swift_path(kt: Path) -> Path:
    rel = kt.relative_to(ANDROID_JAVA)
    name = kt.stem
    if name.endswith("ViewModel"):
        swift_name = name + ".swift"
    elif "Screen" in name or name.endswith("Sheet") or name.endswith("Overlay") or name.endswith("Host"):
        swift_name = name + ".swift"
    elif name.endswith("Repository") or name.endswith("Store") or name.endswith("Manager"):
        swift_name = name + ".swift"
    else:
        swift_name = name + ".swift"
    return FASH / str(rel.parent).replace("\\", "/") / swift_name


def is_screen(name: str) -> bool:
    return (
        "Screen" in name
        or name.endswith("Sheet")
        or name.endswith("Overlay")
        or name.endswith("Host")
        or name.endswith("Content")
        and "Feed" in name
    )


def is_viewmodel(name: str) -> bool:
    return name.endswith("ViewModel")


def screen_template(name: str, pkg: str) -> str:
    return f"""import SwiftUI

/// SwiftUI port of Android `{name}` ({pkg}).
struct {name}: View {{
    @Environment(\\.dismiss) private var dismiss

    var body: some View {{
        {name}Body()
    }}
}}

private struct {name}Body: View {{
    var body: some View {{
        FashScreenScaffold(title: "{name}") {{
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }}
    }}
}}

#Preview {{
    FashTheme {{ {name}() }}
}}
"""


def viewmodel_template(name: str, pkg: str) -> str:
    return f"""import Foundation
import Observation

/// Observable port of Android `{name}` ({pkg}).
@Observable
@MainActor
final class {name} {{
    var isLoading = false
    var errorMessage: String?

    func refresh() async {{
        isLoading = true
        defer {{ isLoading = false }}
        // Port logic from Android {name}.kt
    }}
}}
"""


def data_template(name: str, pkg: str) -> str:
    return f"""import Foundation

/// Port of Android `{name}` ({pkg}).
final class {name} {{
    private let deps: AppDependencies

    init(deps: AppDependencies) {{
        self.deps = deps
    }}
}}
"""


def other_template(name: str, pkg: str) -> str:
    return f"""import Foundation

/// Port of Android `{name}` ({pkg}).
enum {name} {{
}}
"""


def generate_file(kt: Path) -> None:
    if kt.name in SKIP:
        return
    out = kotlin_to_swift_path(kt)
    if out.exists():
        return
    name = kt.stem
    pkg = str(kt.parent.relative_to(ANDROID_JAVA)).replace("\\", ".")
    if is_viewmodel(name):
        content = viewmodel_template(name, pkg)
    elif is_screen(name) or (name.endswith("Content") and "Home" in name):
        content = screen_template(name, pkg)
    elif "Repository" in name or "Store" in name or "Manager" in name or "Coordinator" in name:
        content = data_template(name, pkg)
    else:
        content = other_template(name, pkg)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


def main() -> None:
    count = 0
    for kt in sorted(ANDROID_JAVA.rglob("*.kt")):
        generate_file(kt)
        count += 1
    print(f"Processed {count} Kotlin files under {ANDROID_JAVA}")


if __name__ == "__main__":
    main()
