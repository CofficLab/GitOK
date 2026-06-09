import XCTest
@testable import ProjectSupportKit

final class ProjectGitOperationEventDescriptorTests: XCTestCase {
    func testStashSaveSuccessNormalizesNilMessageToEmptyString() {
        let descriptor = ProjectGitOperationEventDescriptor.stashSaveSuccess(message: nil)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectDidCommit")
        XCTAssertEqual(descriptor.operation, "stashSave")
        XCTAssertTrue(descriptor.success)
        XCTAssertNil(descriptor.error)
        XCTAssertEqual(descriptor.additionalInfo?["message"] as? String, "")
    }

    func testStashSaveFailurePreservesMessageAndError() {
        let error = NSError(domain: "Test", code: 42, userInfo: [NSLocalizedDescriptionKey: "stash failed"])
        let descriptor = ProjectGitOperationEventDescriptor.stashSaveFailure(message: "wip", error: error)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectOperationDidFail")
        XCTAssertEqual(descriptor.operation, "stashSave")
        XCTAssertFalse(descriptor.success)
        XCTAssertEqual(descriptor.error as NSError?, error)
        XCTAssertEqual(descriptor.additionalInfo?["message"] as? String, "wip")
    }

    func testStashIndexOperationsCarryIndexPayload() {
        let applyDescriptor = ProjectGitOperationEventDescriptor.stashApplySuccess(index: 3)
        let popDescriptor = ProjectGitOperationEventDescriptor.stashPopFailure(
            index: 5,
            error: NSError(domain: "Test", code: 7)
        )
        let dropDescriptor = ProjectGitOperationEventDescriptor.stashDropSuccess(index: 8)

        XCTAssertEqual(applyDescriptor.additionalInfo?["index"] as? Int, 3)
        XCTAssertEqual(popDescriptor.notificationName.rawValue, "projectOperationDidFail")
        XCTAssertEqual(popDescriptor.additionalInfo?["index"] as? Int, 5)
        XCTAssertEqual(dropDescriptor.additionalInfo?["index"] as? Int, 8)
    }

    func testContinueMergeSuccessUsesMergeNotificationAndBranchPayload() {
        let descriptor = ProjectGitOperationEventDescriptor.continueMergeSuccess(branchName: "feature/refactor")

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectDidMerge")
        XCTAssertEqual(descriptor.operation, "continueMerge")
        XCTAssertTrue(descriptor.success)
        XCTAssertEqual(descriptor.additionalInfo?["branchName"] as? String, "feature/refactor")
    }

    func testAbortMergeFailureUsesFailureNotificationWithoutAdditionalInfo() {
        let error = NSError(domain: "Test", code: 9, userInfo: [NSLocalizedDescriptionKey: "not merging"])
        let descriptor = ProjectGitOperationEventDescriptor.abortMergeFailure(error: error)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectOperationDidFail")
        XCTAssertEqual(descriptor.operation, "abortMerge")
        XCTAssertFalse(descriptor.success)
        XCTAssertEqual(descriptor.error as NSError?, error)
        XCTAssertNil(descriptor.additionalInfo)
    }

    func testStashApplyFailurePreservesIndexAndError() {
        let error = NSError(domain: "Test", code: 13, userInfo: [NSLocalizedDescriptionKey: "apply failed"])
        let descriptor = ProjectGitOperationEventDescriptor.stashApplyFailure(index: 2, error: error)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectOperationDidFail")
        XCTAssertEqual(descriptor.operation, "stashApply")
        XCTAssertFalse(descriptor.success)
        XCTAssertEqual(descriptor.error as NSError?, error)
        XCTAssertEqual(descriptor.additionalInfo?["index"] as? Int, 2)
    }

    func testStashPopSuccessCarriesIndexPayload() {
        let descriptor = ProjectGitOperationEventDescriptor.stashPopSuccess(index: 7)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectDidCommit")
        XCTAssertEqual(descriptor.operation, "stashPop")
        XCTAssertTrue(descriptor.success)
        XCTAssertNil(descriptor.error)
        XCTAssertEqual(descriptor.additionalInfo?["index"] as? Int, 7)
    }

    func testStashPopFailurePreservesIndexAndError() {
        let error = NSError(domain: "Test", code: 17, userInfo: [NSLocalizedDescriptionKey: "pop failed"])
        let descriptor = ProjectGitOperationEventDescriptor.stashPopFailure(index: 4, error: error)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectOperationDidFail")
        XCTAssertEqual(descriptor.operation, "stashPop")
        XCTAssertFalse(descriptor.success)
        XCTAssertEqual(descriptor.error as NSError?, error)
        XCTAssertEqual(descriptor.additionalInfo?["index"] as? Int, 4)
    }

    func testStashDropFailurePreservesIndexAndError() {
        let error = NSError(domain: "Test", code: 21, userInfo: [NSLocalizedDescriptionKey: "drop failed"])
        let descriptor = ProjectGitOperationEventDescriptor.stashDropFailure(index: 9, error: error)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectOperationDidFail")
        XCTAssertEqual(descriptor.operation, "stashDrop")
        XCTAssertFalse(descriptor.success)
        XCTAssertEqual(descriptor.error as NSError?, error)
        XCTAssertEqual(descriptor.additionalInfo?["index"] as? Int, 9)
    }

    func testAbortMergeSuccessUsesMergeNotificationWithoutAdditionalInfo() {
        let descriptor = ProjectGitOperationEventDescriptor.abortMergeSuccess()

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectDidMerge")
        XCTAssertEqual(descriptor.operation, "abortMerge")
        XCTAssertTrue(descriptor.success)
        XCTAssertNil(descriptor.error)
        XCTAssertNil(descriptor.additionalInfo)
    }

    func testContinueMergeFailurePreservesBranchNameAndError() {
        let error = NSError(domain: "Test", code: 25, userInfo: [NSLocalizedDescriptionKey: "continue failed"])
        let descriptor = ProjectGitOperationEventDescriptor.continueMergeFailure(branchName: "feature/bugfix", error: error)

        XCTAssertEqual(descriptor.notificationName.rawValue, "projectOperationDidFail")
        XCTAssertEqual(descriptor.operation, "continueMerge")
        XCTAssertFalse(descriptor.success)
        XCTAssertEqual(descriptor.error as NSError?, error)
        XCTAssertEqual(descriptor.additionalInfo?["branchName"] as? String, "feature/bugfix")
    }
}
