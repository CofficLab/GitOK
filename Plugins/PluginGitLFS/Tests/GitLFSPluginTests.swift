import Foundation
import GitOKCoreKit
import XCTest
@testable import PluginGitLFS

final class GitLFSPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitLFSPlugin.metadata

        XCTAssertEqual(metadata.id, "GitLFSPlugin")
        XCTAssertEqual(metadata.iconName, "externaldrive.badge.timemachine")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "GitLFS")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginGitLFSLocalization.bundle.url(forResource: "GitLFS", withExtension: "xcstrings"))
        XCTAssertFalse(PluginGitLFSLocalization.string("Git LFS").isEmpty)
        XCTAssertFalse(PluginGitLFSLocalization.string("Git LFS status and large file recommendations").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))

        XCTAssertNotNil(GitLFSPlugin.shared.statusBarTrailingView(context: context))
    }
}
