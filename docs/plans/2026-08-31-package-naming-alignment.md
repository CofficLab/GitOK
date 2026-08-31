# Package Naming Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make GitOK package directories and SwiftPM package/product names follow Lumi's category-first naming convention.

**Architecture:** Plugin packages will use `Plugin<Feature>` names while preserving existing target/module and plugin type names where Lumi does so. Core libraries will use category-first names such as `KitGitCore`; all package paths, manifests, imports, generated registries, Xcode references, and validation rules will be updated together.

**Tech Stack:** Swift 6, Swift Package Manager, Xcode project files, shell boundary checks.

---

### Task 1: Define the package rename map

Record the exact old-to-new mapping for every active plugin package and the core kit package that violates Lumi's convention. Treat legacy non-package directories as out of scope unless they are referenced by SwiftPM or Xcode.

### Task 2: Rename plugin package directories and manifests

Rename `Plugins/*Plugin` directories to `Plugins/Plugin*`, then update each manifest's package and product name. Preserve target/module names so source imports and plugin type names remain stable, matching Lumi's `PluginGit` package / `GitPlugin` target pattern.

### Task 3: Update registry and package references

Update `FactoryGitOK/Package.swift`, generated registry imports, package paths, and any scripts/docs that refer to old plugin package paths.

### Task 4: Align core kit naming

Rename `KitGitCore` to `KitGitCore`, update its manifest and all source/test imports and package dependencies. Keep GitOK-specific packages unchanged unless a direct Lumi category mapping exists.

### Task 5: Add naming validation and verify

Extend the package-boundary script to reject active plugin package directories and package declarations that do not begin with `Plugin`. Run all affected package tests, boundary checks, and the Xcode build.
