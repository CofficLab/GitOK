#!/usr/bin/env python3
"""Generate a Localizable.xcstrings catalog for a SwiftPM package.

Usage:
    python3 gen_xcstrings.py <output_path> '<json_translations>'

`json_translations` maps each key to {en, zh-Hans, zh-Hant, zh-HK, zh-TW}.
Format mirrors the PluginWorktreeClean template (sourceLanguage en).
"""
import json
import sys


def build(translations: dict[str, dict[str, str]]) -> dict:
    langs = ["en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"]
    strings = {}
    for key, values in translations.items():
        localizations = {}
        for lang in langs:
            value = values.get(lang)
            if value is None:
                # fall back: zh-HK/zh-TW inherit zh-Hant; missing en keeps key
                if lang in ("zh-HK", "zh-TW"):
                    value = values.get("zh-Hant")
                if value is None:
                    value = key if lang == "en" else values.get("en", key)
            localizations[lang] = {
                "stringUnit": {"state": "translated", "value": value}
            }
        strings[key] = {"localizations": localizations}
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


def main() -> None:
    out_path, raw = sys.argv[1], sys.argv[2]
    translations = json.loads(raw)
    catalog = build(translations)
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(catalog, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


if __name__ == "__main__":
    main()
