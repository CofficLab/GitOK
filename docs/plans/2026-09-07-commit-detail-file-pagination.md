# Commit Detail File Pagination Implementation Plan

> **For Codex:** Implement this plan task-by-task with review checkpoints. Keep the existing commit selection and selected-file behavior compatible during migration.

**Goal:** Make the commit detail changed-file list remain responsive and memory-bounded even when a commit changes tens of thousands of files.

**Architecture:** Replace the current eager `[GitFileChange]` load with offset-based file pages. The Git layer will count and stream only the requested page, the commit-detail data source will keep a small LRU page cache, and the SwiftUI list will render indexed placeholders for unloaded rows. Selecting a file will continue to load its full diff only after selection.

**Tech Stack:** Swift 6, SwiftUI `LazyVStack`, macOS `Process`/`Pipe`, `KitGit`, `ProviderGit`, `PluginCommitDetail`, XCTest.

---

## Current problem

`ProjectManager.loadCommitFiles` calls `git.loadChanges`, which runs `diff-tree` and `numstat`, parses every changed file, and stores the entire result in `currentCommitFiles`. `CommitDetailLayout` uses `LazyVStack`, but that only delays row view creation; it does not reduce the already-created array or the Git command output held during parsing.

The fix must therefore enforce bounded memory at three levels:

1. Git process output is streamed instead of collected into one large `String`.
2. The provider returns one requested page instead of a complete file list.
3. The UI retains only a small number of nearby pages and uses placeholders for the rest.

## Target behavior

- Initial commit detail shows the first page quickly, with a total file count when available.
- Scrolling down requests the next page; scrolling up requests the previous page.
- Only a bounded cache, recommended at 3–5 pages, remains in memory.
- Page requests are deduplicated and cancelled/ignored when the selected commit changes.
- A failed page shows an inline retry affordance without clearing already loaded pages.
- The header count represents the total changed-file count, not only loaded rows.
- File paths, status, rename information, and numstat values remain unchanged.
- Full file contents are never loaded for the list; the existing selected-file diff path remains on demand.

## Implementation tasks

### Task 1: Add streaming Git primitives

**Files:**

- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/KitGit/Sources/KitGit/GitProcessRunner.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/KitGit/Sources/KitGit/GitDiffLoader.swift`
- Test `/Users/colorfy/Code/CofficLab/GitOK/Packages/KitGit/Tests/KitGitTests/GitDiffLoaderTests.swift`

1. Add a streaming process API that reads stdout in chunks and reports stderr on failure. It must support cancellation/early termination after the requested page has been collected.
2. Add a NUL-delimited parser for Git path records so tabs, newlines, Unicode paths, and rename pairs are handled safely.
3. Add `countChanges(commit:in:)` that counts records without retaining them.
4. Add `loadChangesPage(commit:limit:offset:in:)` returning a `GitFileChangePage` containing `items`, `offset`, `hasMore`, and `totalCount` when known.
5. Keep the existing full `loadChanges` API temporarily as a compatibility wrapper implemented by paging, then mark it deprecated after all callers migrate.
6. Add tests for page boundaries, no duplicate paths, root commits, binary files, renamed files, Unicode paths, empty changes, and a generated repository with at least 1,000 changed files.

### Task 2: Expose paged changes through Git providers

**Files:**

- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/ProviderGit/Sources/ProviderGit/GitProviding.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/ProviderGit/Sources/ProviderGit/DefaultGitProvider.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginGitCLI/Sources/PluginGitCLI/GitCLIBackend.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginGitLibGit2/Sources/PluginGitLibGit2/GitLibGit2Backend.swift`

1. Add provider requirements for `countCommitChanges` and `loadCommitChangesPage`.
2. Route both operations through `DefaultGitProvider.execute` so backend fallback behavior remains consistent.
3. Implement the CLI backend with the streaming `KitGit` loader.
4. Implement the LibGit2 backend with a bounded iterator/page operation. If the current LibGit2 wrapper cannot expose an iterator, add that capability to the wrapper rather than calling an API that materializes the complete diff.
5. Keep existing `loadChanges` behavior for unrelated consumers until migration is complete.

### Task 3: Introduce a bounded commit-file page store

**Files:**

- Create `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginCommitDetail/Sources/PluginCommitDetail/ViewModels/CommitFilePageStore.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginCommitDetail/Sources/PluginCommitDetail/ViewModels/CommitDetailViewModel.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginCommitDetail/Sources/PluginCommitDetail/Observers/CommitDetailObserver.swift`

1. Define `CommitFilePageStore` as a `@MainActor` observable store keyed by commit hash and page index.
2. Store only `pageSize` pages around the visible page; evict least-recently-used pages that are not visible or prefetched.
3. Track `totalCount`, `loadedPages`, `loadingPages`, page errors, and a request token tied to the selected commit.
4. Deduplicate concurrent requests for the same page and ignore stale results after commit/project changes.
5. Keep `selectedFile` as a path/hash intent independent of page eviction, so changing the cache window cannot lose selection state.
6. During migration, keep `ProjectProviding.currentCommitFiles` as a compatibility surface but stop using it for `CommitDetailLayout`; remove the eager load after all consumers are migrated.

### Task 4: Render an indexed, paged SwiftUI list

**Files:**

- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginCommitDetail/Sources/PluginCommitDetail/Views/CommitDetailView.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginCommitDetail/Sources/PluginCommitDetail/Views/CommitDetailLayout.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginCommitDetail/Sources/PluginCommitDetail/Views/FileChangeRow.swift` if extracted during implementation

1. Change the layout input from a complete `[GitFileChange]` to the page store/data source.
2. Render `0..<totalCount` in `LazyVStack`; each visible index reads its page from the store.
3. Render a lightweight placeholder for unloaded rows and request the corresponding page from `onAppear`.
4. Standardize row height or provide a stable estimated height so inserting a page does not cause large scroll jumps.
5. Prefetch one page in the scroll direction and evict pages outside the protected visible window.
6. Keep the existing top progress indicator, empty state, error presentation, row animation, and file selection behavior.

### Task 5: Remove eager-loading paths and add regression coverage

**Files:**

- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginProjects/Sources/PluginProjects/ProjectManager.swift`
- Modify `/Users/colorfy/Code/CofficLab/GitOK/Packages/PluginCommitDetail/Tests/PluginCommitDetailTests/CommitDetailPluginTests.swift`
- Add page-store tests beside the new store

1. Stop loading the complete file list from `ProjectManager` once commit detail owns the paged store.
2. Verify commit switching cancels/invalidates old page requests.
3. Verify page requests are deduplicated, errors can retry, and LRU eviction never exceeds the configured page limit.
4. Verify scrolling forward and backward requests the correct offsets and preserves the selected file path.
5. Add a performance test with 10,000+ changed files asserting that initial memory remains bounded by the page cache rather than file count.

## Verification commands

Run each focused test while implementing, then run the complete relevant set:

```bash
swift test --package-path Packages/KitGit
swift test --package-path Packages/ProviderGit
swift test --package-path Packages/PluginGitCLI
swift test --package-path Packages/PluginGitLibGit2
swift test --package-path Packages/PluginCommitDetail
git diff --check
```

Manual QA should cover a normal commit, a commit with 1,000+ changed files, renamed/Unicode paths, rapid scrolling in both directions, selecting a file after page eviction, switching commits while a page is loading, and retrying a failed page.

## Rollout order

Implement and merge Tasks 1–2 first, then introduce the page store behind the existing detail view. After UI and regression coverage pass, remove the eager `ProjectManager` load path in a separate cleanup commit. This keeps each change reviewable and makes it possible to fall back to the previous detail list while the new page store is being validated.
