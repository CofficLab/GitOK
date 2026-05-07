import Foundation
import XCTest

final class ProjectEventRefreshRulesTests: XCTestCase {
    func testStashRefreshTriggersOnlyForStashOperations() {
        XCTAssertTrue(ProjectEventRefreshRules.shouldRefreshStash(for: "stashSave"))
        XCTAssertTrue(ProjectEventRefreshRules.shouldRefreshStash(for: "stashApply"))
        XCTAssertTrue(ProjectEventRefreshRules.shouldRefreshStash(for: "stashPop"))
        XCTAssertTrue(ProjectEventRefreshRules.shouldRefreshStash(for: "stashDrop"))

        XCTAssertFalse(ProjectEventRefreshRules.shouldRefreshStash(for: "commit"))
        XCTAssertFalse(ProjectEventRefreshRules.shouldRefreshStash(for: "addFiles"))
        XCTAssertFalse(ProjectEventRefreshRules.shouldRefreshStash(for: "continueMerge"))
    }

    func testConflictStatusRefreshTriggersForMergeAndAddFilesNotifications() {
        XCTAssertTrue(
            ProjectEventRefreshRules.shouldRefreshConflictStatus(
                for: Notification.Name("projectDidMerge")
            )
        )
        XCTAssertTrue(
            ProjectEventRefreshRules.shouldRefreshConflictStatus(
                for: Notification.Name("projectDidAddFiles")
            )
        )

        XCTAssertFalse(
            ProjectEventRefreshRules.shouldRefreshConflictStatus(
                for: Notification.Name("projectDidCommit")
            )
        )
        XCTAssertFalse(
            ProjectEventRefreshRules.shouldRefreshConflictStatus(
                for: Notification.Name("projectOperationDidFail")
            )
        )
    }
}
