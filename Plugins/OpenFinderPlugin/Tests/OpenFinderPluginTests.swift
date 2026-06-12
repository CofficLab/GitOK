import XCTest
import GitOKCoreKit
@testable import OpenFinderPlugin

final class OpenFinderPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenFinderPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenFinder")
        XCTAssertEqual(metadata.iconName, "folder")
        XCTAssertEqual(metadata.order, 8300)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenFinderPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenFinderPluginLocalization.string("Open Finder").isEmpty)
        XCTAssertFalse(OpenFinderPluginLocalization.string("Open in Finder").isEmpty)
    }

    @MainActor
    func testToolbarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"))
        XCTAssertFalse(OpenFinderPlugin.toolbarTrailingItems(context: context).isEmpty)
    }
}
