import XCTest
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
}
