import XCTest
import LibGit2Swift
@testable import GitCoreKit

final class GitOperationErrorTests: XCTestCase {
    func testPushNeedsFetchMessageClassifiesCommonGitOutput() {
        let error = NSError(
            domain: "Git",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "failed to push some refs: non-fast-forward",
            ]
        )

        XCTAssertEqual(
            GitOperationError.pushNeedsFetchMessage(from: error),
            "failed to push some refs: non-fast-forward"
        )
    }

    func testSyncNeedsUserDecisionDescriptionMentionsDivergence() {
        let error = GitOperationError.syncNeedsUserDecision(ahead: 2, behind: 3)

        XCTAssertEqual(error.errorDescription, "本地有 2 个未推送提交，远程有 3 个本地没有的提交。")
        XCTAssertEqual(error.recoverySuggestion, "请先 Pull 或 Rebase 处理分叉后，再执行 Push。")
    }

    func testRemoteErrorKindHidesLibGit2ErrorDetails() {
        XCTAssertEqual(GitOperationError.remoteErrorKind(from: LibGit2Error.networkError(-1)), .network)
        XCTAssertEqual(GitOperationError.remoteErrorKind(from: LibGit2Error.authenticationError), .authentication)
        XCTAssertEqual(GitOperationError.remoteErrorKind(from: LibGit2Error.configNotFound), .known)
        XCTAssertEqual(GitOperationError.remoteErrorKind(from: NSError(domain: "Other", code: 1)), .other)
    }

    func testDetectsLocalChangesWouldBeOverwritten() {
        let error = LibGit2Error.localChangesWouldBeOverwritten(message: "checkout blocked")
        XCTAssertTrue(GitOperationError.isLocalChangesWouldBeOverwritten(error))
        XCTAssertFalse(GitOperationError.isLocalChangesWouldBeOverwritten(LibGit2Error.mergeConflict))
    }
}
