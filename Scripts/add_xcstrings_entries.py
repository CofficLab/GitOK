#!/usr/bin/env python3
"""向 xcstrings catalog 补齐缺失的本地化条目。

用法：
    python3 Scripts/add_xcstrings_entries.py <条目定义 JSON>

条目定义格式：
```json
{
  "PluginGitDiff": {
    "Open": {
      "en": "Open",
      "zh-Hans": "打开",
      "zh-Hant": "打開",
      "zh-TW": "打開",
      "zh-HK": "打開"
    }
  }
}
```
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKAGES = os.path.join(ROOT, "Packages")
LANGUAGES = ["en", "zh-Hans", "zh-Hant", "zh-TW", "zh-HK"]


def catalog_path(package):
    return os.path.join(PACKAGES, package, "Resources", "Localizable.xcstrings")


def add_entries(package, entries):
    path = catalog_path(package)
    if not os.path.exists(path):
        raise SystemExit(f"{package}: 找不到 catalog {path}")

    with open(path, encoding="utf-8") as handle:
        catalog = json.load(handle)

    strings = catalog.setdefault("strings", {})
    added = []

    for key, translations in entries.items():
        if key in strings and strings[key].get("localizations"):
            existing = set(strings[key]["localizations"].keys())
            missing = [lang for lang in LANGUAGES if lang not in existing]
            if not missing:
                continue

        localizations = {}
        for language in LANGUAGES:
            value = translations.get(language)
            if value is None:
                # 未单独给出的语言沿用英文值。
                value = translations.get("en")
            if value is None:
                continue
            localizations[language] = {
                "stringUnit": {"state": "translated", "value": value}
            }

        strings[key] = {"localizations": localizations}
        added.append(key)

    catalog["version"] = "1.0"
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(catalog, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    return added


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)

    with open(sys.argv[1], encoding="utf-8") as handle:
        definition = json.load(handle)

    for package, entries in definition.items():
        added = add_entries(package, entries)
        if added:
            print(f"{package}: 新增 {len(added)} 条")
            for key in added:
                print(f"    + {key}")
        else:
            print(f"{package}: 无变化")


if __name__ == "__main__":
    main()
