import AppKit
import Carbon.HIToolbox
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
    /// setUp 前的系统键盘输入源，tearDown 时恢复，避免测试污染用户输入法。
    private var previousKeyboardInputSource: TISInputSource?

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 中文输入法（如拼音）的候选/状态窗口会以 Dialog 角色挂进被测应用的
        // AX 树；XCUITest 点击前的 interruption 检查会追踪它，而该窗口是瞬态的，
        // 消失时机不同会造成 "Failed to get matching snapshot" 随机失败。
        // 测试期间统一切到 ASCII 键盘布局，从源头消除该类窗口。
        switchToASCIICapableInputSource()
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
            "-ApplePersistenceIgnoreState", "YES",
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
        restorePreviousInputSource()
        if let fixtureRoot {
            try? FileManager.default.removeItem(at: fixtureRoot)
        }
        try super.tearDownWithError()
    }

    // MARK: - Input Source

    /// 切到 ASCII-capable 键盘布局（如 ABC / U.S.）。
    ///
    /// 中文拼音等输入法的候选窗会以 `Dialog` 角色挂进被测应用的 AX 树，
    /// XCUITest 点击前的 interruption 检查会追踪这个瞬态窗口，其出现/消失
    /// 时机不受控，导致 clone 等测试随机报 "Failed to get matching snapshot"。
    /// 测试期间统一使用 ASCII 布局即可从源头消除该窗口。
    private func switchToASCIICapableInputSource() {
        previousKeyboardInputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()

        let filter: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsASCIICapable as String: true,
        ]
        guard let candidates = TISCreateInputSourceList(filter as CFDictionary, false)?
            .takeRetainedValue() as? [TISInputSource],
            let target = candidates.first(where: { inputSourceID($0) == "com.apple.keylayout.ABC" })
                ?? candidates.first(where: { inputSourceID($0) == "com.apple.keylayout.US" })
                ?? candidates.first
        else { return }

        TISSelectInputSource(target)
    }

    /// 读取输入源的稳定标识符（如 `com.apple.keylayout.ABC`）。
    private func inputSourceID(_ source: TISInputSource) -> String? {
        guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
    }

    /// 恢复测试前的输入源（在 tearDown 调用，避免测试改变用户输入法）。
    private func restorePreviousInputSource() {
        if let previous = previousKeyboardInputSource {
            TISSelectInputSource(previous)
            previousKeyboardInputSource = nil
        }
    }

    func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// 按可见文本（label/value）查找元素——LumiSettings 渲染的设置侧边栏
    /// 条目不带 accessibility identifier，只能按标题定位。
    func element(label: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR value == %@", label, label))
            .firstMatch
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

    /// 执行一次 git 命令但忽略退出码。
    ///
    /// 用于搭建夹具状态，例如 `git merge` 在制造冲突时必然以非零码退出，
    /// 而测试真正关心的是它留下的工作区状态。
    func runGitAllowingFailure(_ arguments: [String], in repository: URL? = nil) throws {
        let process = Process()
        process.executableURL = gitExecutableURL
        process.arguments = ["-C", (repository ?? repositoryURL).path] + arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
    }

    /// 读取 git 命令输出，非零退出码时返回 `nil` 而不是抛错。
    ///
    /// `git rev-parse --verify -q MERGE_HEAD` 在没有 MERGE_HEAD 时正是以非零码退出，
    /// 需要用这种方式探测某个 ref 是否存在。
    func gitOutput(_ arguments: [String], allowFailure: Bool, in repository: URL? = nil) throws -> String {
        let process = Process()
        process.executableURL = gitExecutableURL
        process.arguments = ["-C", (repository ?? repositoryURL).path] + arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            if allowFailure { return "" }
            throw NSError(
                domain: "GitOKUITests.GitFixture",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "git \(arguments.joined(separator: " ")) failed"]
            )
        }
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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

    var gitExecutableURL: URL {
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
