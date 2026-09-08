# Commit Activity Heatmap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a reusable local-Git activity heatmap provider and render it in the top row of the working-tree-clean overview in PluginWorktreeClean.

**Architecture:** `ProviderActivityHeatmap` defines only the Sendable activity data, provider protocol, and observer contract. A separate `PluginActivityHeatmap` owns the concrete implementation: it reads commit history through `GitProviding`, aggregates author-date commits into daily counts, checks the worktree state, and persists per-repository snapshots under its own plugin data directory supplied by `StorageProviding`. `PluginWorktreeClean` owns the complete clean-worktree overview UI: it consumes the provider through a narrow capability and composes one overview with a top row containing the clean-state prompt and heatmap, followed by full-width repository, Git user, and preset sections. `PluginCommitDetail` remains responsible only for selected-commit and worktree-change details.

**Tech Stack:** Swift 6 package targets, SwiftUI, `GitProviding`, `StorageProviding`, JSON persistence, Swift Testing/XCTest.

---

### Task 1: Add the activity heatmap Provider package

**Files:**
- Create: `Packages/ProviderActivityHeatmap/Package.swift`
- Create: `Packages/ProviderActivityHeatmap/Sources/ProviderActivityHeatmap/ActivityHeatmapProviding.swift`
- Create: `Packages/ProviderActivityHeatmap/README.md`
- Create: `Packages/ProviderActivityHeatmap/Tests/ProviderActivityHeatmapTests/ProviderActivityHeatmapTests.swift`
- Modify: `Packages/PluginWorktreeClean/Package.swift`
- Modify: `Packages/FactoryGitOK/Package.swift`
- Modify: `Packages/ProviderContentView/Sources/ProviderContentView/ContentViewProviding.swift`
- Modify: `Packages/ProviderContentView/Sources/ProviderContentView/DefaultContentViewProviding.swift`

**Step 1: Write the failing provider contract test**

Test that a default provider can publish a repository snapshot, expose it through the protocol, notify observers, and cancel an observer without changing the data model.

**Step 2: Run the provider test to verify it fails**

Run: `swift test --package-path Packages/ProviderActivityHeatmap`

Expected: FAIL because the package and provider types do not exist.

**Step 3: Implement the minimal provider contract and in-memory default**

Define `ActivityHeatmapDay` (`date`, `commitCount`), `ActivityHeatmapSnapshot` (`repositoryPath`, `generatedAt`, `days`), `ActivityHeatmapProviding`, observer handle/event types, and `DefaultActivityHeatmapProvider` with replacement semantics and main-actor observation.

**Step 4: Run the provider tests**

Run: `swift test --package-path Packages/ProviderActivityHeatmap`

Expected: PASS.

**Step 5: Commit**

Run: `git add Packages/ProviderActivityHeatmap Packages/PluginWorktreeClean/Package.swift Packages/FactoryGitOK/Package.swift && git commit -m "feat: add activity heatmap provider contract"`

### Task 2: Implement the Activity Heatmap data plugin

**Files:**
- Create: `Packages/PluginActivityHeatmap/Package.swift`
- Create: `Packages/PluginActivityHeatmap/Sources/PluginActivityHeatmap/ActivityHeatmapPlugin.swift`
- Create: `Packages/PluginActivityHeatmap/Sources/PluginActivityHeatmap/LocalActivityHeatmapProvider.swift`
- Create: `Packages/PluginActivityHeatmap/Tests/PluginActivityHeatmapTests/LocalActivityHeatmapProviderTests.swift`

**Step 1: Write failing aggregation and cache tests**

Test that commits are grouped by the selected calendar day, that an empty history produces an empty snapshot, and that a newly created provider reloads a valid JSON cache from its injected directory.

**Step 2: Run the focused tests to verify they fail**

Run: `swift test --package-path Packages/PluginActivityHeatmap --filter LocalActivityHeatmapProviderTests`

Expected: FAIL because the data plugin implementation does not exist.

**Step 3: Implement the plugin-owned provider**

Inject `GitProviding`, `StorageProviding`, and a calendar/loader seam for tests. Load a bounded recent history for six months, aggregate commits by local calendar day, use a stable repository-keyed JSON file in `StorageProviding.pluginDataDirectory(for: PluginActivityHeatmap.id)`, and publish cached data before refreshing. Refresh on project/data changes and repository-watch changes; clear the published snapshot when the worktree is dirty. Register the concrete provider in the kernel from the data plugin.

**Step 4: Run focused tests**

Run: `swift test --package-path Packages/PluginActivityHeatmap --filter LocalActivityHeatmapProviderTests`

Expected: PASS.

**Step 5: Commit**

Run: `git add Packages/PluginActivityHeatmap && git commit -m "feat: cache local git activity heatmap"`

### Task 3: Add the Worktree Clean capability and heatmap view

**Files:**
- Create: `Packages/PluginWorktreeClean/Sources/PluginWorktreeClean/Capabilities/WorktreeCleanActivityHeatmapCapability.swift`
- Create: `Packages/PluginWorktreeClean/Sources/PluginWorktreeClean/Observers/WorktreeCleanActivityHeatmapObserver.swift`
- Create: `Packages/PluginWorktreeClean/Sources/PluginWorktreeClean/ViewModels/WorktreeCleanActivityHeatmapViewModel.swift`
- Create: `Packages/PluginWorktreeClean/Sources/PluginWorktreeClean/Views/WorktreeCleanActivityHeatmapView.swift`
- Create: `Packages/PluginWorktreeClean/Tests/PluginWorktreeCleanTests/WorktreeCleanActivityHeatmapViewModelTests.swift`
- Modify: `Packages/PluginWorktreeClean/Sources/PluginWorktreeClean/WorktreeCleanPlugin.swift`
- Modify: `Packages/PluginWorktreeClean/Resources/Localizable.xcstrings`

**Step 1: Write failing view-model/capability tests**

Test that provider snapshots are copied into published view-model state and that the heatmap maps zero, low, medium, and high counts to deterministic colors/levels.

**Step 2: Run focused tests to verify they fail**

Run: `swift test --package-path Packages/PluginWorktreeClean --filter WorktreeCleanActivityHeatmapViewModelTests`

Expected: FAIL because the capability/view-model types do not exist.

**Step 3: Implement the capability, model, and SwiftUI view**

Keep the view free of provider subscriptions. Render a compact five-column-week grid with weekday labels, a legend, tooltip/accessibility text for each day, and a graceful empty state. Limit the heatmap to the same clean-worktree mode as the left view.

**Step 4: Compose the top row and full-width information sections**

Have WorktreeClean resolve the provider registered by `PluginActivityHeatmap`, adapt it through its capability, and compose the heatmap beside only the clean-state prompt inside `WorktreeCleanView`. Keep repository information, Git user configuration, and presets below that top row at full width. Keep Commit Detail's existing commit/worktree content entry separate and preserve existing behavior in non-clean/selected-commit modes.

**Step 5: Run focused tests**

Run: `swift test --package-path Packages/PluginWorktreeClean --filter WorktreeCleanActivityHeatmapViewModelTests`

Expected: PASS.

**Step 6: Commit**

Run: `git add Packages/PluginWorktreeClean && git commit -m "feat: render commit activity heatmap beside clean state"`

### Task 4: Integrate package wiring and verify the application target

**Files:**
- Modify: `Packages/FactoryGitOK/Package.swift`
- Modify: `Packages/FactoryGitOK/Sources/FactoryGitOK/ProviderFactory.swift` (only if the provider must be registered centrally)
- Modify: `Packages/FactoryGitOK/Sources/FactoryGitOK/PluginFactory.swift` (only if plugin construction changes)

**Step 1: Run all affected package tests**

Run: `swift test --package-path Packages/ProviderActivityHeatmap`, `swift test --package-path Packages/PluginActivityHeatmap`, `swift test --package-path Packages/PluginWorktreeClean`, and `swift test --package-path Packages/PluginCommitDetail`

Expected: PASS.

**Step 2: Build the app package graph**

Run: `swift build --package-path Packages/FactoryGitOK`

Expected: PASS with the new provider package resolved through FactoryGitOK.

**Step 3: Inspect the final diff and working tree**

Run: `git diff --check` and `git status --short`

Expected: no whitespace errors and only the feature/plan files changed.

**Step 4: Commit integration changes**

Run: `git add Packages/FactoryGitOK && git commit -m "build: wire activity heatmap provider package"`
