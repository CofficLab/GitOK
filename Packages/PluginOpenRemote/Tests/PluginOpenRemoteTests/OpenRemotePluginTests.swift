import XCTest
@testable import PluginOpenRemote

final class OpenRemotePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenRemotePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenRemote")
        XCTAssertEqual(metadata.iconName, "link")
        XCTAssertEqual(metadata.order, 8407)
        XCTAssertTrue(metadata.allowUserToggle)
        XCTAssertTrue(metadata.defaultEnabled)
        XCTAssertEqual(metadata.tableName, "OpenRemote")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(PluginOpenRemoteLocalization.bundle.url(forResource: "OpenRemote", withExtension: "xcstrings"))
        XCTAssertFalse(PluginOpenRemoteLocalization.string("Open Remote").isEmpty)
        XCTAssertFalse(PluginOpenRemoteLocalization.string("Open in Browser").isEmpty)
    }

    func testToolbarContributionIsAvailable() {
        XCTAssertNotNil(OpenRemotePlugin.shared.toolBarTrailingView())
    }

    func testRemoteURLConversion() {
        XCTAssertEqual(
            OpenRemoteURLProvider.webURL(forRemoteURL: "git@github.com:cofficlab/gitok.git")?.absoluteString,
            "https://github.com/cofficlab/gitok"
        )
        XCTAssertNil(OpenRemoteURLProvider.webURL(forRemoteURL: nil))
        XCTAssertNil(OpenRemoteURLProvider.webURL(forRemoteURL: "/tmp/repo.git"))
    }
}
