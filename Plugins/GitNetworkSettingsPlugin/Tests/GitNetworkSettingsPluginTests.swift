import XCTest
@testable import GitNetworkSettingsPlugin

final class GitNetworkSettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(GitNetworkSettingsPlugin.metadata.id, "GitNetworkSettingsPlugin")
    }
}
