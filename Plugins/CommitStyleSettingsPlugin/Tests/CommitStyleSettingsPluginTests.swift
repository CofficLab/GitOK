import XCTest
@testable import CommitStyleSettingsPlugin

final class CommitStyleSettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(CommitStyleSettingsPlugin.metadata.id, "CommitStyleSettingsPlugin")
    }
}
