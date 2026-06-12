@testable import GitWorkspaceCore
import Testing

@Suite("FileListRules")
struct FileListRulesTests {
    @Test("presentation state handles large unselected worktree list")
    func presentationStateHandlesLargeUnselectedWorktreeList() {
        let paths = (0..<100_000).map { "Sources/File\($0).swift" }
        let unstagedPaths = Set(paths)

        let state = FileListRules.presentationState(
            allPaths: paths,
            filterText: "",
            isHistoryMode: false,
            stagedPaths: [],
            unstagedPaths: unstagedPaths,
            untrackedPaths: [],
            selectedBatchPaths: []
        )

        #expect(state.visiblePaths.count == paths.count)
        #expect(state.sections == [
            FileListRules.FileSection(kind: .changes, paths: paths)
        ])
        #expect(state.batchActionState.selectedPaths.isEmpty)
        #expect(state.batchActionState.stageablePaths.isEmpty)
        #expect(state.batchActionState.unstageablePaths.isEmpty)
        #expect(state.showsBatchActionBar == false)
        #expect(state.showsDiscardAll == true)
    }

    @Test("presentation state groups staged and unstaged paths in one pass")
    func presentationStateGroupsStagedAndUnstagedPaths() {
        let paths = ["a.txt", "b.txt", "c.txt"]

        let state = FileListRules.presentationState(
            allPaths: paths,
            filterText: "",
            isHistoryMode: false,
            stagedPaths: ["b.txt", "c.txt"],
            unstagedPaths: ["a.txt", "c.txt"],
            untrackedPaths: [],
            selectedBatchPaths: ["a.txt", "b.txt", "c.txt"]
        )

        #expect(state.sections == [
            FileListRules.FileSection(kind: .changes, paths: ["a.txt", "c.txt"]),
            FileListRules.FileSection(kind: .stagedChanges, paths: ["b.txt"]),
        ])
        #expect(state.batchActionState.stageablePaths == ["a.txt", "c.txt"])
        #expect(state.batchActionState.unstageablePaths == ["b.txt", "c.txt"])
    }
}
