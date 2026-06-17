import GitCoreKit
import GitOKCoreKit
import XCTest
@testable import GitSubmodulePlugin

final class GitSubmodulePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitSubmodulePlugin.metadata

        XCTAssertEqual(metadata.id, "GitSubmodulePlugin")
        XCTAssertEqual(metadata.displayName, "Submodule")
        XCTAssertEqual(metadata.iconName, "shippingbox")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(GitSubmodulePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(GitSubmodulePluginLocalization.string("Submodule").isEmpty)
        XCTAssertFalse(GitSubmodulePluginLocalization.string("Initialize").isEmpty)
    }

    @MainActor
    func testStatusBarTrailingContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))
        XCTAssertFalse(GitSubmodulePlugin.statusBarTrailingItems(context: context).isEmpty)
    }

    func testPresentationCalculatesIssueCountAndIcon() {
        let submodules = [
            GitRepositoryCLI.GitSubmodule(path: "Ready", commitHash: "1234567890", status: .initialized, description: nil),
            GitRepositoryCLI.GitSubmodule(path: "NeedsInit", commitHash: "abcdef1234", status: .uninitialized, description: nil),
        ]

        XCTAssertEqual(SubmodulePresentation.issueCount(submodules), 1)
        XCTAssertEqual(SubmodulePresentation.iconName(issueCount: 0), "shippingbox")
        XCTAssertEqual(SubmodulePresentation.iconName(issueCount: 1), "shippingbox.fill")
    }

    func testPresentationBuildsRowSubtitle() {
        let submodule = GitRepositoryCLI.GitSubmodule(
            path: "Vendor/Kit",
            commitHash: "abcdef123456",
            status: .modified,
            description: "local changes"
        )

        let subtitle = SubmodulePresentation.rowSubtitle(for: submodule)
        XCTAssertTrue(subtitle.contains("abcdef12"))
        XCTAssertTrue(subtitle.contains("local changes"))
    }
}
