#!/usr/bin/env python3
"""Extract L("...") keys from AboutView Swift files."""
import glob
import json
import re
import sys


def extract(path: str) -> list[str]:
    with open(path, encoding="utf-8") as f:
        text = f.read()
    keys = []
    # L("...") and L("...", arg)
    for m in re.finditer(r'L\("((?:[^"\\]|\\.)*)"', text):
        key = m.group(1).replace('\\"', '"').replace("\\\\", "\\")
        if key not in keys:
            keys.append(key)
    return keys


def main() -> None:
    out = {}
    for f in sorted(glob.glob("Packages/*/Sources/*/Views/*AboutView.swift")):
        keys = extract(f)
        if keys:
            out[f] = keys
    print(json.dumps(out, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
