import GitOKCoreKit
import XCTest
@testable import GitIgnorePlugin

final class GitIgnorePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitIgnorePlugin.metadata

        XCTAssertEqual(metadata.id, "GitignorePlugin")
        XCTAssertEqual(metadata.iconName, "doc.badge.gearshape")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(GitIgnorePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(GitIgnorePluginLocalization.string("Gitignore").isEmpty)
        XCTAssertFalse(GitIgnorePluginLocalization.string("Provides .gitignore viewer in status bar").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))
        XCTAssertNotNil(GitIgnorePlugin.shared.statusBarTrailingView(context: context))
    }

    func testXcodeTemplateMergeIsStable() {
        let merged = GitIgnoreOrganizer.merge(existing: "build/\nDerivedData/\n", template: .xcode)

        XCTAssertTrue(merged.contains("# Xcode"))
        XCTAssertTrue(merged.contains("*.xcuserstate"))
        XCTAssertEqual(merged.components(separatedBy: "DerivedData/").count, 2)
    }

    func testOrganizeGroupsKnownTemplates() {
        let organized = GitIgnoreOrganizer.organize(existing: "pubspec.lock\nfoo.tmp\n*.xcuserstate\n")

        XCTAssertTrue(organized.contains("# Xcode"))
        XCTAssertTrue(organized.contains("# Flutter"))
        XCTAssertTrue(organized.contains("# Other"))
        XCTAssertTrue(organized.contains("foo.tmp"))
    }
}
