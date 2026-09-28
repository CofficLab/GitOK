import AppKit
import XCTest

/// Shared app launch and accessibility lookup for GitOK's macOS UI tests.
class GitOKUITestCase: XCTestCase {
    var app: XCUIApplication!
    private var fixtureRoot: URL!
    var fixtureRootURL: URL { fixtureRoot }
    var repositoryURL: URL!
    var hasWorkingTreeChanges: Bool { true }
    var fixtureProjectTitle: String { "GitOK UI Fixture" }
    var uiTestLanguage: String { "en" }
    var uiTestLocale: String { "en_US" }
    var expectsReadyGitWorkbench: Bool { true }

    override func setUpWithError() throws {
        continueAfterFailure = false
        fixtureRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKUITests-\(UUID().uuidString)", isDirectory: true)
        repositoryURL = fixtureRoot.appendingPathComponent("Repository", isDirectory: true)
        try FileManager.default.createDirectory(at: repositoryURL, withIntermediateDirectories: true)
        try createRepositoryFixture()
        try seedProjectStore()
        try seedAdditionalUIState()

        app = XCUIApplication()
        app.launchArguments += [
            "--ui-testing",
            "-AppleLanguages", "(\(uiTestLanguage))",
            "-AppleLocale", uiTestLocale,
        ]
        app.launchEnvironment["GITOK_UI_TEST_DATA_ROOT"] = fixtureRoot
            .appendingPathComponent("Data", isDirectory: true).path
        app.launchEnvironment["GITOK_UI_TEST_CLONE_DESTINATION"] = fixtureRoot.path
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
            app.buttons.matching(NSPredicate(format: "label == %@", fixtureProjectTitle))
                .firstMatch.waitForExistence(timeout: 20),
            "The isolated fixture project was not restored into the project list"
        )
        if expectsReadyGitWorkbench {
            XCTAssertTrue(
                element(identifier: "gitok.git.branch.switcher").waitForExistence(timeout: 20),
                "The Git toolbar did not expose its branch switcher"
            )
        }
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

    func replaceText(in element: XCUIElement, with value: String) {
        element.click()
        element.typeKey("a", modifierFlags: .command)
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.pasteboardItems?.map { item in
            item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            }
        } ?? []
        defer {
            pasteboard.clearContents()
            let restoredItems = previousContents.map { contents in
                let item = NSPasteboardItem()
                contents.forEach { item.setData($0.1, forType: $0.0) }
                return item
            }
            if !restoredItems.isEmpty {
                pasteboard.writeObjects(restoredItems)
            }
        }
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        app.typeKey("v", modifierFlags: .command)
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
        waitForPredicate(NSPredicate(format: "value == %@", label), on: element, timeout: timeout)
    }

    func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        waitForPredicate(NSPredicate(format: "isEnabled == true"), on: element, timeout: timeout)
    }

    func waitForPredicate(_ predicate: NSPredicate, on element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func gitOutput(_ arguments: [String], in repository: URL? = nil) throws -> String {
        let process = Process()
        process.executableURL = gitExecutableURL
        process.arguments = ["-C", (repository ?? repositoryURL).path] + arguments
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

        if hasWorkingTreeChanges {
            try Data("modified by the UI test\n".utf8).write(to: trackedFile)
            try Data("untracked fixture file\n".utf8)
                .write(to: repositoryURL.appendingPathComponent("untracked.txt"))
        }
    }

    func additionalProjectFixtures() throws -> [UITestProject] { [] }

    func seedAdditionalUIState() throws {}

    private func seedProjectStore() throws {
        let projectID = UUID()
        let storeDirectory = fixtureRoot
            .appendingPathComponent("Data", isDirectory: true)
            .appendingPathComponent("com.coffic.gitok.plugin.projects", isDirectory: true)
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        let additionalProjects = try additionalProjectFixtures()

        let store = UITestProjectStore(
            projects: [UITestProject(id: projectID, url: repositoryURL, title: fixtureProjectTitle, isPinned: false)]
                + additionalProjects,
            currentProjectID: projectID
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(store).write(to: storeDirectory.appendingPathComponent("projects.json"), options: .atomic)
    }

    private func runGit(_ arguments: [String]) throws {
        try runGit(arguments, in: repositoryURL)
    }

    func createCleanRepository(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try runGit(["init", "--quiet", "--initial-branch=main", url.path], in: url)
        try runGit(["config", "user.name", "GitOK UI Test"], in: url)
        try runGit(["config", "user.email", "gitok-ui-tests@example.invalid"], in: url)
        try Data("initial content\n".utf8).write(to: url.appendingPathComponent("tracked.txt"))
        try runGit(["add", "tracked.txt"], in: url)
        try runGit(["commit", "--quiet", "-m", "Initial fixture commit"], in: url)
    }

    private func runGit(_ arguments: [String], in repository: URL) throws {
        let process = Process()
        process.executableURL = gitExecutableURL
        process.arguments = arguments.first == "init"
            ? arguments
            : ["-C", repository.path] + arguments
        let error = Pipe()
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitOKUITests.GitFixture", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private var gitExecutableURL: URL {
        let developerDirectory = ProcessInfo.processInfo.environment["DEVELOPER_DIR"]
            ?? "/Applications/Xcode.app/Contents/Developer"
        let xcodeGit = URL(fileURLWithPath: developerDirectory)
            .appendingPathComponent("usr/bin/git")
        if FileManager.default.isExecutableFile(atPath: xcodeGit.path) {
            return xcodeGit
        }
        return URL(fileURLWithPath: "/usr/bin/git")
    }
}

struct UITestProjectStore: Encodable {
    let projects: [UITestProject]
    let currentProjectID: UUID?
}

struct UITestProject: Encodable {
    let id: UUID
    let url: URL
    let title: String
    let isPinned: Bool
    let lastOpenedAt: Date? = nil
}

struct UITestCloneTaskStore: Encodable {
    let tasks: [UITestCloneTask]
}

struct UITestCloneTask: Encodable {
    let id: UUID
    let remoteURL: String
    let destination: URL
    let repositoryName: String
    let status: String
    let phase: String?
    let fractionCompleted: Double?
    let detail: String?
    let errorMessage: String?
    let createdAt: Date
    let updatedAt: Date
    let startedAt: Date?
    let finishedAt: Date?
}

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

struct GitOKLocalizationExpectation {
    let addProject: String
    let cloneRepository: String
    let clone: String
    let cloneHeading: String
    let cloneDescription: String
    let remoteURL: String
    let destination: String
    let chooseDestination: String
    let repositoryName: String
    let untracked: String
    let search: String
    let newBranchName: String
    let createBranch: String
    let openSettings: String
    let general: String
    let cancel: String
}

class GitOKLocalizationUITestCase: GitOKUITestCase {
    var expectedLocalization: GitOKLocalizationExpectation { fatalError("Override per language") }

    private func staticText(matching text: String) -> XCUIElement {
        app.staticTexts.matching(
            NSPredicate(format: "label == %@ OR value == %@", text, text)
        ).firstMatch
    }

    func assertKeySurfacesUseExpectedLocalization() {
        let expected = expectedLocalization

        let addProject = element(identifier: "gitok.projects.add")
        XCTAssertTrue(addProject.waitForExistence(timeout: 10))
        XCTAssertEqual(addProject.label, expected.addProject)

        let cloneRepository = app.buttons.matching(identifier: "gitok.projects.clone").firstMatch
        XCTAssertEqual(cloneRepository.label, expected.cloneRepository)
        cloneRepository.click()

        for text in [expected.cloneHeading, expected.cloneDescription, expected.remoteURL, expected.destination] {
            XCTAssertTrue(staticText(matching: text).waitForExistence(timeout: 5), "Missing localized clone-form text: \(text)")
        }
        let destinationPicker = element(identifier: "gitok.clone.destination.choose")
        XCTAssertEqual(destinationPicker.label, expected.chooseDestination)
        let repositoryName = element(identifier: "gitok.clone.repository-name")
        XCTAssertEqual(repositoryName.placeholderValue, expected.repositoryName)
        let clone = app.buttons.matching(NSPredicate(format: "label == %@", expected.clone)).firstMatch
        XCTAssertTrue(clone.waitForExistence(timeout: 5))
        XCTAssertFalse(clone.isEnabled, "Clone should remain disabled until required values are valid")
        app.buttons[expectedLocalization.cancel].click()

        let untracked = element(identifier: "gitok.worktree.status.untracked.txt")
        XCTAssertTrue(untracked.waitForExistence(timeout: 10))
        XCTAssertEqual(untracked.value as? String, expected.untracked)

        element(identifier: "gitok.git.branch.switcher").click()
        let branchSearch = element(identifier: "gitok.git.branch.search")
        XCTAssertTrue(branchSearch.waitForExistence(timeout: 5))
        XCTAssertEqual(branchSearch.placeholderValue, expected.search)
        element(identifier: "gitok.git.branch.create.toggle").click()
        let newBranchName = element(identifier: "gitok.git.branch.new-name")
        XCTAssertTrue(newBranchName.waitForExistence(timeout: 5))
        XCTAssertEqual(newBranchName.placeholderValue, expected.newBranchName)
        let createBranch = element(identifier: "gitok.git.branch.create")
        XCTAssertEqual(createBranch.label, expected.createBranch)

        _ = openSettings()
        let settingsButton = app.buttons.matching(identifier: "gitok.settings.button").firstMatch
        XCTAssertEqual(settingsButton.label, expected.openSettings)
        let general = element(identifier: "settings.entry.general")
        XCTAssertTrue(general.waitForExistence(timeout: 5))
        XCTAssertTrue(
            general.label == expected.general || (general.value as? String) == expected.general,
            "General settings section was not localized: label=\(general.label), value=\(general.value ?? "nil")"
        )
    }
}

final class GitOKEnglishLocalizationUITests: GitOKLocalizationUITestCase {
    override var uiTestLanguage: String { "en" }
    override var uiTestLocale: String { "en_US" }
    override var expectedLocalization: GitOKLocalizationExpectation {
        GitOKLocalizationExpectation(
            addProject: "Add Project",
            cloneRepository: "Clone Repository",
            clone: "Clone",
            cloneHeading: "Clone Repository",
            cloneDescription: "Clone a remote repository and add it to your projects.",
            remoteURL: "Remote URL",
            destination: "Destination",
            chooseDestination: "Choose...",
            repositoryName: "Repository name",
            untracked: "Untracked",
            search: "Search",
            newBranchName: "New branch name",
            createBranch: "Create",
            openSettings: "Open Settings",
            general: "General",
            cancel: "Cancel"
        )
    }

    func testEnglishLocaleShowsEnglishAcrossMainGitCloneAndSettings() {
        assertKeySurfacesUseExpectedLocalization()
    }
}

final class GitOKChineseLocalizationUITests: GitOKLocalizationUITestCase {
    override var uiTestLanguage: String { "zh-Hans" }
    override var uiTestLocale: String { "zh_CN" }
    override var expectedLocalization: GitOKLocalizationExpectation {
        GitOKLocalizationExpectation(
            addProject: "添加项目",
            cloneRepository: "克隆仓库",
            clone: "克隆",
            cloneHeading: "克隆仓库",
            cloneDescription: "克隆远程仓库并将其添加到项目中。",
            remoteURL: "远程 URL",
            destination: "目标位置",
            chooseDestination: "选择…",
            repositoryName: "仓库名称",
            untracked: "未跟踪",
            search: "搜索",
            newBranchName: "新分支名称",
            createBranch: "创建",
            openSettings: "打开设置",
            general: "通用",
            cancel: "取消"
        )
    }

    func testChineseLocaleShowsChineseAcrossMainGitCloneAndSettings() {
        assertKeySurfacesUseExpectedLocalization()
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

class GitOKCloneFailureFixtureTestCase: GitOKUITestCase {
    let kuzeeRemoteURL = "https://github.com/CofficLab/Kuzee.git"
    var shouldSeedExternalClone: Bool { false }

    override var expectsReadyGitWorkbench: Bool { false }

    override var fixtureProjectTitle: String { "Kuzee" }

    override func additionalProjectFixtures() throws -> [UITestProject] {
        let lumiURL = fixtureRootURL.appendingPathComponent("Lumi", isDirectory: true)
        try createCleanRepository(at: lumiURL)
        return [
            UITestProject(
                id: UUID(),
                url: lumiURL,
                title: "Lumi",
                isPinned: false
            ),
        ]
    }

    override func seedAdditionalUIState() throws {
        if shouldSeedExternalClone {
            _ = try gitOutput(["remote", "add", "origin", kuzeeRemoteURL], in: repositoryURL)
        }

        let cloneDirectory = fixtureRootURL
            .appendingPathComponent("Data", isDirectory: true)
            .appendingPathComponent("com.coffic.gitok.plugin.clone-repository", isDirectory: true)
        try FileManager.default.createDirectory(at: cloneDirectory, withIntermediateDirectories: true)

        let now = Date()
        let task = UITestCloneTask(
            id: UUID(),
            remoteURL: kuzeeRemoteURL,
            destination: repositoryURL,
            repositoryName: "Kuzee",
            status: "failed",
            phase: "checkingOut",
            fractionCompleted: 0.92,
            detail: "Clone failed",
            errorMessage: "remote authentication required but no callback set",
            createdAt: now,
            updatedAt: now,
            startedAt: now,
            finishedAt: now
        )
        let store = UITestCloneTaskStore(tasks: [task])
        try JSONEncoder().encode(store).write(
            to: cloneDirectory.appendingPathComponent("clone-tasks.json"),
            options: .atomic
        )
    }
}

final class GitOKCloneFailureIsolationUITests: GitOKCloneFailureFixtureTestCase {
    func testFailedCloneHidesGitWorkbenchAndRail() {
        XCTAssertTrue(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 15),
            "The seeded Kuzee clone failure was not displayed"
        )

        let railVisible = element(identifier: "gitok.workspace.rail").waitForExistence(timeout: 2)
        let branchSwitcherVisible = element(identifier: "gitok.git.branch.switcher").waitForExistence(timeout: 2)
        let commitFormVisible = element(identifier: "gitok.commit.subject").waitForExistence(timeout: 2)

        XCTAssertFalse(
            railVisible,
            "The RailView is visible even though the current project clone failed"
        )
        XCTAssertFalse(
            branchSwitcherVisible,
            "The Git branch UI is visible even though the current project clone failed"
        )
        XCTAssertFalse(
            commitFormVisible,
            "The commit form is visible even though the current project clone failed"
        )
    }

    func testFailedCloneDetailsDoNotLeakAfterSwitchingProjects() {
        XCTAssertTrue(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 15),
            "The seeded Kuzee clone failure was not displayed"
        )

        let lumi = app.buttons.matching(NSPredicate(format: "label == %@", "Lumi")).firstMatch
        XCTAssertTrue(lumi.waitForExistence(timeout: 10), "The Lumi project row is missing")
        lumi.click()

        XCTAssertFalse(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 2),
            "Kuzee clone details leaked into the Lumi project"
        )
    }
}

final class GitOKExternalCloneReconciliationUITests: GitOKCloneFailureFixtureTestCase {
    override var shouldSeedExternalClone: Bool { true }

    func testExternalCloneShouldClearStaleFailedCloneTask() throws {
        XCTAssertEqual(
            try gitOutput(["rev-parse", "--is-inside-work-tree"], in: repositoryURL),
            "true",
            "The fixture destination should represent a repository cloned outside GitOK"
        )

        XCTAssertFalse(
            app.staticTexts[kuzeeRemoteURL].waitForExistence(timeout: 2),
            "GitOK still shows the stale clone failure after the destination became a valid repository"
        )
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
        XCTAssertEqual(diffFile.value as? String, "tracked.txt")
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

    func testUntrackedFileCanBeStagedAndCommitted() throws {
        let status = element(identifier: "gitok.worktree.status.untracked.txt")
        XCTAssertTrue(status.waitForExistence(timeout: 15), "The untracked fixture file is missing from Changes")
        XCTAssertTrue(waitForLabel(status, toEqual: "Untracked"), "The fixture file should start untracked")

        let stage = element(identifier: "gitok.worktree.stage.untracked.txt")
        XCTAssertTrue(stage.waitForExistence(timeout: 5), "The untracked file has no Stage action")
        stage.click()
        XCTAssertTrue(
            waitForLabel(status, toEqual: "Staged", timeout: 10),
            "Staging the new file did not update its status"
        )
        XCTAssertTrue(try gitOutput(["diff", "--cached", "--name-only"]).contains("untracked.txt"))

        let subject = element(identifier: "gitok.commit.subject")
        XCTAssertTrue(subject.waitForExistence(timeout: 10))
        let marker = "ui-untracked-\(UUID().uuidString)"
        replaceText(in: subject, with: "Add \(marker)")
        let commit = element(identifier: "gitok.commit.submit")
        XCTAssertTrue(waitUntilEnabled(commit), "A staged new file should be committable")
        commit.click()

        let deadline = Date().addingTimeInterval(15)
        var latestSubject = ""
        while Date() < deadline {
            latestSubject = try gitOutput(["log", "-1", "--format=%s"])
            if latestSubject.contains(marker) { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(latestSubject.contains(marker), "The staged new file was not committed")
        XCTAssertEqual(try gitOutput(["ls-tree", "--name-only", "HEAD", "--", "untracked.txt"]), "untracked.txt")
    }

    func testBatchStageAndUnstageSelectedFiles() throws {
        let trackedSelection = element(identifier: "gitok.worktree.select.tracked.txt")
        let untrackedSelection = element(identifier: "gitok.worktree.select.untracked.txt")
        XCTAssertTrue(trackedSelection.waitForExistence(timeout: 15))
        XCTAssertTrue(untrackedSelection.waitForExistence(timeout: 5))
        trackedSelection.click()
        untrackedSelection.click()

        let stage = element(identifier: "gitok.worktree.batch.stage")
        XCTAssertTrue(waitUntilEnabled(stage), "Selecting changed files should enable batch Stage")
        stage.click()
        let trackedStatus = element(identifier: "gitok.worktree.status.tracked.txt")
        let untrackedStatus = element(identifier: "gitok.worktree.status.untracked.txt")
        XCTAssertTrue(waitForLabel(trackedStatus, toEqual: "Staged"))
        XCTAssertTrue(waitForLabel(untrackedStatus, toEqual: "Staged"))
        XCTAssertEqual(
            try gitOutput(["diff", "--cached", "--name-only"]).split(separator: "\n").sorted(),
            ["tracked.txt", "untracked.txt"]
        )
        XCTAssertEqual(
            try gitOutput(["show", ":untracked.txt"]),
            try String(contentsOf: repositoryURL.appendingPathComponent("untracked.txt"), encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
            "Batch Stage should capture the current contents of the new file"
        )

        element(identifier: "gitok.worktree.select.tracked.txt").click()
        element(identifier: "gitok.worktree.select.untracked.txt").click()
        let unstage = element(identifier: "gitok.worktree.batch.unstage")
        XCTAssertTrue(waitUntilEnabled(unstage), "Selecting staged files should enable batch Unstage")
        unstage.click()
        XCTAssertTrue(waitForLabel(trackedStatus, toEqual: "Not Staged"))
        XCTAssertTrue(
            waitForLabel(untrackedStatus, toEqual: "Untracked"),
            "Untracked file status did not return after batch unstage"
        )
        XCTAssertEqual(try gitOutput(["diff", "--cached", "--name-only"]), "")
    }

    func testDiscardAllChangesRequiresConfirmation() throws {
        let discardAll = element(identifier: "gitok.worktree.discard-all")
        XCTAssertTrue(discardAll.waitForExistence(timeout: 15), "Discard All is missing from Changes")
        discardAll.click()

        let alert = app.sheets.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Discard All did not ask for confirmation")
        let confirm = alert.buttons["Discard All Changes"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "The confirmation has no destructive action")
        confirm.click()

        let deadline = Date().addingTimeInterval(15)
        var status = ""
        while Date() < deadline {
            status = try gitOutput(["status", "--porcelain"])
            if status.isEmpty { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(status.isEmpty, "Discard All left repository changes behind: \(status)")
        XCTAssertEqual(
            try String(contentsOf: repositoryURL.appendingPathComponent("tracked.txt"), encoding: .utf8),
            "initial content\n"
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: repositoryURL.appendingPathComponent("untracked.txt").path))
    }

    func testCancellingDiscardAllKeepsWorkingTreeChanges() throws {
        let discardAll = element(identifier: "gitok.worktree.discard-all")
        XCTAssertTrue(discardAll.waitForExistence(timeout: 15), "Discard All is missing from Changes")
        discardAll.click()

        let alert = app.sheets.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Discard All did not ask for confirmation")
        let cancel = alert.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Discard All confirmation has no Cancel action")
        cancel.click()

        XCTAssertFalse(alert.waitForExistence(timeout: 1), "Cancelling should close the confirmation")
        XCTAssertEqual(
            try gitOutput(["status", "--porcelain"]).split(separator: "\n").count,
            2,
            "Cancelling Discard All must leave both fixture changes intact"
        )
        XCTAssertEqual(
            try String(contentsOf: repositoryURL.appendingPathComponent("tracked.txt"), encoding: .utf8),
            "modified by the UI test\n"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: repositoryURL.appendingPathComponent("untracked.txt").path))
    }

    func testDiscardingOneFileLeavesOtherChangesUntouched() throws {
        let discardTracked = element(identifier: "gitok.worktree.discard.tracked.txt")
        XCTAssertTrue(discardTracked.waitForExistence(timeout: 15), "The modified fixture file has no Discard action")
        discardTracked.click()

        let alert = app.sheets.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Discarding one file did not ask for confirmation")
        let confirm = alert.buttons["Discard"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "The confirmation has no single-file Discard action")
        confirm.click()

        let deadline = Date().addingTimeInterval(15)
        var status = ""
        while Date() < deadline {
            status = try gitOutput(["status", "--porcelain"])
            if status == "?? untracked.txt" { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertEqual(status, "?? untracked.txt", "Discarding the tracked file should preserve the unrelated untracked file")
        XCTAssertEqual(
            try String(contentsOf: repositoryURL.appendingPathComponent("tracked.txt"), encoding: .utf8),
            "initial content\n"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: repositoryURL.appendingPathComponent("untracked.txt").path))
    }

    func testCommitButtonCreatesCommitFromStagedChange() throws {
        let commit = element(identifier: "gitok.commit.submit")
        XCTAssertTrue(commit.waitForExistence(timeout: 10), "The Commit action is missing")
        XCTAssertTrue(commit.isEnabled, "The Commit action should be available for the active project")

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
        replaceText(in: subject, with: "Commit \(marker)")

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
        replaceText(in: nameField, with: name)
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "value == %@", name), on: nameField, timeout: 5),
            "The branch-name field did not retain the entered name"
        )

        let create = element(identifier: "gitok.git.branch.create")
        XCTAssertTrue(waitUntilEnabled(create), "A non-empty branch name should enable Create")
        create.click()

        let currentBranch = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "label CONTAINS %@", name), on: currentBranch, timeout: 15),
            "Creating the branch did not update the toolbar"
        )
        XCTAssertEqual(try gitOutput(["branch", "--show-current"]), name)

        switcher.click()
        let mainBranch = element(identifier: "gitok.git.branch.option.main")
        XCTAssertTrue(mainBranch.waitForExistence(timeout: 5), "The existing main branch is missing from the picker")
        mainBranch.click()
        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "label CONTAINS %@", "main"), on: currentBranch, timeout: 15),
            "Selecting an existing branch did not update the toolbar"
        )
        XCTAssertEqual(try gitOutput(["branch", "--show-current"]), "main")
    }

    func testBranchPickerSearchFiltersLocalBranches() throws {
        let branchName = "ui-search-\(UUID().uuidString.prefix(8))"
        _ = try gitOutput(["branch", branchName])

        let switcher = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 15), "The branch picker is missing")
        XCTAssertTrue(waitUntilEnabled(switcher), "The branch list did not finish loading")
        switcher.click()

        let matchingBranch = element(identifier: "gitok.git.branch.option.\(branchName)")
        XCTAssertTrue(matchingBranch.waitForExistence(timeout: 10), "The new local branch was not listed")
        let mainBranch = element(identifier: "gitok.git.branch.option.main")
        XCTAssertTrue(mainBranch.exists, "The unfiltered list should initially include main")

        let search = element(identifier: "gitok.git.branch.search")
        XCTAssertTrue(search.waitForExistence(timeout: 5), "The branch search field is missing")
        replaceText(in: search, with: String(branchName.suffix(8)))

        XCTAssertTrue(matchingBranch.waitForExistence(timeout: 5), "Searching should retain the matching branch")
        XCTAssertFalse(mainBranch.exists, "Searching should filter out branches that do not match")
    }

}

final class GitOKCleanRepositoryUITests: GitOKUITestCase {
    override var hasWorkingTreeChanges: Bool { false }

    func testCreatingBranchRefreshesRepositoryInfo() {
        let branchInfo = element(identifier: "gitok.repository.info.branch")
        XCTAssertTrue(branchInfo.waitForExistence(timeout: 15), "Repository branch information is missing")
        XCTAssertTrue((branchInfo.value as? String)?.contains("main") == true, "The fixture should initially report main")

        let switcher = element(identifier: "gitok.git.branch.switcher")
        XCTAssertTrue(switcher.waitForExistence(timeout: 10))
        XCTAssertTrue(waitUntilEnabled(switcher), "The branch list did not finish loading")
        switcher.click()
        let createToggle = element(identifier: "gitok.git.branch.create.toggle")
        XCTAssertTrue(createToggle.waitForExistence(timeout: 5))
        createToggle.click()

        let name = "ui-info-\(UUID().uuidString.prefix(8))"
        let nameField = element(identifier: "gitok.git.branch.new-name")
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        replaceText(in: nameField, with: name)

        let create = element(identifier: "gitok.git.branch.create")
        XCTAssertTrue(waitUntilEnabled(create))
        create.click()

        XCTAssertTrue(
            waitForPredicate(NSPredicate(format: "value CONTAINS %@", name), on: branchInfo, timeout: 15),
            "Repository information kept showing the previous branch after checkout"
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
        "projects",
        "appearance",
        "plugin-manager",
        "userInfo",
        "commitStyle",
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

    func testSettingsCommandOpensSettingsWindow() {
        let appMenu = app.menuBars.menuBarItems["GitOK"]
        XCTAssertTrue(appMenu.waitForExistence(timeout: 5), "GitOK application menu is missing")
        appMenu.click()
        let settingsCommand = app.menuItems["Settings..."]
        XCTAssertTrue(settingsCommand.waitForExistence(timeout: 5), "Settings command is missing from the app menu")
        settingsCommand.click()
        XCTAssertTrue(
            element(identifier: "gitok.settings.ready").waitForExistence(timeout: 10),
            "The Settings command did not open the settings window"
        )
    }
}
