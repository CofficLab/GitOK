@testable import GitWorkspaceCore
import GitCoreKit
import Testing

@Suite("WorkingStateConflictRules")
struct WorkingStateConflictRulesTests {
    @Test("unresolved files take priority over staged status")
    func unresolvedFilesTakePriority() {
        let files = WorkingStateConflictRules.mergeFiles(
            unresolvedPaths: ["Sources/App.swift"],
            statusEntries: [
                GitStatusEntry(path: "README.md", indexStatus: "M", workTreeStatus: " "),
                GitStatusEntry(path: "Sources/App.swift", indexStatus: "M", workTreeStatus: "M")
            ]
        )

        #expect(files == [
            GitMergeFile(path: "README.md", state: .staged),
            GitMergeFile(path: "Sources/App.swift", state: .unresolved)
        ])
    }

    @Test("merge can continue when all files are staged")
    func canContinueWhenAllFilesStaged() {
        let state = WorkingStateConflictState(
            isMerging: true,
            files: [
                GitMergeFile(path: "README.md", state: .staged),
                GitMergeFile(path: "Sources/App.swift", state: .staged)
            ]
        )

        #expect(state.unresolvedCount == 0)
        #expect(state.pendingStageCount == 0)
        #expect(state.stagedCount == 2)
        #expect(state.canContinueMerge)
    }

    @Test("large conflict panels limit rendered files")
    func largeConflictPanelsLimitRenderedFiles() {
        let files = (0..<125).map {
            GitMergeFile(path: "file-\($0).swift", state: .unresolved)
        }

        #expect(WorkingStateConflictRules.visibleFiles(from: files).count == 80)
        #expect(WorkingStateConflictRules.hiddenFileCount(totalCount: files.count) == 45)
    }
}
