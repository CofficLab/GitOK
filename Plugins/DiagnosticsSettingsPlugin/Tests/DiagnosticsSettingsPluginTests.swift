import XCTest
@testable import DiagnosticsSettingsPlugin

final class DiagnosticsSettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(DiagnosticsSettingsPlugin.metadata.id, "DiagnosticsSettingsPlugin")
    }
}
