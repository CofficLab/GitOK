#!/usr/bin/env python3
"""统一跨包 catalog 的同 key 译法。

同一术语在不同插件的 catalog 中出现不同译法，会让用户在切换界面时
看到前后不一致的措辞。本脚本按「多数派 + 术语合理性」规则统一。

用法：
    python3 Scripts/unify_xcstrings_translations.py <统一规则 JSON>

规则格式：
```json
{
  "Destination": {
    "zh-Hans": "目标位置",
    "zh-Hant": "目標位置"
  }
}
```
规则中未列出的 key 保持原样。
"""
import json
import os
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKAGES = os.path.join(ROOT, "Packages")
LANGS = ["en", "zh-Hans", "zh-Hant", "zh-TW", "zh-HK"]


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def write(path, content):
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)


def all_catalogs():
    for root, dirs, files in os.walk(PACKAGES):
        dirs[:] = [d for d in dirs if d != ".build"]
        for name in files:
            if name == "Localizable.xcstrings":
                yield os.path.join(root, name)


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)

    with open(sys.argv[1], encoding="utf-8") as handle:
        rules = json.load(handle)

    changed_files = 0
    changed_entries = 0

    for path in all_catalogs():
        catalog = json.loads(read(path))
        strings = catalog.get("strings", {})
        dirty = False

        for key, values in rules.items():
            entry = strings.get(key)
            if not entry:
                continue
            localizations = entry.get("localizations", {})
            for language in LANGS:
                target = values.get(language)
                if target is None:
                    continue
                unit = localizations.get(language, {}).get("stringUnit")
                if unit is None:
                    continue
                if unit.get("value") != target:
                    unit["value"] = target
                    unit["state"] = "translated"
                    dirty = True
                    changed_entries += 1

        if dirty:
            write(path, json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
            changed_files += 1

    print(f"统一了 {changed_entries} 条译法，涉及 {changed_files} 个 catalog")


if __name__ == "__main__":
    main()
