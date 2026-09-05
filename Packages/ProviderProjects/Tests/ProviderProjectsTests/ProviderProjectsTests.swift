import XCTest
@testable import ProviderProjects

@MainActor
final class ProviderProjectsTests: XCTestCase {
    func testProjectDefaultsToDirectoryName() {
        let project = Project(url: URL(fileURLWithPath: "/tmp/MyRepo"))
        XCTAssertEqual(project.title, "MyRepo")
        XCTAssertFalse(project.isPinned)
        XCTAssertNil(project.lastOpenedAt)
    }

    func testProjectCodableRoundTrip() throws {
        let project = Project(
            url: URL(fileURLWithPath: "/tmp/MyRepo"),
            title: "MyRepo",
            isPinned: true,
            lastOpenedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        XCTAssertEqual(decoded, project)
    }
}
