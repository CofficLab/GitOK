import XCTest
@testable import GitOKCoreKit

final class GitOKAppTabTests: XCTestCase {
    func testMigratedFromRawValue() {
        XCTAssertEqual(GitOKAppTab.migrated(from: "git"), .git)
    }

    func testMigratedFromLegacyDisplayNames() {
        XCTAssertEqual(GitOKAppTab.migrated(from: "Git"), .git)
    }

    func testMigratedFromRemovedTabsReturnsNil() {
        XCTAssertNil(GitOKAppTab.migrated(from: "banner"))
        XCTAssertNil(GitOKAppTab.migrated(from: "icon"))
        XCTAssertNil(GitOKAppTab.migrated(from: "Banner"))
        XCTAssertNil(GitOKAppTab.migrated(from: "Icon"))
    }

    func testMigratedFromUnknownReturnsNil() {
        XCTAssertNil(GitOKAppTab.migrated(from: "unknown"))
        XCTAssertNil(GitOKAppTab.migrated(from: ""))
    }
}
