# Commit Activity Heatmap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a reusable local-Git activity heatmap provider and render it beside the working-tree-clean view in Commit Detail.

**Architecture:** `ProviderActivityHeatmap` defines only the Sendable activity data, provider protocol, and observer contract. `PluginCommitDetail` owns the concrete implementation: it reads commit history through `GitProviding`, aggregates author-date commits into daily counts, and persists per-repository snapshots under its own plugin data directory supplied by `StorageProviding`. `ProviderContentView` gains an optional layout-group key so `PluginWorktreeClean` can contribute the left block and `PluginCommitDetail` can contribute the right block without importing each other's private views; the content provider renders entries in the same group horizontally.

**Tech Stack:** Swift 6 package targets, SwiftUI, `GitProviding`, `StorageProviding`, JSON persistence, Swift Testing/XCTest.

---

### Task 1: Add the activity heatmap Provider package

**Files:**
- Create: `Packages/ProviderActivityHeatmap/Package.swift`
- Create: `Packages/ProviderActivityHeatmap/Sources/ProviderActivityHeatmap/ActivityHeatmapProviding.swift`
- Create: `Packages/ProviderActivityHeatmap/README.md`
- Create: `Packages/ProviderActivityHeatmap/Tests/ProviderActivityHeatmapTests/ProviderActivityHeatmapTests.swift`
- Modify: `Packages/PluginCommitDetail/Package.swift`
- Modify: `Packages/FactoryGitOK/Package.swift`
- Modify: `Packages/ProviderContentView/Sources/ProviderContentView/ContentViewProviding.swift`
- Modify: `Packages/ProviderContentView/Sources/ProviderContentView/DefaultContentViewProviding.swift`

**Step 1: Write the failing provider contract test**

Test that a default provider can publish a repository snapshot, expose it through the protocol, notify observers, and cancel an observer without changing the data model.

**Step 2: Run the provider test to verify it fails**

Run: `swift test --package-path Packages/ProviderActivityHeatmap`

Expected: FAIL because the package and provider types do not exist.

**Step 3: Implement the minimal provider contract and in-memory default**

Define `ActivityHeatmapDay` (`date`, `commitCount`), `ActivityHeatmapSnapshot` (`repositoryPath`, `generatedAt`, `days`), `ActivityHeatmapProviding`, observer handle/event types, and `DefaultActivityHeatmapProvider` with replacement semantics and main-actor observation. Extend `ContentViewProviding.addContentView` with an optional stable `layoutGroup` while preserving the existing API behavior for callers that omit it; same-group entries are rendered in an `HStack`, other entries remain vertically stacked.

**Step 4: Run the provider tests**

Run: `swift test --package-path Packages/ProviderActivityHeatmap`

Expected: PASS.

**Step 5: Commit**

Run: `git add Packages/ProviderActivityHeatmap Packages/PluginCommitDetail/Package.swift Packages/FactoryGitOK/Package.swift && git commit -m "feat: add activity heatmap provider contract"`

### Task 2: Implement Commit Detail's local Git provider and cache

**Files:**
- Create: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/ActivityHeatmap/CommitActivityHeatmapProvider.swift`
- Create: `Packages/PluginCommitDetail/Tests/PluginCommitDetailTests/CommitActivityHeatmapProviderTests.swift`
- Modify: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/CommitDetailPlugin.swift`

**Step 1: Write failing aggregation and cache tests**

Test that commits are grouped by the selected calendar day, that an empty history produces an empty snapshot, and that a newly created provider reloads a valid JSON cache from its injected directory.

**Step 2: Run the focused tests to verify they fail**

Run: `swift test --package-path Packages/PluginCommitDetail --filter CommitActivityHeatmapProviderTests`

Expected: FAIL because the implementation does not exist.

**Step 3: Implement the plugin-owned provider**

Inject `GitProviding`, `StorageProviding`, and a calendar/loader seam for tests. Load a bounded recent history (five years of daily cells, or the repository's available history), aggregate commits by local calendar day, use a stable repository-keyed JSON file in `StorageProviding.pluginDataDirectory(for: CommitDetailPlugin.id)`, and publish cached data before refreshing. Refresh on project selection/data changes and repository-watch changes; ignore stale refresh results. Register the concrete provider in the kernel from Commit Detail so the implementation remains plugin-owned.

**Step 4: Run focused tests**

Run: `swift test --package-path Packages/PluginCommitDetail --filter CommitActivityHeatmapProviderTests`

Expected: PASS.

**Step 5: Commit**

Run: `git add Packages/PluginCommitDetail && git commit -m "feat: cache local git activity heatmap"`

### Task 3: Add the Commit Detail capability and heatmap view

**Files:**
- Create: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/Capabilities/CommitDetailActivityHeatmapCapability.swift`
- Create: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/ViewModels/CommitActivityHeatmapViewModel.swift`
- Create: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/Views/CommitActivityHeatmapView.swift`
- Modify: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/CommitDetailPlugin.swift`
- Modify: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/Views/CommitDetailView.swift`
- Modify: `Packages/PluginCommitDetail/Resources/Localizable.xcstrings`

**Step 1: Write failing view-model/capability tests**

Test that provider snapshots are copied into published view-model state and that the heatmap maps zero, low, medium, and high counts to deterministic colors/levels.

**Step 2: Run focused tests to verify they fail**

Run: `swift test --package-path Packages/PluginCommitDetail --filter CommitActivityHeatmapViewModelTests`

Expected: FAIL because the capability/view-model types do not exist.

**Step 3: Implement the capability, model, and SwiftUI view**

Keep the view free of provider subscriptions. Render a compact five-column-week grid with weekday labels, a legend, tooltip/accessibility text for each day, and a graceful empty state. Limit the heatmap to the same clean-worktree mode as the left view.

**Step 4: Compose the clean state and heatmap horizontally**

Use the new `layoutGroup` on `ContentViewProviding`: keep `PluginWorktreeClean`'s existing view as the left member of a stable group, and have Commit Detail register its heatmap view as the right member in the same group. Keep Commit Detail's existing commit/worktree content entry separate. Preserve existing behavior in non-clean/selected-commit modes and assign the left pane a larger flexible width than the heatmap.

**Step 5: Run focused tests**

Run: `swift test --package-path Packages/PluginCommitDetail --filter CommitActivityHeatmapViewModelTests`

Expected: PASS.

**Step 6: Commit**

Run: `git add Packages/PluginCommitDetail && git commit -m "feat: render commit activity heatmap beside clean state"`

### Task 4: Integrate package wiring and verify the application target

**Files:**
- Modify: `Packages/FactoryGitOK/Package.swift`
- Modify: `Packages/FactoryGitOK/Sources/FactoryGitOK/ProviderFactory.swift` (only if the provider must be registered centrally)
- Modify: `Packages/FactoryGitOK/Sources/FactoryGitOK/PluginFactory.swift` (only if plugin construction changes)

**Step 1: Run all affected package tests**

Run: `swift test --package-path Packages/ProviderActivityHeatmap` and `swift test --package-path Packages/PluginCommitDetail`

Expected: PASS.

**Step 2: Build the app package graph**

Run: `swift build --package-path Packages/FactoryGitOK`

Expected: PASS with the new provider package resolved through FactoryGitOK.

**Step 3: Inspect the final diff and working tree**

Run: `git diff --check` and `git status --short`

Expected: no whitespace errors and only the feature/plan files changed.

**Step 4: Commit integration changes**

Run: `git add Packages/FactoryGitOK && git commit -m "build: wire activity heatmap provider package"`
