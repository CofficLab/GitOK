import XCTest
import GitOKCoreKit
@testable import OpenRemotePlugin

final class OpenRemotePluginTests: XCTestCase {
    func testPluginMetadataIsStable() {
        let metadata = OpenRemotePlugin.metadata

        XCTAssertEqual(metadata.id, "OpenRemote")
        XCTAssertEqual(metadata.iconName, "link")
        XCTAssertEqual(metadata.order, 8407)
        XCTAssertEqual(metadata.tableName, "Localizable")
        XCTAssertFalse(metadata.displayName.isEmpty)
        XCTAssertFalse(metadata.description.isEmpty)
    }

    func testLocalizationCatalogIsPackaged() {
        XCTAssertNotNil(OpenRemotePluginLocalization.bundle.url(forResource: "Localizable", withExtension: "xcstrings"))
        XCTAssertFalse(OpenRemotePluginLocalization.string("Open Remote").isEmpty)
        XCTAssertFalse(OpenRemotePluginLocalization.string("Open in Browser").isEmpty)
    }

    @MainActor
    func testToolbarContributionIsAvailable() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp/repo"), isGitRepository: true)
        XCTAssertFalse(OpenRemotePlugin.toolbarTrailingItems(context: context).isEmpty)
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
