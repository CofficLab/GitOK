import XCTest
@testable import GitUserSettingsPlugin

final class GitUserSettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(GitUserSettingsPlugin.metadata.id, "GitUserSettingsPlugin")
    }
}
