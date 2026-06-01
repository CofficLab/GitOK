import GitOKCoreKit
import XCTest
@testable import PluginSubmodule

final class SubmodulePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = SubmodulePlugin.metadata

        XCTAssertEqual(metadata.id, "SubmodulePlugin")
        XCTAssertEqual(metadata.displayName, "Submodule")
        XCTAssertEqual(metadata.iconName, "shippingbox")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "GitSubmodule")
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginSubmoduleLocalization.bundle.url(forResource: "GitSubmodule", withExtension: "xcstrings"))
        XCTAssertFalse(PluginSubmoduleLocalization.string("Submodule").isEmpty)
        XCTAssertFalse(PluginSubmoduleLocalization.string("Initialize").isEmpty)
    }

    @MainActor
    func testStatusBarTrailingContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))
        XCTAssertNotNil(SubmodulePlugin.shared.statusBarTrailingView(context: context))
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
