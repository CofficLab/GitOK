import XCTest

final class ConflictResolutionStateTests: XCTestCase {
    func testIdleStateDisablesContinueAndShowsIdleMessages() {
        let state = ConflictResolutionState(isMerging: false, mergeFiles: [])

        XCTAssertFalse(state.hasStagedResolutions)
        XCTAssertFalse(state.hasPendingUnstagedResolutions)
        XCTAssertFalse(state.canContinueMerge)
        XCTAssertEqual(state.statusSubtitle, "没有正在进行的冲突流程。")
        XCTAssertEqual(state.continueHint, "No merge in progress")
    }

    func testUnresolvedFilesBlockContinueAndPrioritizeResolveMessage() {
        let state = ConflictResolutionState(
            isMerging: true,
            mergeFiles: [
                GitMergeFile(path: "conflict.swift", state: .unresolved),
                GitMergeFile(path: "resolved.swift", state: .staged),
            ]
        )

        XCTAssertTrue(state.hasStagedResolutions)
        XCTAssertTrue(state.hasUnresolvedFiles)
        XCTAssertFalse(state.canContinueMerge)
        XCTAssertEqual(state.statusSubtitle, "先在编辑器中解决冲突，再将文件标记为已解决。")
        XCTAssertEqual(state.continueHint, "Resolve conflicts before continue")
    }

    func testPendingStageStateBlocksContinueUntilEverythingIsStaged() {
        let state = ConflictResolutionState(
            isMerging: true,
            mergeFiles: [
                GitMergeFile(path: "resolved.swift", state: .pendingStage),
                GitMergeFile(path: "ready.swift", state: .staged),
            ]
        )

        XCTAssertTrue(state.hasStagedResolutions)
        XCTAssertTrue(state.hasPendingUnstagedResolutions)
        XCTAssertFalse(state.canContinueMerge)
        XCTAssertEqual(state.statusSubtitle, "冲突标记已移除，但还有文件尚未暂存。")
        XCTAssertEqual(state.continueHint, "Stage resolved files before continue")
    }

    func testFullyStagedMergeEnablesContinue() {
        let state = ConflictResolutionState(
            isMerging: true,
            mergeFiles: [
                GitMergeFile(path: "a.swift", state: .staged),
                GitMergeFile(path: "b.swift", state: .staged),
            ]
        )

        XCTAssertTrue(state.hasStagedResolutions)
        XCTAssertFalse(state.hasPendingUnstagedResolutions)
        XCTAssertTrue(state.canContinueMerge)
        XCTAssertEqual(state.statusSubtitle, "所有合并文件都已暂存，可以继续完成合并。")
        XCTAssertEqual(state.continueHint, "Ready to continue merge")
    }

    func testEmptyMergeStateDoesNotAllowContinue() {
        let state = ConflictResolutionState(isMerging: true, mergeFiles: [])

        XCTAssertFalse(state.hasStagedResolutions)
        XCTAssertFalse(state.canContinueMerge)
        XCTAssertEqual(state.statusSubtitle, "合并仍在进行中。")
        XCTAssertEqual(state.continueHint, "Merge in progress")
    }
}
