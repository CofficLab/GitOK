import XCTest
@testable import OpenFinderPlugin

final class OpenFinderPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenFinderPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenFinder")
        XCTAssertEqual(metadata.iconName, "folder")
        XCTAssertEqual(metadata.order, 8300)
        XCTAssertFalse(metadata.allowUserToggle)
        XCTAssertFalse(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenFinderPluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenFinderPluginLocalization.string("Open Finder").isEmpty)
        XCTAssertFalse(OpenFinderPluginLocalization.string("Open in Finder").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenFinderPlugin.shared.toolBarTrailingView())
    }
}
