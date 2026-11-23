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
    # lumi-softworks
    "https://github.com/lumi-softworks/LumiFactory.git": "1.7.3",
    "https://github.com/lumi-softworks/LumiKernel.git": "1.1.2",
    "https://github.com/lumi-softworks/LumiKitAgentTool.git": "1.0.5",
    "https://github.com/lumi-softworks/LumiKitKeychain.git": "1.0.1",
    "https://github.com/lumi-softworks/LumiKitLLM.git": "1.1.1",
    "https://github.com/lumi-softworks/LumiKitTestSupport.git": "1.0.1",
    "https://github.com/lumi-softworks/LumiLocalization.git": "1.0.3",
    "https://github.com/lumi-softworks/LumiLogging.git": "1.0.3",
    "https://github.com/lumi-softworks/LumiPluginAbout.git": "3.1.0",
    "https://github.com/lumi-softworks/LumiPluginCommand.git": "1.0.3",
    "https://github.com/lumi-softworks/LumiPluginLogos.git": "1.0.2",
    "https://github.com/lumi-softworks/LumiPluginPluginManager.git": "1.8.0",
    "https://github.com/lumi-softworks/LumiPluginRootView.git": "1.3.3",
    "https://github.com/lumi-softworks/LumiPluginSettingView.git": "1.0.5",
    "https://github.com/lumi-softworks/LumiPluginStorage.git": "1.2.3",
    "https://github.com/lumi-softworks/LumiPluginThemePack.git": "1.2.3",
    "https://github.com/lumi-softworks/LumiPluginToast.git": "1.2.5",
    "https://github.com/lumi-softworks/LumiProviders.git": "1.27.0",
    "https://github.com/lumi-softworks/LumiSettings.git": "1.1.2",
    "https://github.com/lumi-softworks/LumiThemePack.git": "1.1.0",
    "https://github.com/lumi-softworks/LumiUI.git": "1.19.3",
    # nookery
    "https://github.com/nookery/LibGit2Swift.git": "1.1.1",
    "https://github.com/nookery/MagicDiffView": None,  # branch-based, skip
    "https://github.com/nookery/MagicLog.git": "1.0.0",
    # third-party
    "https://github.com/gonzalezreal/swift-markdown-ui": "2.4.1",
    "https://github.com/gonzalezreal/NetworkImage": "6.0.1",
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
