# Discard All Worktree Changes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a safe, repository-wide “Discard All Changes” action to Commit Detail’s worktree view.

**Architecture:** Keep the destructive operation in `KitGit`, expose it through the existing `GitOperationProviding` boundary, and implement both CLI and LibGit2 backend adapters. Commit Detail will only collect a fresh status snapshot, ask for explicit confirmation, invoke the provider asynchronously, and refresh through the existing `notifyDataChanged()` path. The operation covers staged, unstaged, deleted, renamed, and untracked entries while leaving ignored files, commits, branches, and remotes untouched.

**Tech Stack:** Swift 6, Swift Package Manager, SwiftUI, `GitProcessRunner`, `GitProviding`, XCTest.

---

### Task 1: Add the repository-level Git operation

**Files:**
- Modify: `Packages/KitGit/Sources/KitGit/GitCommitOperation.swift`
- Test: `Packages/KitGit/Tests/KitGitTests/GitCommitOperationTests.swift`

**Steps:**

1. Add a failing integration test that creates a temporary repository containing tracked modifications, staged modifications, a tracked deletion, a staged rename or addition, and an untracked file/directory. Call `discardAllChanges(in:)` and assert that the worktree is clean, tracked `HEAD` content is restored, staged state is gone, and untracked items are removed.
2. Run `swift test --package-path Packages/KitGit --filter GitCommitOperationTests` and confirm the new test fails because the operation does not exist.
3. Implement `GitCommitOperation.discardAllChanges(in:)` with the repository-level semantics: reset the index, restore tracked paths from `HEAD` when a `HEAD` exists, then clean non-ignored untracked files/directories. Keep ignored files untouched and preserve the existing path-safety/error handling conventions.
4. Add coverage for an empty worktree and a repository without a first commit; both should complete without corrupting the repository.
5. Run the focused test suite and confirm it passes.

### Task 2: Expose the capability through Git Provider backends

**Files:**
- Modify: `Packages/ProviderGit/Sources/ProviderGit/GitProviding.swift`
- Modify: `Packages/ProviderGit/Sources/ProviderGit/DefaultGitProvider.swift`
- Modify: `Packages/PluginGitCLI/Sources/PluginGitCLI/GitCLIBackend.swift`
- Modify: `Packages/PluginGitLibGit2/Sources/PluginGitLibGit2/GitLibGit2Backend.swift`

**Steps:**

1. Add `discardAllChanges(in:)` to `GitOperationProviding` next to the existing stage/unstage/discard methods.
2. Forward the operation in `DefaultGitProvider`, `GitCLIBackend`, and `GitLibGit2Backend` without adding UI-specific behavior to any backend.
3. Build and test `ProviderGit`, `PluginGitCLI`, and `PluginGitLibGit2` to verify every backend conforms to the updated protocol.

### Task 3: Add the Commit Detail action and confirmation flow

**Files:**
- Modify: `Packages/PluginCommitDetail/Sources/PluginCommitDetail/Views/WorktreeChangesView.swift`
- Modify: `Packages/PluginCommitDetail/Resources/Localizable.xcstrings`

**Steps:**

1. Add an explicit `Discard All` destructive icon action to the worktree header, visible only when entries are present and disabled while any stage/unstage/discard operation is active.
2. Add a separate confirmation state for the whole worktree snapshot. The message must state the number of affected entries and that staged, unstaged, and untracked changes will be deleted permanently.
3. On confirmation, invoke the provider asynchronously, show progress, clear selection, call `onDataChanged()` on success, and preserve the list with an error banner on failure.
4. Ensure a fresh status snapshot is captured before confirmation and that stale results cannot overwrite a newer project/load token.
5. Add English and Simplified Chinese localization entries for the action, confirmation title/message, and failure state if needed.

### Task 4: Verify behavior and integration

**Files:**
- Test/inspect: `Packages/KitGit/Tests/KitGitTests/GitCommitOperationTests.swift`
- Test/inspect: `Packages/PluginCommitDetail/Tests/PluginCommitDetailTests/CommitDetailPluginTests.swift`
- Build/inspect: `GitOK.xcodeproj/project.pbxproj`

**Steps:**

1. Run the KitGit discard integration tests and all Commit Detail tests.
2. Run the relevant package builds and the GitOK Xcode Debug build.
3. Run `git diff --check` and verify the final diff contains only the intended feature changes.
4. Manually review that no command uses `git clean -x` or otherwise removes ignored files, and that no operation targets a commit, branch, or remote.
