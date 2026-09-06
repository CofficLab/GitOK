#!/usr/bin/env python3
"""Insert onRegister/onUnregister (docs.addAbout) + ProviderDocsView import
into plugin class files.

Usage: register_about.py <package_dir>:<ViewName> [<package_dir>:<ViewName> ...]
"""
import re
import sys

TEMPLATE = """    public func onRegister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.addAbout(
            DocsEntry(id: id, name: metadata.name) { {VIEW}() }
        )
    }

    public func onUnregister(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any DocsViewProviding).self)?.removeEntries(id: id)
    }

"""


def find_class_file(pkg: str) -> str | None:
    import glob
    import os
    name = os.path.basename(pkg.rstrip("/"))
    cands = glob.glob(f"{pkg}/Sources/{name}/*.swift")
    for c in cands:
        with open(c, encoding="utf-8") as f:
            t = f.read()
        if "SuperPlugin" in t and "func onBoot" in t:
            return c
    return None


def insert_before_anchor(text: str, anchor: str, chunk: str) -> str:
    idx = text.find(anchor)
    if idx == -1:
        return text
    return text[:idx] + chunk + text[idx:]


def patch(pkg: str, view: str) -> bool:
    f = find_class_file(pkg)
    if f is None:
        print(f"SKIP {pkg}: no class file")
        return False
    with open(f, encoding="utf-8") as fh:
        text = fh.read()
    orig = text

    if "import ProviderDocsView" not in text:
        # insert after the last import line
        imports = [m for m in re.finditer(r"^import [^\n]+$", text, re.M)]
        if imports:
            last = imports[-1]
            text = text[: last.end()] + "\nimport ProviderDocsView" + text[last.end():]

    if "func onRegister" not in text:
        chunk = TEMPLATE.replace("{VIEW}", view)
        text = insert_before_anchor(text, "public func onBoot", chunk)

    if text != orig:
        with open(f, "w", encoding="utf-8") as fh:
            fh.write(text)
        return True
    return False


if __name__ == "__main__":
    changed = []
    for arg in sys.argv[1:]:
        pkg, _, view = arg.partition(":")
        if patch(pkg, view):
            changed.append(pkg)
    print("changed:", ", ".join(changed) if changed else "(none)")
