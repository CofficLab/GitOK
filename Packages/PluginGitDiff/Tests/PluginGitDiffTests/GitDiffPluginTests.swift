import Foundation
import XCTest
@testable import PluginGitDiff

@MainActor
final class GitDiffPluginTests: XCTestCase {
    func testPluginMetadata() {
        let plugin = GitDiffPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.git-diff")
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.description.isEmpty)
    }
}
