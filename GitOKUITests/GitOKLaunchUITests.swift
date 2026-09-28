import Foundation
import XCTest

final class GitOKLaunchUITests: GitOKUITestCase {
    func testLaunchShowsMainWindowAndReadyRoot() {
        XCTAssertTrue(app.windows["GitOK"].exists, "GitOK's main window is not visible")
        XCTAssertTrue(element(identifier: "gitok.main.ready").exists)
        XCTAssertTrue(element(identifier: "gitok.git.branch.switcher").exists)
        XCTAssertTrue(element(identifier: "gitok.settings.button").exists)
    }

    func testLaunchShowsSettingsAndSceneControls() {
        XCTAssertTrue(
            element(identifier: "gitok.settings.button").waitForExistence(timeout: 10),
            "The toolbar settings control is missing"
        )
        XCTAssertTrue(
            element(identifier: "gitok.projects.add").waitForExistence(timeout: 10),
            "The add-project control is missing"
        )
        XCTAssertTrue(
            element(identifier: "gitok.projects.clone").waitForExistence(timeout: 10),
            "The clone-repository control is missing"
        )
        XCTAssertTrue(
            element(identifier: "gitok.workspace.scene.switcher").waitForExistence(timeout: 10),
            "The workspace scene switcher is missing"
        )
    }
}
import Foundation
import XCTest
