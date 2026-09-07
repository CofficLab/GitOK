# Merge Selection Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement the plan task-by-task.

**Goal:** Persist the last source and target branch selected in the Smart Merge form and restore them per repository.

**Architecture:** `GitSmartMergePlugin` resolves `StorageProviding` during boot and injects the plugin data directory into the merge views. A small `MergeSelectionStore` owns JSON persistence and keys selections by the repository’s standardized path. `MergeForm` restores only branch names that still exist among current local branches, then saves subsequent complete selections; the merge operation itself remains unchanged.

**Tech Stack:** Swift 6, SwiftUI, Swift Package Manager, `StorageProviding`, JSONEncoder/JSONDecoder, Swift Testing.

---

### Task 1: Add the merge selection store

**Files:**
- Create: `Packages/PluginGitSmartMerge/Sources/PluginGitSmartMerge/Support/MergeSelectionStore.swift`
- Create: `Packages/PluginGitSmartMerge/Tests/PluginGitSmartMergeTests/MergeSelectionStoreTests.swift`

**Steps:**

1. Write tests for saving/loading a source-target pair, isolation between two repository paths, and malformed/missing files falling back to no saved selection.
2. Run `swift test --package-path Packages/PluginGitSmartMerge --filter MergeSelectionStoreTests` and confirm it fails because the store does not exist.
3. Implement a Codable `MergeSelection` value and a store backed by `<pluginDataDirectory>/merge-selection.json`. Use a standardized repository path as the dictionary key, atomic writes, and fail-soft reads/writes so a broken preference file never blocks merging.
4. Run the focused store tests and confirm they pass.

### Task 2: Inject plugin storage using the Lumi boundary

**Files:**
- Modify: `Packages/PluginGitSmartMerge/Package.swift`
- Modify: `Packages/PluginGitSmartMerge/Sources/PluginGitSmartMerge/GitSmartMergePlugin.swift`
- Modify: `Packages/PluginGitSmartMerge/Sources/PluginGitSmartMerge/Views/MergeStatusTile.swift`

**Steps:**

1. Add the `ProviderStorage` package dependency and product dependency.
2. During `onBoot`, resolve `StorageProviding` and obtain `pluginDataDirectory(for: id)`. Keep the existing merge status item available if storage is unavailable by allowing the view to use its fallback store location.
3. Thread the optional storage directory through `MergeStatusTile` into `MergeForm` without changing the existing public two-argument initializers’ behavior.

### Task 3: Restore and save valid branch selections

**Files:**
- Modify: `Packages/PluginGitSmartMerge/Sources/PluginGitSmartMerge/Views/MergeStatusTile.swift`

**Steps:**

1. Add a store and restoration-ready state to `MergeForm`.
2. On branch load, read the saved selection for the current repository, filter the branch list to local branches as before, and restore saved source/target names only when they are present. Preserve the current default source/target fallback.
3. Persist a complete pair when either picker changes after restoration. Save the pair again before a merge so the latest choice survives closing the popover or a failed merge.
4. Add a load token and project URL guard so a late branch-list result cannot overwrite selections after switching repositories.
5. Reload selections when the current project changes while the popover remains mounted.

### Task 4: Verify integration

**Files:**
- Test/inspect: `Packages/PluginGitSmartMerge/Tests/PluginGitSmartMergeTests/PluginGitSmartMergeTests.swift`
- Build/inspect: `Packages/PluginGitSmartMerge/Package.swift`

**Steps:**

1. Run all Smart Merge tests.
2. Build the Smart Merge package and the GitOK Xcode Debug scheme.
3. Run `git diff --check` and confirm the persistence file is scoped to the plugin data directory, branch values are validated against current local branches, and no merge command behavior changed.
