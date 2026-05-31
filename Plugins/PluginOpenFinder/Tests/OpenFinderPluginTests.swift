import XCTest
@testable import PluginOpenFinder

final class OpenFinderPluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenFinderPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenFinder")
        XCTAssertEqual(metadata.iconName, "folder")
        XCTAssertEqual(metadata.order, 8300)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenFinder")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginOpenFinderLocalization.bundle.url(forResource: "OpenFinder", withExtension: "xcstrings"))
        XCTAssertFalse(PluginOpenFinderLocalization.string("Open Finder").isEmpty)
        XCTAssertFalse(PluginOpenFinderLocalization.string("Open in Finder").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenFinderPlugin.shared.toolBarTrailingView())
    }
}
