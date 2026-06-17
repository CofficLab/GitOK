import XCTest
@testable import GitRepositorySettingsPlugin

final class GitRepositorySettingsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(GitRepositorySettingsPlugin.metadata.id, "GitRepositorySettingsPlugin")
    }
}
