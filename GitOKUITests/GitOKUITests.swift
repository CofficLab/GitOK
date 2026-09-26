import XCTest

/// Shared app launch and accessibility lookup for GitOK's macOS UI tests.
class GitOKUITestCase: XCTestCase {
    var app: XCUIApplication!
    private var fixtureRoot: URL!
    var repositoryURL: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        fixtureRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKUITests-\(UUID().uuidString)", isDirectory: true)
        repositoryURL = fixtureRoot.appendingPathComponent("Repository", isDirectory: true)
        try FileManager.default.createDirectory(at: repositoryURL, withIntermediateDirectories: true)
        try createRepositoryFixture()
        try seedProjectStore()

        app = XCUIApplication()
        app.launchArguments += ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["GITOK_UI_TEST_DATA_ROOT"] = fixtureRoot
            .appendingPathComponent("Data", isDirectory: true).path
        app.launch()

        XCTAssertTrue(
            element(identifier: "gitok.main.ready").waitForExistence(timeout: 30),
            "GitOK did not finish assembling its main window"
        )
        XCTAssertFalse(
            element(identifier: "gitok.startup-error").exists,
            "GitOK displayed its startup error view"
        )
        XCTAssertTrue(
            element(identifier: "gitok.git.branch.switcher").waitForExistence(timeout: 20),
            "The isolated fixture project was not restored into the Git workspace"
        )
    }

    override func tearDownWithError() throws {
        if let app, app.state != .notRunning {
            app.terminate()
        }
        if let fixtureRoot {
            try? FileManager.default.removeItem(at: fixtureRoot)
        }
        try super.tearDownWithError()
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

    func waitForLabel(_ element: XCUIElement, toEqual label: String, timeout: TimeInterval = 10) -> Bool {
        waitForPredicate(NSPredicate(format: "label == %@", label), on: element, timeout: timeout)
    }

    func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        waitForPredicate(NSPredicate(format: "isEnabled == true"), on: element, timeout: timeout)
    }

    func waitForPredicate(_ predicate: NSPredicate, on element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func gitOutput(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", repositoryURL.path] + arguments
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitOKUITests.GitFixture", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message])
        }
        return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func createRepositoryFixture() throws {
        try runGit(["init", "--quiet", "--initial-branch=main", repositoryURL.path])
        try runGit(["config", "user.name", "GitOK UI Test"])
        try runGit(["config", "user.email", "gitok-ui-tests@example.invalid"])

        let trackedFile = repositoryURL.appendingPathComponent("tracked.txt")
        try Data("initial content\n".utf8).write(to: trackedFile)
        try runGit(["add", "tracked.txt"])
        try runGit(["commit", "--quiet", "-m", "Initial fixture commit"])

        try Data("modified by the UI test\n".utf8).write(to: trackedFile)
        try Data("untracked fixture file\n".utf8)
            .write(to: repositoryURL.appendingPathComponent("untracked.txt"))
    }

    private func seedProjectStore() throws {
        let projectID = UUID()
        let storeDirectory = fixtureRoot
            .appendingPathComponent("Data", isDirectory: true)
            .appendingPathComponent("com.coffic.gitok.plugin.projects", isDirectory: true)
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

        let store = UITestProjectStore(
            projects: [UITestProject(id: projectID, url: repositoryURL, title: "GitOK UI Fixture", isPinned: false)],
            currentProjectID: projectID
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(store).write(to: storeDirectory.appendingPathComponent("projects.json"), options: .atomic)
    }

    private func runGit(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments.first == "init"
            ? arguments
            : ["-C", repositoryURL.path] + arguments
        let error = Pipe()
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitOKUITests.GitFixture", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}

private struct UITestProjectStore: Encodable {
    let projects: [UITestProject]
    let currentProjectID: UUID?
}

private struct UITestProject: Encodable {
    let id: UUID
    let url: URL
    let title: String
    let isPinned: Bool
    let lastOpenedAt: Date? = nil
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
        XCTAssertTrue(
            app.staticTexts["Banner Editor"].waitForExistence(timeout: 10),
            "The Banner workspace did not show its editor"
        )

        let switcher = element(identifier: "gitok.workspace.scene.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        XCTAssertTrue(switcher.label.localizedCaseInsensitiveContains("Banner"))

        switcher.click()
        let icon = element(identifier: "gitok.workspace.scene.option.icon")
        XCTAssertTrue(icon.waitForExistence(timeout: 5))
        icon.click()
        XCTAssertTrue(
            app.staticTexts["Icon Editor"].waitForExistence(timeout: 10),
            "The Icon workspace did not show its editor"
        )
        XCTAssertTrue(
            element(identifier: "gitok.workspace.scene.switcher").label.localizedCaseInsensitiveContains("Icon")
        )
    }
}

final class GitOKGitWorkflowUITests: GitOKUITestCase {
    func testSelectingWorkingTreeFileOpensItsDiff() {
        let file = element(identifier: "gitok.worktree.file.tracked.txt")
        XCTAssertTrue(file.waitForExistence(timeout: 15), "The modified fixture file is missing from Changes")
        file.click()

        let diffFile = element(identifier: "gitok.git.diff.file")
        XCTAssertTrue(diffFile.waitForExistence(timeout: 15), "Selecting the changed file did not open its diff")
        XCTAssertEqual(diffFile.label, "tracked.txt")
        XCTAssertTrue(element(identifier: "gitok.git.diff.panel").exists)
    }

    func testStageAndUnstageWorkingTreeChange() {
        let status = element(identifier: "gitok.worktree.status.tracked.txt")
        XCTAssertTrue(status.waitForExistence(timeout: 15), "The modified fixture file is missing from Changes")
        XCTAssertTrue(waitForLabel(status, toEqual: "Not Staged"), "The fixture change should start unstaged")

        let stage = element(identifier: "gitok.worktree.stage.tracked.txt")
        XCTAssertTrue(stage.waitForExistence(timeout: 5), "The Stage action is missing")
        stage.click()
        XCTAssertTrue(waitForLabel(status, toEqual: "Staged"), "Staging did not update the worktree row")

        let unstage = element(identifier: "gitok.worktree.unstage.tracked.txt")
        XCTAssertTrue(unstage.waitForExistence(timeout: 5), "The Unstage action is missing")
        unstage.click()
        XCTAssertTrue(waitForLabel(status, toEqual: "Not Staged"), "Unstaging did not restore the worktree state")
    }

    func testCommitButtonCreatesCommitFromStagedChange() throws {
        let stage = element(identifier: "gitok.worktree.stage.tracked.txt")
        XCTAssertTrue(stage.waitForExistence(timeout: 15), "The fixture change is missing from Changes")
        stage.click()
        XCTAssertTrue(
            waitForLabel(element(identifier: "gitok.worktree.status.tracked.txt"), toEqual: "Staged"),
            "The fixture change did not stage"
        )

        let subject = element(identifier: "gitok.commit.subject")
        XCTAssertTrue(subject.waitForExistence(timeout: 10), "The commit subject field is missing")
        let marker = "ui-\(UUID().uuidString)"
        subject.click()
        subject.typeText("Commit \(marker)")

        let commit = element(identifier: "gitok.commit.submit")
        XCTAssertTrue(commit.waitForExistence(timeout: 5), "The Commit action is missing")
        XCTAssertTrue(commit.isEnabled, "Commit should be enabled after entering a message")
        commit.click()

        let deadline = Date().addingTimeInterval(15)
        var latestSubject = ""
        while Date() < deadline {
            latestSubject = try gitOutput(["log", "-1", "--format=%s"])
            if latestSubject.contains(marker) { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(latestSubject.contains(marker), "Commit did not write the submitted message to Git")
    }

    func testBranchPickerCreatesAndChecksOutBranch() throws {
        let switcher = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 15), "The branch picker is missing")
        XCTAssertTrue(waitUntilEnabled(switcher), "The current branch did not finish loading")
        switcher.click()

        let createToggle = element(identifier: "gitok.git.branch.create.toggle")
        XCTAssertTrue(createToggle.waitForExistence(timeout: 5), "The new-branch control is missing")
        XCTAssertTrue(waitUntilEnabled(createToggle), "The branch list did not finish loading")
        createToggle.click()

        let name = "ui-\(UUID().uuidString.prefix(8))"
        let nameField = element(identifier: "gitok.git.branch.new-name")
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "The branch-name field is missing")
        nameField.typeText(name)

        let create = element(identifier: "gitok.git.branch.create")
        XCTAssertTrue(waitUntilEnabled(create), "A non-empty branch name should enable Create")
        create.click()

        let currentBranch = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "label CONTAINS %@", name), on: currentBranch, timeout: 15),
            "Creating the branch did not update the toolbar"
        )
        XCTAssertEqual(try gitOutput(["branch", "--show-current"]), name)
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
