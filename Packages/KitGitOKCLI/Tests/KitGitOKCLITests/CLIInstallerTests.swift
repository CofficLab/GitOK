import Foundation
import XCTest
@testable import KitGitOKCLI

/// `CLIInstaller` 的安装 / 卸载 / 状态检测测试。
final class CLIInstallerTests: XCTestCase {

    private var workingDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        workingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-cli-install-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: workingDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: workingDirectory)
        try super.tearDownWithError()
    }

    private func makeTarget(
        isOnPath: Bool = true
    ) -> CLIInstallTarget {
        CLIInstallTarget(
            directory: workingDirectory,
            isOnPath: isOnPath,
            isWritable: true
        )
    }

    func testInstallWritesExecutableScript() {
        let outcome = CLIInstaller.install(
            target: makeTarget(),
            environment: ["PATH": workingDirectory.path]
        )

        guard case .installed(let target) = outcome else {
            return XCTFail("expected installation to succeed, got \(outcome)")
        }
        XCTAssertEqual(target.directory.path, workingDirectory.standardizedFileURL.path)

        let scriptURL = workingDirectory.appendingPathComponent("gitok")
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: scriptURL.path),
            "the installed script must be executable"
        )
    }

    func testInstallReportsWhenTargetIsNotOnPath() {
        let outcome = CLIInstaller.install(
            target: makeTarget(isOnPath: false),
            environment: ["PATH": "/usr/bin"]
        )
        guard case .installedButNotOnPath = outcome else {
            return XCTFail("expected installedButNotOnPath, got \(outcome)")
        }
    }

    func testInstallCreatesMissingDirectory() {
        let nested = workingDirectory
            .appendingPathComponent("nested/dir", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: nested.path))

        let outcome = CLIInstaller.install(
            target: CLIInstallTarget(directory: nested, isOnPath: true, isWritable: true),
            environment: ["PATH": nested.path]
        )

        guard case .installed = outcome else {
            return XCTFail("expected installation to succeed, got \(outcome)")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: nested.path))
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: nested.appendingPathComponent("gitok").path
            )
        )
    }

    func testInstallFailsOnUnwritableDirectory() {
        let outcome = CLIInstaller.install(
            target: CLIInstallTarget(
                directory: workingDirectory,
                isOnPath: true,
                isWritable: false
            ),
            environment: ["PATH": workingDirectory.path]
        )

        guard case .failed = outcome else {
            return XCTFail("expected failure, got \(outcome)")
        }
    }

    func testStatusReportsNotInstalledInitially() {
        let status = CLIInstaller.status(
            environment: ["PATH": workingDirectory.path, "HOME": workingDirectory.path]
        )
        XCTAssertFalse(status.isInstalled)
        XCTAssertNil(status.installedPath)
    }

    func testStatusReportsInstalledAfterInstall() {
        _ = CLIInstaller.install(
            target: makeTarget(),
            environment: ["PATH": workingDirectory.path]
        )

        let status = CLIInstaller.status(
            environment: ["PATH": workingDirectory.path, "HOME": workingDirectory.path]
        )
        XCTAssertTrue(status.isInstalled)
        XCTAssertTrue(status.isOnPath)
        XCTAssertEqual(
            status.installedPath?.lastPathComponent,
            "gitok"
        )
    }

    func testUninstallRemovesScript() {
        _ = CLIInstaller.install(
            target: makeTarget(),
            environment: ["PATH": workingDirectory.path]
        )
        let scriptURL = workingDirectory.appendingPathComponent("gitok")
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptURL.path))

        let removed = CLIInstaller.uninstall(
            environment: ["PATH": workingDirectory.path, "HOME": workingDirectory.path]
        )

        XCTAssertTrue(removed)
        XCTAssertFalse(FileManager.default.fileExists(atPath: scriptURL.path))
        XCTAssertFalse(
            CLIInstaller.status(
                environment: ["PATH": workingDirectory.path, "HOME": workingDirectory.path]
            ).isInstalled
        )
    }

    func testUninstallSucceedsWhenNothingInstalled() {
        let removed = CLIInstaller.uninstall(
            environment: ["PATH": workingDirectory.path, "HOME": workingDirectory.path]
        )
        XCTAssertTrue(removed, "uninstalling a missing command is a no-op success")
    }

    func testReinstallOverwritesExistingScript() {
        _ = CLIInstaller.install(
            target: makeTarget(),
            environment: ["PATH": workingDirectory.path]
        )
        let scriptURL = workingDirectory.appendingPathComponent("gitok")
        try? "stale".write(to: scriptURL, atomically: true, encoding: .utf8)

        _ = CLIInstaller.install(
            target: makeTarget(),
            environment: ["PATH": workingDirectory.path]
        )

        let contents = try? String(contentsOf: scriptURL, encoding: .utf8)
        XCTAssertTrue(contents?.contains("#!/bin/sh") == true)
        XCTAssertFalse(contents?.contains("stale") == true)
    }
}
