import Foundation
import GitOKCoreKit
import XCTest
@testable import GitLFSPlugin

final class GitLFSPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitLFSPlugin.metadata

        XCTAssertEqual(metadata.id, "GitLFSPlugin")
        XCTAssertEqual(metadata.iconName, "externaldrive.badge.timemachine")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(GitLFSPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(GitLFSPluginLocalization.string("Git LFS").isEmpty)
        XCTAssertFalse(GitLFSPluginLocalization.string("Git LFS status and large file recommendations").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))

        XCTAssertFalse(GitLFSPlugin.statusBarTrailingItems(context: context).isEmpty)
    }
}
