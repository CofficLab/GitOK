# Git Process Pipe Deadlock Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent Git subprocesses from hanging on large output and stop stale project-language analysis tasks from accumulating after project changes.

**Architecture:** Update the shared Git process runner so stdout and stderr are drained while the child process is running. Make the project-language provider retain and cancel the previous analysis task, while keeping the existing generation guard for stale results.

**Tech Stack:** Swift 6, Foundation `Process`/`Pipe`, Swift Concurrency, Swift Testing, Xcode/macOS.

---

### Task 1: Cover large-output Git process handling

**Files:**
- Modify: `Packages/KitGit/Sources/KitGit/GitProcessRunner.swift`
- Test: `Packages/KitGit/Tests/KitGitTests/GitProcessRunnerTests.swift` (or the existing KitGit process-runner test target)

**Steps:**

1. Locate the existing KitGit test target and add a test that executes a command producing more than the pipe buffer through `GitProcessRunner.run`.
2. Run the focused test and confirm it reproduces the timeout/hang before the implementation change.
3. Change `GitProcessRunner.run` to consume stdout and stderr concurrently while the process is running, preserving exit-code handling and UTF-8/GB18030 decoding.
4. Run the focused test and the complete KitGit test suite.

### Task 2: Cancel stale project language analysis

**Files:**
- Modify: `Packages/PluginProjectLanguages/Sources/PluginProjectLanguages/LocalProjectLanguagesProvider.swift`
- Test: `Packages/PluginProjectLanguages/Tests/PluginProjectLanguagesTests/LocalProjectLanguagesProviderTests.swift`

**Steps:**

1. Add a test analyzer or refresh scenario proving a second refresh cancels the first analysis and only the newest repository can publish a snapshot.
2. Run the focused test and confirm it fails against the current implementation.
3. Store the active `Task`, cancel it before each refresh, clear it on completion, and retain the generation guard as a second safety check.
4. Run the complete PluginProjectLanguages test suite.

### Task 3: Verify integration

**Files:**
- No additional source files expected.

**Steps:**

1. Run the ProviderProjectLanguages, PluginWorktreeClean, and FactoryGitOK test suites.
2. Run the full GitOK Debug build without code signing.
3. Check `git diff --check` and confirm no unrelated files are staged.

### Task 4: Commit

**Steps:**

1. Stage only the pipe fix, cancellation fix, tests, and this plan document.
2. Commit with `fix: prevent git loading deadlocks`.
