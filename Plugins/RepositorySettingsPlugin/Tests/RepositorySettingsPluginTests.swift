import XCTest
@testable import RepositorySettingsPlugin

final class RepositorySettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(RepositorySettingsPlugin.metadata.id, "RepositorySettingsPlugin")
    }
}
