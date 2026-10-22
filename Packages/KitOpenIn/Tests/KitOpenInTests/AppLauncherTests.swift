import Foundation
import XCTest
@testable import KitOpenIn

/// `AppLauncher` 的应用解析与 remote 链接转换覆盖。
final class AppLauncherTests: XCTestCase {

    // MARK: - Helpers

    private func makeRepository(remote: String?) throws -> URL {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("KitOpenInTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        try runGit(["init", "-q"], in: repository)
        if let remote {
            try runGit(["remote", "add", "origin", remote], in: repository)
        }
        return repository
    }

    @discardableResult
    private func runGit(_ arguments: [String], in repository: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = repository
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "AppLauncherTests", code: Int(process.terminationStatus))
        }
        return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }

    // MARK: - 应用解析

    func testFinderAndTerminalAreAlwaysInstalled() {
        // 系统自带的两个应用必然可解析。
        XCTAssertNotNil(AppLauncher.applicationURL(for: .finder))
        XCTAssertNotNil(AppLauncher.applicationURL(for: .terminal))
        XCTAssertTrue(AppLauncher.isInstalled(.finder))
        XCTAssertTrue(AppLauncher.isInstalled(.terminal))
    }

    func testRemoteTargetIsAlwaysAvailable() {
        XCTAssertTrue(OpenTarget.remote.isAlwaysAvailable)
        XCTAssertTrue(AppLauncher.isInstalled(.remote))
    }

    func testRemoteTargetHasNoApplicationURLNorFallbackPath() {
        // Remote 通过浏览器打开，没有自己的应用 bundle。
        XCTAssertEqual(OpenTarget.remote.bundleIdentifier, "")
        XCTAssertTrue(OpenTarget.remote.fallbackPaths.isEmpty)
    }

    // MARK: - remote 链接转换

    func testWebURLFromScpLikeRemote() {
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "git@github.com:user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
    }

    func testWebURLFromSSHRemote() {
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "ssh://git@github.com/user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
    }

    func testWebURLFromHTTPSRemote() {
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "https://github.com/user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
    }

    func testWebURLKeepsRemoteWithoutGitSuffix() {
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "https://github.com/user/repo")?.absoluteString,
            "https://github.com/user/repo"
        )
    }

    func testWebURLTrimsSurroundingWhitespace() {
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "  git@github.com:user/repo.git\n")?.absoluteString,
            "https://github.com/user/repo"
        )
    }

    func testWebURLFromInvalidRemoteIsNil() {
        // 空字符串无法构造成 URL。
        XCTAssertNil(AppLauncher.webURL(fromRemote: ""))
    }

    // MARK: - 仓库 remote

    func testRemoteWebURLReadsOriginRemote() throws {
        let repository = try makeRepository(remote: "git@github.com:user/repo.git")
        defer { try? FileManager.default.removeItem(at: repository) }

        let url = AppLauncher.remoteWebURL(for: repository)

        XCTAssertEqual(url?.absoluteString, "https://github.com/user/repo")
    }

    func testRemoteWebURLIsNilWithoutRemote() throws {
        let repository = try makeRepository(remote: nil)
        defer { try? FileManager.default.removeItem(at: repository) }

        XCTAssertNil(AppLauncher.remoteWebURL(for: repository))
    }

    func testRemoteWebURLIsNilForNonRepository() {
        let missing = URL(fileURLWithPath: "/tmp/kit-open-in-missing-\(UUID().uuidString)")

        XCTAssertNil(AppLauncher.remoteWebURL(for: missing))
    }

    // MARK: - 打开动作的安全路径

    /// Remote 目标在没有可用 remote 链接时直接返回，不会打开任何应用。
    func testOpenRemoteWithoutRemoteDoesNothing() async throws {
        let missing = URL(fileURLWithPath: "/tmp/kit-open-in-missing-\(UUID().uuidString)")

        AppLauncher.open(.remote, projectURL: missing)
        // 打开动作在后台线程执行；留出时间窗确认没有异常抛出。
        try await Task.sleep(for: .milliseconds(200))
    }

    /// Remote 目标不支持「用应用打开单个文件」，直接返回。
    func testOpenFileInRemoteTargetDoesNothing() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/kit-open-in-file-\(UUID().uuidString)")

        AppLauncher.openFile(fileURL, in: .remote)
        try await Task.sleep(for: .milliseconds(200))
    }
}

/// `OpenTarget` 的文案、回退路径与本地化覆盖。
final class OpenTargetPresentationTests: XCTestCase {

    func testHelpTextIsNotEmptyForEveryTarget() {
        for target in OpenTarget.allCases {
            XCTAssertFalse(target.helpText.isEmpty, "target \(target.rawValue) 缺少帮助文案")
        }
    }

    func testRemoteHelpTextUsesDedicatedCopy() {
        // Remote 有单独的文案，其余目标统一使用「Open in %@」。
        XCTAssertFalse(OpenTarget.remote.helpText.contains("Open in"))
        XCTAssertTrue(OpenTarget.finder.helpText.contains("Finder"))
        XCTAssertTrue(OpenTarget.vscode.helpText.contains("VS Code"))
    }

    func testFallbackPathsAreAbsoluteOrHomeRelative() {
        for target in OpenTarget.allCases {
            for path in target.fallbackPaths {
                XCTAssertTrue(
                    path.hasPrefix("/") || path.hasPrefix(NSHomeDirectory()),
                    "target \(target.rawValue) 的回退路径不是绝对路径：\(path)"
                )
            }
        }
    }

    func testFinderAndTerminalHaveSingleFallbackPath() {
        XCTAssertEqual(
            OpenTarget.finder.fallbackPaths,
            ["/System/Library/CoreServices/Finder.app"]
        )
        XCTAssertEqual(
            OpenTarget.terminal.fallbackPaths,
            ["/System/Applications/Utilities/Terminal.app"]
        )
        XCTAssertEqual(OpenTarget.xcode.fallbackPaths, ["/Applications/Xcode.app"])
        XCTAssertEqual(
            OpenTarget.githubDesktop.fallbackPaths,
            ["/Applications/GitHub Desktop.app"]
        )
    }

    func testEveryTargetHasBundleIdentifierExceptRemote() {
        for target in OpenTarget.allCases where target != .remote {
            XCTAssertFalse(
                target.bundleIdentifier.isEmpty,
                "target \(target.rawValue) 缺少 bundle identifier"
            )
        }
    }

    func testLocalizationReturnsNonEmptyValue() {
        let value = KitOpenInLocalization.string("Open in %@", bundle: .module)
        XCTAssertFalse(value.isEmpty)
    }
}
