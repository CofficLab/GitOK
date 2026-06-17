import XCTest
@testable import GitOKCoreKit

final class GitOKAppTabTests: XCTestCase {
    func testMigratedFromRawValue() {
        XCTAssertEqual(GitOKAppTab.migrated(from: "git"), .git)
        XCTAssertEqual(GitOKAppTab.migrated(from: "banner"), .banner)
        XCTAssertEqual(GitOKAppTab.migrated(from: "icon"), .icon)
    }

    func testMigratedFromLegacyDisplayNames() {
        XCTAssertEqual(GitOKAppTab.migrated(from: "Git"), .git)
        XCTAssertEqual(GitOKAppTab.migrated(from: "Banner"), .banner)
        XCTAssertEqual(GitOKAppTab.migrated(from: "Icon"), .icon)
    }

    func testMigratedFromUnknownReturnsNil() {
        XCTAssertNil(GitOKAppTab.migrated(from: "unknown"))
        XCTAssertNil(GitOKAppTab.migrated(from: ""))
    }
}
