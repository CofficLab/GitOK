#!/usr/bin/env python3
"""Bump remote SPM dependency version constraints to the latest published tags.

Usage: bump_package_deps.py <root> [<root> ...]

Each entry maps a repository URL to the new `from:` version. Only constraints
that use `from:` are rewritten; branch/revision/exact pins are left untouched.
"""
import re
import sys
from pathlib import Path

BUMPS = {
    "https://github.com/CofficLab/LumiProviders.git": "1.13.0",
    "https://github.com/CofficLab/LumiUI.git": "1.11.1",
    "https://github.com/CofficLab/LumiSettings.git": "1.1.0",
    "https://github.com/CofficLab/LumiPluginSettingView.git": "1.0.3",
    "https://github.com/sparkle-project/Sparkle": "2.10.1",
}

PKG_RE = re.compile(
    r'(\.package\(url:\s*"(?P<url>[^"]+)"\s*,\s*from:\s*")(?P<ver>[^"]+)(?P<tail>")'
)


def bump(text: str) -> str:
    def repl(m: re.Match) -> str:
        url = m.group("url")
        new = BUMPS.get(url) or BUMPS.get(url.rstrip("/") + ".git")
        if new is None or new == m.group("ver"):
            return m.group(0)
        return m.group(1) + new + m.group("tail")

    return PKG_RE.sub(repl, text)


def main(roots: list[str]) -> None:
    changed = []
    for root in roots:
        for manifest in sorted(Path(root).glob("Packages/*/Package.swift")):
            original = manifest.read_text(encoding="utf-8")
            updated = bump(original)
            if updated != original:
                manifest.write_text(updated, encoding="utf-8")
                changed.append(str(manifest))
    print(f"changed {len(changed)} manifests")
    for c in changed:
        print("  ", c)


if __name__ == "__main__":
    main(sys.argv[1:] or ["."])
