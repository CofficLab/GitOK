import Foundation
import XCTest

final class GitOKCloneRepositoryUITests: GitOKUITestCase {
    func testCloneSheetValidatesRequiredFieldsAndDerivesRepositoryName() {
        let cloneButton = element(identifier: "gitok.projects.clone")
        XCTAssertTrue(cloneButton.waitForExistence(timeout: 10))
        cloneButton.click()

        XCTAssertTrue(
            element(identifier: "gitok.clone.sheet").waitForExistence(timeout: 5),
            "Clone repository form did not appear"
        )

        let submit = app.buttons.matching(NSPredicate(format: "label == %@", "Clone")).firstMatch
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertFalse(submit.isEnabled, "Clone should stay disabled until required values are valid")

        let remoteField = element(identifier: "gitok.clone.remote-url")
        XCTAssertTrue(remoteField.waitForExistence(timeout: 5), "Remote URL field is missing")
        replaceText(in: remoteField, with: "https://github.com/example/sample-repo.git")

        let nameField = element(identifier: "gitok.clone.repository-name")
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "value == %@", "sample-repo"), on: nameField, timeout: 5),
            "Repository name was not derived from the remote URL"
        )

        replaceText(in: nameField, with: "sample-repo-ui-\(UUID().uuidString)")
        XCTAssertTrue(submit.isEnabled, "A unique valid destination should enable Clone")

        app.buttons["Cancel"].click()
        XCTAssertFalse(element(identifier: "gitok.clone.sheet").exists, "Cancel should dismiss the clone form")
    }

    func testCloneSheetClonesLocalRepositoryIntoProjects() throws {
        let remoteURL = fixtureRootURL.appendingPathComponent("remote.git", isDirectory: true)
        _ = try gitOutput(["clone", "--bare", ".", remoteURL.path])

        let repositoryName = "gitok-ui-clone-\(UUID().uuidString)"
        let destinationURL = fixtureRootURL
            .appendingPathComponent(repositoryName, isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destinationURL.path))

        element(identifier: "gitok.projects.clone").click()
        let remoteField = element(identifier: "gitok.clone.remote-url")
        XCTAssertTrue(remoteField.waitForExistence(timeout: 5))
        replaceText(in: remoteField, with: remoteURL.absoluteString)
        let nameField = element(identifier: "gitok.clone.repository-name")
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "The clone destination name field is missing")
        replaceText(in: nameField, with: repositoryName)

        let clone = app.buttons.matching(NSPredicate(format: "label == %@", "Clone")).firstMatch
        XCTAssertTrue(waitUntilEnabled(clone), "A valid local repository clone should be allowed")
        clone.click()
        XCTAssertFalse(element(identifier: "gitok.clone.sheet").waitForExistence(timeout: 2))

        let deadline = Date().addingTimeInterval(30)
        var clonedRoot: String?
        while Date() < deadline {
            clonedRoot = try? gitOutput(["rev-parse", "--show-toplevel"], in: destinationURL)
            if clonedRoot != nil { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTAssertEqual(clonedRoot, destinationURL.path, "The clone task did not create a working repository")
        XCTAssertEqual(try gitOutput(["branch", "--show-current"], in: destinationURL), "main")
        XCTAssertEqual(try gitOutput(["remote", "get-url", "origin"], in: destinationURL), remoteURL.absoluteString)
    }

    func testCloneDestinationPickerCanBeCancelled() {
        element(identifier: "gitok.projects.clone").click()
        let chooseDestination = element(identifier: "gitok.clone.destination.choose")
        XCTAssertTrue(chooseDestination.waitForExistence(timeout: 5))
        chooseDestination.click()

        let folderPicker = app.dialogs.firstMatch
        XCTAssertTrue(folderPicker.waitForExistence(timeout: 10), "Destination folder picker did not open")
        let cancel = folderPicker.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Destination folder picker has no Cancel action")
        cancel.click()

        XCTAssertTrue(
            element(identifier: "gitok.clone.sheet").waitForExistence(timeout: 5),
            "Cancelling the folder picker should keep the clone form open"
        )
    }
}
import Foundation
import XCTest
