import XCTest

/// Shared app launch and accessibility lookup for GitOK's macOS UI tests.
class GitOKUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        XCTAssertTrue(
            element(identifier: "gitok.main.ready").waitForExistence(timeout: 30),
            "GitOK did not finish assembling its main window"
        )
        XCTAssertFalse(
            element(identifier: "gitok.startup-error").exists,
            "GitOK displayed its startup error view"
        )
    }

    func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @discardableResult
    func openSettings() -> XCUIElement {
        let button = element(identifier: "gitok.settings.button")
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Toolbar settings button is missing")
        button.click()

        let settings = element(identifier: "gitok.settings.ready")
        XCTAssertTrue(settings.waitForExistence(timeout: 15), "Settings window did not open")
        return settings
    }
}

final class GitOKLaunchUITests: GitOKUITestCase {
    func testLaunchShowsMainWindowAndReadyRoot() {
        XCTAssertTrue(app.windows["GitOK"].exists, "GitOK's main window is not visible")
        XCTAssertTrue(element(identifier: "gitok.main.ready").exists)
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

        let remoteField = app.textFields["https://github.com/owner/repo.git"]
        XCTAssertTrue(remoteField.waitForExistence(timeout: 5), "Remote URL field is missing")
        remoteField.click()
        remoteField.typeText("https://github.com/example/sample-repo.git")

        XCTAssertTrue(
            app.textFields.matching(NSPredicate(format: "value == %@", "sample-repo")).firstMatch.exists,
            "Repository name was not derived from the remote URL"
        )

        let nameField = app.textFields.matching(NSPredicate(format: "value == %@", "sample-repo")).firstMatch
        nameField.click()
        nameField.typeKey("a", modifierFlags: .command)
        nameField.typeText("sample-repo-ui-\(UUID().uuidString)")
        XCTAssertTrue(submit.isEnabled, "A unique valid destination should enable Clone")

        app.buttons["Cancel"].click()
        XCTAssertFalse(element(identifier: "gitok.clone.sheet").exists, "Cancel should dismiss the clone form")
    }
}

final class GitOKWorkspaceUITests: GitOKUITestCase {
    func testScenePickerListsGitBannerAndIconWorkspaces() {
        let switcher = element(identifier: "gitok.workspace.scene.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        switcher.click()

        for scene in ["git", "banner", "icon"] {
            XCTAssertTrue(
                element(identifier: "gitok.workspace.scene.option.\(scene)").waitForExistence(timeout: 5),
                "Scene picker is missing the \(scene) workspace"
            )
        }
    }

    func testSelectingSceneUpdatesToolbarAndClosesPicker() {
        element(identifier: "gitok.workspace.scene.switcher").click()

        let banner = element(identifier: "gitok.workspace.scene.option.banner")
        XCTAssertTrue(banner.waitForExistence(timeout: 5), "Banner workspace option is missing")
        banner.click()

        let switcher = element(identifier: "gitok.workspace.scene.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        XCTAssertTrue(switcher.label.localizedCaseInsensitiveContains("Banner"))

        switcher.click()
        let icon = element(identifier: "gitok.workspace.scene.option.icon")
        XCTAssertTrue(icon.waitForExistence(timeout: 5))
        icon.click()
        XCTAssertTrue(
            element(identifier: "gitok.workspace.scene.switcher").label.localizedCaseInsensitiveContains("Icon")
        )
    }
}

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

final class GitOKSettingsUITests: GitOKUITestCase {
    private let settingsEntryIDs = [
        "general",
        "plugin-manager",
        "repository",
        "userInfo",
        "commitStyle",
        "network",
        "diagnostics",
        "about",
    ]

    private func selectSettingsEntry(_ entryID: String) {
        let entry = element(identifier: "settings.entry.\(entryID)")
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "Settings section \(entryID) is missing")

        // Walk the settings sidebar as rows move below the visible part of the window.
        let settingsWindow = app.windows.element(boundBy: 1)
        for _ in 0..<8 where !entry.isHittable {
            let sidebar = settingsWindow.scrollViews.firstMatch
            guard sidebar.exists else { break }
            sidebar.swipeUp()
        }
        XCTAssertTrue(entry.isHittable, "Settings section \(entryID) is not reachable")
        entry.click()
        XCTAssertTrue(
            element(identifier: "settings.detail.\(entryID)").waitForExistence(timeout: 5),
            "Settings detail for \(entryID) did not load after selection"
        )
    }

    func testToolbarButtonOpensSettingsWindow() {
        _ = openSettings()
        XCTAssertTrue(app.windows.count >= 2, "Opening settings should show a dedicated window")
    }

    func testSettingsSidebarContainsRegisteredSections() {
        _ = openSettings()

        for entryID in settingsEntryIDs {
            XCTAssertTrue(
                element(identifier: "settings.entry.\(entryID)").waitForExistence(timeout: 5),
                "Settings sidebar is missing the \(entryID) section"
            )
        }
    }

    func testSettingsSectionsCanBeSelected() {
        _ = openSettings()

        for entryID in settingsEntryIDs {
            selectSettingsEntry(entryID)
        }
    }

    func testSettingsKeyboardShortcutOpensSettingsWindow() {
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(
            element(identifier: "gitok.settings.ready").waitForExistence(timeout: 10),
            "Command-comma did not open the settings window"
        )
    }
}
