import XCTest

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
}
