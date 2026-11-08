#!/usr/bin/env python3
"""Validate GitOK localization catalogs and user-facing string usage.

Checked rules (see .agent/rules/plugin-i18n-rules.md):
1. Every Packages/<Package>/Resources/Localizable.xcstrings is valid JSON with
   sourceLanguage "en" and is not empty.
2. Every key is non-empty, is not marked extractionState "stale", and has a
   non-empty translation for all five supported languages.
3. Every key is referenced from Packages/<Package>/Sources or GitOKApp. Keys
   that are assembled at runtime (format strings without a literal call site)
   must contain "%" and carry a "Runtime-assembled" comment.
4. Plugin/app Swift sources must not pass bare string literals to SwiftUI
   text-taking initializers (Text, Label, Button, Toggle, TextField,
   SecureField); use the package localization shim or Text(verbatim:) for
   non-translatable glyphs/file names.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGUAGES = ("en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW")
FORMAT_COMMENT_MARKER = "Runtime-assembled"
BARE_UI_LITERAL = re.compile(
    r'\b(Text|Label|Button|Toggle|TextField|SecureField)\s*\(\s*"[^"\\]*"\s*\)'
)
SWIFT_SOURCES = [ROOT / "GitOKApp"] + sorted((ROOT / "Packages").glob("*/Sources"))

errors = []


def error(message):
    errors.append(message)


def package_name(catalog):
    return catalog.relative_to(ROOT / "Packages").parts[0]


def swift_blob(package):
    chunks = []
    for base in (ROOT / "Packages" / package / "Sources", ROOT / "GitOKApp"):
        if base.exists():
            for path in base.rglob("*.swift"):
                chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(chunks)


def check_catalog(path, catalog_count):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        error(f"{path}: invalid JSON: {exc}")
        return catalog_count, 0

    if data.get("sourceLanguage") != "en":
        error(f"{path}: sourceLanguage must be \"en\"")

    strings = data.get("strings") or {}
    if not strings:
        error(f"{path}: catalog is empty; remove the file and its .process resource")
        return catalog_count + 1, 0

    package = package_name(path)
    blob = swift_blob(package)

    for key, entry in strings.items():
        if not key:
            error(f"{path}: empty string key")
            continue
        if entry.get("extractionState") == "stale":
            error(f"{path}: key {key!r} is marked extractionState \"stale\"")
        localizations = entry.get("localizations") or {}
        for language in LANGUAGES:
            value = (
                localizations.get(language, {})
                .get("stringUnit", {})
                .get("value", "")
            )
            if not value:
                error(f"{path}: key {key!r} is missing a {language} translation")

        used = key in blob or key.replace('"', '\\"') in blob
        if used:
            continue
        comment = entry.get("comment") or ""
        if "%" in key and FORMAT_COMMENT_MARKER in comment:
            continue
        error(
            f"{path}: key {key!r} is not referenced by {package} sources or GitOKApp "
            "(add a \"Runtime-assembled\" comment if it is a format string built at runtime)"
        )

    return catalog_count + 1, len(strings)


def check_bare_literals():
    for base in SWIFT_SOURCES:
        if not base.exists():
            continue
        for path in base.rglob("*.swift"):
            for number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                code = line.split("//", 1)[0]
                match = BARE_UI_LITERAL.search(code)
                if match:
                    error(f"{path}:{number}: bare UI literal {match.group(0)!r}; use the localization shim")


def main():
    catalogs = sorted(
        set((ROOT / "Packages").glob("*/Resources/Localizable.xcstrings"))
        | set((ROOT / "Packages").glob("*/Sources/Localizable.xcstrings"))
    )
    catalog_count = 0
    key_count = 0
    for path in catalogs:
        catalog_count, keys = check_catalog(path, catalog_count)
        key_count += keys
    check_bare_literals()

    if errors:
        print(f"Localization check failed with {len(errors)} problem(s):\n")
        for message in errors:
            print(f"- {message}")
        return 1

    print(f"Localization check passed: {catalog_count} catalogs, {key_count} keys.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
