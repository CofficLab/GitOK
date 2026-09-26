import XCTest
@testable import ProviderProjects

@MainActor
final class ProjectRenameErrorTests: XCTestCase {
    func testErrorDescriptions() {
        XCTAssertEqual(ProjectRenameError.invalidName.errorDescription,
                       "Project name must be non-empty and must not contain \"/\".")
        XCTAssertEqual(ProjectRenameError.targetExists.errorDescription,
                       "A folder with this name already exists.")
        XCTAssertEqual(ProjectRenameError.moveFailed("disk full").errorDescription,
                       "Failed to rename the project folder: disk full")
    }

    func testErrorEquality() {
        XCTAssertEqual(ProjectRenameError.invalidName, ProjectRenameError.invalidName)
        XCTAssertEqual(ProjectRenameError.targetExists, ProjectRenameError.targetExists)
        XCTAssertEqual(ProjectRenameError.moveFailed("a"), ProjectRenameError.moveFailed("a"))
        XCTAssertNotEqual(ProjectRenameError.moveFailed("a"), ProjectRenameError.moveFailed("b"))
    }
}
