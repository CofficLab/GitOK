import XCTest

final class AutoPushDecisionTests: XCTestCase {
    func testCheckSkipsWhenBranchIsMissing() {
        XCTAssertEqual(
            AutoPushDecision.check(
                currentBranchName: nil,
                isEnabled: true,
                isGitRepo: true,
                hasRemote: true
            ),
            .skip(.missingBranch)
        )
    }

    func testCheckSkipsWhenAutoPushIsDisabled() {
        XCTAssertEqual(
            AutoPushDecision.check(
                currentBranchName: "main",
                isEnabled: false,
                isGitRepo: true,
                hasRemote: true
            ),
            .skip(.disabled)
        )
    }

    func testCheckSkipsWhenProjectIsNotGitRepository() {
        XCTAssertEqual(
            AutoPushDecision.check(
                currentBranchName: "main",
                isEnabled: true,
                isGitRepo: false,
                hasRemote: true
            ),
            .skip(.notGitRepository)
        )
    }

    func testCheckSkipsWhenRemoteIsMissing() {
        XCTAssertEqual(
            AutoPushDecision.check(
                currentBranchName: "main",
                isEnabled: true,
                isGitRepo: true,
                hasRemote: false
            ),
            .skip(.missingRemote)
        )
    }

    func testCheckAllowsPushWhenAllRequirementsAreMet() {
        XCTAssertEqual(
            AutoPushDecision.check(
                currentBranchName: "feature/refactor",
                isEnabled: true,
                isGitRepo: true,
                hasRemote: true
            ),
            .shouldPush(branchName: "feature/refactor")
        )
    }

    func testExecutionSkipsWhenPushIsAlreadyRunning() {
        XCTAssertEqual(
            AutoPushDecision.execution(isAlreadyPushing: true, unpushedCommitCount: 3),
            .skipAlreadyPushing
        )
    }

    func testExecutionMarksIdleWhenThereIsNothingToPush() {
        XCTAssertEqual(
            AutoPushDecision.execution(isAlreadyPushing: false, unpushedCommitCount: 0),
            .markIdle
        )
    }

    func testExecutionPushesWhenCommitsAreWaiting() {
        XCTAssertEqual(
            AutoPushDecision.execution(isAlreadyPushing: false, unpushedCommitCount: 2),
            .push
        )
    }
}
