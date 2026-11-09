import Foundation
import XCTest
@testable import KitGitOKCLI

/// `CLIScriptBuilder` 的脚本内容生成测试。
final class CLIScriptBuilderTests: XCTestCase {

    func testScriptHasShebangAndIsExecutableShell() {
        let contents = CLIScriptBuilder.scriptContents()
        XCTAssertTrue(contents.hasPrefix("#!/bin/sh\n"))
        XCTAssertTrue(contents.contains("set -eu"))
    }

    func testScriptUsesConfiguredCommandNameAndScheme() {
        let contents = CLIScriptBuilder.scriptContents(
            commandName: "mygitok",
            urlScheme: "mygitok"
        )
        XCTAssertTrue(contents.contains("mygitok://open?path="))
        XCTAssertTrue(contents.contains("mygitok: 未找到 GitOK.app"))
        // scheme 必须是自定义值，不能残留默认 scheme。
        XCTAssertFalse(
            contents.contains("\"gitok://open?path="),
            "the default scheme must not leak into a custom-scheme script"
        )
    }

    func testScriptResolvesAppFromEnvironmentAndDefaultLocations() {
        let contents = CLIScriptBuilder.scriptContents()
        XCTAssertTrue(contents.contains("${GITOK_APP:-}"))
        XCTAssertTrue(contents.contains("/Applications/GitOK.app"))
        XCTAssertTrue(contents.contains("$HOME/Applications/GitOK.app"))
    }

    func testScriptPercentEncodesPath() {
        let contents = CLIScriptBuilder.scriptContents()
        XCTAssertTrue(contents.contains("URI::Escape"))
        XCTAssertTrue(contents.contains("uri_escape"))
        XCTAssertTrue(contents.contains("ENCODED_PATH"))
    }

    func testScriptDoesNotHardcodeAppBundlePath() {
        // 脚本不能依赖 App bundle 内的任何文件，否则 App 移动后就失效。
        let contents = CLIScriptBuilder.scriptContents()
        XCTAssertFalse(contents.contains("Contents/MacOS"))
        XCTAssertFalse(contents.contains("Contents/Resources"))
    }

    func testGeneratedScriptRunsSuccessfullyInShell() throws {
        // 把脚本写到临时文件，用 `sh -n` 做语法检查。
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-syntax-\(UUID().uuidString).sh")
        defer { try? FileManager.default.removeItem(at: scriptURL) }
        try CLIScriptBuilder.scriptContents().write(
            to: scriptURL,
            atomically: true,
            encoding: .utf8
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-n", scriptURL.path]
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(
            process.terminationStatus,
            0,
            "generated script must be valid shell: \(String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")"
        )
    }

    func testGeneratedScriptReportsMissingApp() throws {
        // GITOK_APP 指向不存在的路径时，脚本应报错退出而不是静默成功。
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-missing-\(UUID().uuidString).sh")
        defer { try? FileManager.default.removeItem(at: scriptURL) }
        try CLIScriptBuilder.scriptContents().write(
            to: scriptURL,
            atomically: true,
            encoding: .utf8
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [scriptURL.path, "/tmp"]
        process.environment = ["GITOK_APP": "/nonexistent-path-for-test", "PATH": "/usr/bin:/bin"]
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        try process.run()
        process.waitUntilExit()

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        XCTAssertNotEqual(process.terminationStatus, 0)
        XCTAssertTrue(output.contains("未找到 GitOK.app"), "unexpected output: \(output)")
    }
}
