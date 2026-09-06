#!/usr/bin/env python3
"""Merge per-package localization entries into Resources/Localizable.xcstrings.

Usage:
    python3 merge_xcstrings.py <package_dir> '<json>'
    json: {"key": {"en": "...", "zh-Hans": "...", "zh-Hant": "...", "zh-HK": "...", "zh-TW": "..."}, ...}
    If a language value is omitted, it falls back to "en".
"""
import json
import os
import sys


def main() -> None:
    if len(sys.argv) != 3:
        print("usage: merge_xcstrings.py <package_dir> <json>")
        sys.exit(2)
    pkg_dir = sys.argv[1]
    entries = json.loads(sys.argv[2])

    resources_dir = os.path.join(pkg_dir, "Resources")
    os.makedirs(resources_dir, exist_ok=True)
    path = os.path.join(resources_dir, "Localizable.xcstrings")

    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            catalog = json.load(f)
    else:
        catalog = {"sourceLanguage": "en", "strings": {}, "version": "1.0"}

    strings = catalog.setdefault("strings", {})

    for key, langs in entries.items():
        entry = strings.get(key)
        if entry is None:
            entry = {"localizations": {}}
            strings[key] = entry
        localizations = entry.setdefault("localizations", {})
        en = langs.get("en") or key
        for lang in ("en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"):
            value = langs.get(lang) or en
            localizations[lang] = {
                "stringUnit": {"state": "translated", "value": value}
            }

    # Keep stable ordering: sourceLanguage, strings (sorted by key), version
    catalog["sourceLanguage"] = "en"
    sorted_strings = dict(sorted(strings.items(), key=lambda kv: kv[0]))
    catalog["strings"] = sorted_strings
    catalog["version"] = "1.0"

    with open(path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"merged {len(entries)} keys -> {path}")


if __name__ == "__main__":
    main()
