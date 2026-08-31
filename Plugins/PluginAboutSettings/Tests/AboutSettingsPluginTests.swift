import XCTest
@testable import AboutSettingsPlugin

final class AboutSettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(AboutSettingsPlugin.metadata.id, "AboutSettingsPlugin")
    }
}
