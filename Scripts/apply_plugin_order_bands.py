#!/usr/bin/env python3
"""Rewrite plugin metadata.order values into Lumi-style bands.

Bands: 0-99 core, 100-199 base services, 200-299 features, 300+ optional.
Only the `GitOKPluginMetadata(...)` call block of each plugin entry file is
modified; contribution item orders elsewhere in the file stay untouched.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# plugin dir -> new order (None = insert fresh, int = replace existing)
ORDERS = {
    "ProjectsPlugin": 10,
    "OnboardingPlugin": 20,
    "GitRepositorySettingsPlugin": 30,
    "GitUserSettingsPlugin": 40,
    "GitWatcherPlugin": 50,
    "GitCleanStatusPlugin": 60,
    "GitUnpushedStatusPlugin": 70,
    "ProjectPickerPlugin": 80,
    "GitCommitStyleSettingsPlugin": 100,
    "GitNetworkSettingsPlugin": 110,
    "DiagnosticsSettingsPlugin": 120,
    "AppearanceSettingsPlugin": 130,
    "AboutSettingsPlugin": 140,
    "SettingsButtonPlugin": 150,
    "ActivityStatusPlugin": 160,
    "GitWorkingStatePlugin": 200,
    "GitCommitListPlugin": 210,
    "GitDetailPlugin": 220,
    "GitBranchPlugin": 230,
    "GitStashPlugin": 240,
    "GitSubmodulePlugin": 250,
    "GitConflictResolverPlugin": 260,
    "GitSmartMergePlugin": 270,
    "GitRemoteRepositoryPlugin": 280,
    "GitLFSPlugin": 285,
    "GitIgnorePlugin": 290,
    "ReadmePlugin": 295,
    "FileInfoPlugin": 300,
    "LicensePlugin": 310,
    "ThemeStatusBarPlugin": 320,
    "ThemeGitOKPlugin": 330,
    "ThemeSpringPlugin": 331,
    "ThemeAuroraPlugin": 332,
    "ThemeMidnightPlugin": 333,
    "ThemeEmberPlugin": 334,
    "ThemeRiverPlugin": 335,
    "ThemeNebulaPlugin": 336,
    "ThemeHarborPlugin": 337,
    "ThemeOrchardPlugin": 338,
    "ThemeGlacierPlugin": 339,
    "ThemeSummerPlugin": 340,
    "ThemeMatrixPlugin": 341,
    "ThemeMountainPlugin": 342,
    "ThemeWinterPlugin": 343,
    "ThemeGraphitePlugin": 344,
    "ThemeDraculaPlugin": 345,
    "ThemeOneDarkPlugin": 346,
    "ThemeXcodeLightPlugin": 347,
    "ThemeGitHubLightPlugin": 348,
    "OpenFinderPlugin": 400,
    "OpenTerminalPlugin": 410,
    "OpenLumiPlugin": 420,
    "OpenVSCodePlugin": 430,
    "OpenCursorPlugin": 440,
    "OpenXcodePlugin": 450,
    "OpenGitHubDesktopPlugin": 460,
    "OpenTraePlugin": 470,
    "OpenKiroPlugin": 480,
    "OpenAntigravityPlugin": 490,
    "OpenRemotePlugin": 500,
}


def find_entry_file(plugin: str) -> Path | None:
    sources = ROOT / "Plugins" / plugin / "Sources"
    if not sources.is_dir():
        return None
    candidates = [p for p in sources.rglob("*.swift") if "GitOKPluginMetadata(" in p.read_text()]
    return candidates[0] if candidates else None


def rewrite(path: Path, new_order: int) -> bool:
    text = path.read_text()
    start = text.find("GitOKPluginMetadata(")
    if start == -1:
        return False
    # find matching closing paren of the metadata call
    depth = 0
    i = text.find("(", start)
    end = -1
    for j in range(i, len(text)):
        if text[j] == "(":
            depth += 1
        elif text[j] == ")":
            depth -= 1
            if depth == 0:
                end = j
                break
    if end == -1:
        return False
    block = text[i:end]

    if re.search(r"\border:\s*\d+\s*,", block):
        new_block = re.sub(r"\border:\s*\d+\s*,", f"order: {new_order},", block, count=1)
    else:
        # insert after the iconName argument line
        m = re.search(r"iconName:\s*\"[^\"]*\"\s*,", block)
        if not m:
            return False
        new_block = block[: m.end()] + f"\n        order: {new_order}," + block[m.end() :]

    text = text[:i] + new_block + text[end:]
    path.write_text(text)
    return True


def main() -> int:
    failed = []
    for plugin, order in ORDERS.items():
        path = find_entry_file(plugin)
        if path is None:
            failed.append(f"{plugin}: entry file not found")
            continue
        if not rewrite(path, order):
            failed.append(f"{plugin}: rewrite failed")
    for line in failed:
        print(f"FAIL {line}", file=sys.stderr)
    print(f"updated {len(ORDERS) - len(failed)}/{len(ORDERS)} plugins")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
