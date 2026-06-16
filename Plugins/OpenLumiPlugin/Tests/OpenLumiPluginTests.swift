import XCTest
import GitOKCoreKit
import SwiftUI
@testable import OpenLumiPlugin

final class LumiConfigurationTests: XCTestCase {

    func testDefaultConfigurationHasCorrectBundleIdentifier() {
        let config = LumiApplicationConfiguration()
        XCTAssertEqual(config.bundleIdentifier, "com.coffic.lumi")
    }

    func testDefaultConfigurationIncludesSystemApplicationsPath() {
        let config = LumiApplicationConfiguration()
        XCTAssertTrue(config.fallbackApplicationPaths.contains("/Applications/Lumi.app"))
    }
}

final class OpenLumiPluginMetadataTests: XCTestCase {

    func testPluginMetadataIsStable() {
        let metadata = OpenLumiPlugin.metadata

        XCTAssertEqual(metadata.id, "OpenLumi")
        XCTAssertEqual(metadata.iconName, "sun.max.fill")
        XCTAssertEqual(metadata.order, 8399)
        XCTAssertEqual(metadata.policy, .optIn)
    }

    @MainActor
    func testToolbarReturnsItemWhenProjectURLExists() {
        let context = GitOKPluginContext(projectURL: URL(fileURLWithPath: "/tmp"))
        let items = OpenLumiPlugin.toolbarTrailingItems(context: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "OpenLumi")
    }
}
