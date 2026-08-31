import XCTest
@testable import GitCommitStyleSettingsPlugin

final class GitCommitStyleSettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(GitCommitStyleSettingsPlugin.metadata.id, "GitCommitStyleSettingsPlugin")
    }
}
