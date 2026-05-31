import XCTest
@testable import PluginGitIgnore

final class GitIgnorePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = GitIgnorePlugin.metadata

        XCTAssertEqual(metadata.id, "GitignorePlugin")
        XCTAssertEqual(metadata.iconName, "doc.badge.gearshape")
        XCTAssertEqual(metadata.order, 9999)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "GitIgnore")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginGitIgnoreLocalization.bundle.url(forResource: "GitIgnore", withExtension: "xcstrings"))
        XCTAssertFalse(PluginGitIgnoreLocalization.string("Gitignore").isEmpty)
        XCTAssertFalse(PluginGitIgnoreLocalization.string("Provides .gitignore viewer in status bar").isEmpty)
    }

    @MainActor
    func testStatusBarContributionIsAvailable() {
        XCTAssertNotNil(GitIgnorePlugin.shared.statusBarTrailingView())
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
