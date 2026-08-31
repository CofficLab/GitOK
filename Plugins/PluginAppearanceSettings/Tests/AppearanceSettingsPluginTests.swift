import XCTest
@testable import AppearanceSettingsPlugin

final class AppearanceSettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(AppearanceSettingsPlugin.metadata.id, "AppearanceSettingsPlugin")
    }
}
