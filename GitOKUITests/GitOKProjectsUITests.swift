import Foundation
import XCTest

final class GitOKProjectsUITests: GitOKUITestCase {
    func testAddProjectOpensFolderPickerAndCanBeCancelled() {
        let addButton = element(identifier: "gitok.projects.add")
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "Add-project control is missing")
        addButton.click()

        let picker = app.dialogs.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10), "Add Project did not open a folder picker")
        let cancelButton = picker.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Folder picker has no Cancel action")
        cancelButton.click()
        XCTAssertFalse(picker.waitForExistence(timeout: 1), "Cancelling folder selection should close the picker")
    }
}
import Foundation
import XCTest
