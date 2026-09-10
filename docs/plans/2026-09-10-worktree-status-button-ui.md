# Worktree Status Button UI Upgrade Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade the Worktree Status rail action button into a theme-aware Branch Pulse control with a custom loading animation while preserving existing Push, Sync, and conflict behavior.

**Architecture:** Keep the current operation orchestration in `WorkingTreeStatusView`, but extract the button presentation into small private SwiftUI views. Use `@LumiTheme` semantic colors and `LumiMotionPreferenceReader`; use recognizable action glyphs, a remote badge, hover treatment, and a custom orbit loader rather than `ProgressView`. The button is intentionally flat and icon-only: a tonal fill, restrained border, no shadow or glossy highlight, and a compact badge only when remote deltas exist.

**Tech Stack:** Swift 6, SwiftUI, macOS 14+, LumiUI theme and motion tokens, Swift Package Manager.

---

### Task 1: Add pure action-state mapping coverage

**Files:**
- Modify: `Packages/PluginWorktreeStatus/Tests/PluginWorktreeStatusTests/PluginWorktreeStatusTests.swift`
- Modify: `Packages/PluginWorktreeStatus/Sources/PluginWorktreeStatus/Views/WorkingTreeStatusView.swift`

**Step 1:** Add tests for the presentation state mapping: upstream versus no upstream, ahead/behind badge text, and synchronizing/pushing labels.

**Step 2:** Run `swift test --package-path Packages/PluginWorktreeStatus --filter PluginWorktreeStatusTests` and confirm the new mapping symbols are initially unavailable.

**Step 3:** Implement the smallest internal state helpers needed by the view without changing Git operation calls.

**Step 4:** Run the focused package tests and confirm they pass.

### Task 2: Implement the Branch Pulse button visuals

**Files:**
- Modify: `Packages/PluginWorktreeStatus/Sources/PluginWorktreeStatus/Views/WorkingTreeStatusView.swift`

**Step 1:** Replace the system `ProgressView` and `Color.accentColor` button treatment with a fixed-width, theme-driven custom button.

**Step 2:** Add a custom branch-node mark, remote delta badge, hover glow, pressed scale, and semantic accessibility label/help text.

**Step 3:** Add a custom orbit/sweep loader for synchronization and publishing, respecting Lumi reduced-motion preferences.

**Step 4:** Preserve the existing `performPrimaryAction`, `performSynchronize`, `performPush`, and conflict resolver behavior.

### Task 3: Update localization and verify integration

**Files:**
- Modify: `Packages/PluginWorktreeStatus/Resources/Localizable.xcstrings`
- Modify: `Packages/PluginWorktreeStatus/README.md`

**Step 1:** Add localized action and activity labels required by the new control.

**Step 2:** Document the Branch Pulse states and theme integration briefly in the package README.

**Step 3:** Run `swift test --package-path Packages/PluginWorktreeStatus`.

**Step 4:** Build the package and inspect the diff for accidental behavior or scope changes.

**Step 5:** Manually verify the button in at least one dark theme, one light theme, reduced motion, no-upstream, ahead/behind, and loading states.
