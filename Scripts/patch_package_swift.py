#!/usr/bin/env python3
"""Add ProviderDocsView + LumiUI deps and Resources to plugin Package.swift files.

Usage: patch_package_swift.py <package_dir> [<package_dir> ...]

Edits are conservative: each change is applied only when the target text is
missing, and the file is re-parsed after patching.
"""
import re
import sys

LUMIUI_PKG = '.package(url: "https://github.com/CofficLab/LumiUI.git", from: "1.2.1"),'
DOCS_PKG = '.package(path: "../ProviderDocsView"),'
DOCS_PROD = '.product(name: "ProviderDocsView", package: "ProviderDocsView"),'
LUMIUI_PROD = '.product(name: "LumiUI", package: "LumiUI"),'
RES_LINE = '.process("../../Resources/Localizable.xcstrings")'


def find_block(text: str, open_paren: str, start: int) -> tuple[int, int]:
    """Return (open_idx, close_idx) of the first balanced (...) starting at/after start."""
    depth = 0
    i = text.find(open_paren, start)
    if i == -1:
        return -1, -1
    depth = 1
    j = i + len(open_paren)
    while j < len(text) and depth > 0:
        c = text[j]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        j += 1
    return i, j - 1


def insert_before(text: str, pos: int, chunk: str) -> str:
    return text[:pos] + chunk + text[pos:]


def insert_into_array(text: str, arr_start: int, arr_end: int, line: str, indent: str) -> str:
    """Insert `line` into the array body [arr_start, arr_end) right before the closing `]`."""
    # arr_end points at ']'; insert before it with a newline
    return text[:arr_end] + indent + line + "\n" + text[arr_end:]


def patch(path: str) -> bool:
    with open(path, encoding="utf-8") as f:
        text = f.read()
    original = text

    pkg_name = re.search(r'name:\s*"([^"]+)"', text).group(1)

    # ---- 1. defaultLocalization ----
    if "defaultLocalization:" not in text:
        text = re.sub(
            r'(let package = Package\(\n)(    name: "[^"]+",\n)',
            r"\1\2    defaultLocalization: \"en\",\n",
            text,
            count=1,
        )

    # ---- 2. package-level dependencies array ----
    pkg_open = text.find("let package = Package(")
    deps_open = text.find("dependencies: [", pkg_open)
    if deps_open != -1:
        close = text.find("]", deps_open)
        for line in (DOCS_PKG, LUMIUI_PKG):
            if line not in text:
                text = insert_into_array(text, deps_open, close, line, "        ")
                close += len(line) + 9  # shift close by inserted length + newline + indent

    # ---- 3. first .target block: product deps + resources ----
    t_open, t_close = find_block(text, ".target(", 0)
    if t_open != -1:
        body = text[t_open:t_close]
        tdeps_open = body.find("dependencies: [")
        if tdeps_open != -1:
            abs_tdeps = t_open + tdeps_open
            close = text.find("]", abs_tdeps)
            for line in (DOCS_PROD, LUMIUI_PROD):
                if line not in body:
                    text = insert_into_array(text, abs_tdeps, close, line, "                ")
                    close += len(line) + 17  # newline + indent
                    body = text[t_open:t_close]

        # resources: only if not present anywhere in the target block
        if RES_LINE not in text[t_open:t_close]:
            # place right before the closing ')' of the target block; a trailing
            # comma before ')' is always valid Swift, so no extra checks needed.
            indent = "            "
            chunk = (
                ",\n"
                + indent
                + "resources: [\n"
                + indent
                + "    "
                + RES_LINE
                + "\n"
                + indent
                + "]"
            )
            text = insert_before(text, t_close, chunk)
            t_close += len(chunk)

    if text != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        return True
    return False


if __name__ == "__main__":
    changed = []
    for d in sys.argv[1:]:
        p = d.rstrip("/") + "/Package.swift"
        try:
            if patch(p):
                changed.append(d)
        except Exception as e:  # noqa: BLE001
            print(f"FAILED {d}: {e}")
    print("changed:", ", ".join(changed) if changed else "(none)")
