import XCTest
@testable import ProjectsPlugin

final class ProjectsPluginTests: XCTestCase {
    func testMetadata() {
        XCTAssertEqual(ProjectsPlugin.metadata.id, "ProjectsPlugin")
    }
}
