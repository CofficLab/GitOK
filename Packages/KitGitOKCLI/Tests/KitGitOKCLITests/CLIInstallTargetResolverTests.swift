import Foundation
import XCTest
@testable import KitGitOKCLI

/// `CLIInstallTargetResolver` 的目录选择逻辑测试。
final class CLIInstallTargetResolverTests: XCTestCase {

    private func makeTemporaryDirectory(
        _ name: String = UUID().uuidString
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-cli-\(name)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testCandidatesIncludePathDirectoryWhenWritable() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let targets = CLIInstallTargetResolver.candidates(
            environment: ["PATH": directory.path, "HOME": "/tmp"]
        )

        let match = targets.first { $0.directory.path == directory.standardizedFileURL.path }
        XCTAssertNotNil(match)
        XCTAssertTrue(match?.isOnPath == true)
        XCTAssertTrue(match?.isWritable == true)
    }

    func testBestTargetPrefersDirectoryAlreadyOnPath() throws {
        let onPathDirectory = try makeTemporaryDirectory("onpath")
        defer { try? FileManager.default.removeItem(at: onPathDirectory) }

        let targets = CLIInstallTargetResolver.candidates(
            environment: ["PATH": onPathDirectory.path, "HOME": "/tmp"]
        )
        let best = CLIInstallTargetResolver.bestTarget(
            environment: ["PATH": onPathDirectory.path, "HOME": "/tmp"]
        )

        XCTAssertEqual(
            best?.directory.path,
            onPathDirectory.standardizedFileURL.path,
            "a directory already on PATH must win so the command works right after install"
        )
        XCTAssertEqual(best, targets.first(where: { $0.isOnPath }))
    }

    func testUserDirectoryIsUsedWhenHomeIsAvailable() throws {
        let home = try makeTemporaryDirectory("home")
        defer { try? FileManager.default.removeItem(at: home) }

        let targets = CLIInstallTargetResolver.candidates(
            environment: ["PATH": "", "HOME": home.path]
        )

        let userDirectory = home
            .appendingPathComponent(".local/bin", isDirectory: true)
            .standardizedFileURL
        XCTAssertTrue(
            targets.contains { $0.directory.path == userDirectory.path },
            "the user-level ~/.local/bin directory must always be a candidate"
        )
    }

    func testUserDirectoryIsMarkedNotOnPathWhenAbsentFromPath() throws {
        let home = try makeTemporaryDirectory("home2")
        defer { try? FileManager.default.removeItem(at: home) }

        let targets = CLIInstallTargetResolver.candidates(
            environment: ["PATH": "/usr/bin:/bin", "HOME": home.path]
        )

        let userDirectory = home
            .appendingPathComponent(".local/bin", isDirectory: true)
            .standardizedFileURL
        let match = targets.first { $0.directory.path == userDirectory.path }
        XCTAssertEqual(match?.isOnPath, false)
        XCTAssertEqual(match?.isWritable, true, "a not-yet-created directory is still installable")
    }

    func testNonWritablePathDirectoryIsSkipped() throws {
        let directory = try makeTemporaryDirectory("ro")
        defer { try? FileManager.default.removeItem(at: directory) }
        // 去掉写权限，模拟只读目录。
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o555))],
            ofItemAtPath: directory.path
        )
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: Int16(0o755))],
                ofItemAtPath: directory.path
            )
        }

        let targets = CLIInstallTargetResolver.candidates(
            environment: ["PATH": directory.path, "HOME": "/tmp"]
        )

        XCTAssertFalse(
            targets.contains { $0.directory.path == directory.standardizedFileURL.path },
            "a read-only directory must not be offered as an install target"
        )
    }

    func testBestTargetFallsBackToUserDirectoryWhenNoPathEntryIsUsable() throws {
        let home = try makeTemporaryDirectory("home3")
        defer { try? FileManager.default.removeItem(at: home) }

        // PATH 只包含不可写的系统目录，且 preferredDirectories 里的目录
        // 全部不可写时，应回落到 ~/.local/bin。
        // 这里用一个不存在的 HOME 之外的场景：把 PATH 指向临时只读目录，
        // 并断言返回值要么是真实可写的偏好目录，要么是用户目录 ——
        // 重点是「永远不会返回不可写目录」。
        let best = CLIInstallTargetResolver.bestTarget(
            environment: ["PATH": "/nonexistent-dir-for-test", "HOME": home.path]
        )

        let userDirectory = home
            .appendingPathComponent(".local/bin", isDirectory: true)
            .standardizedFileURL
        let preferredWritable = CLIInstallTargetResolver.preferredDirectories
            .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
            .contains { FileManager.default.isWritableFile(atPath: $0) }

        if preferredWritable {
            XCTAssertNotNil(best, "a writable preferred directory must be selected")
        } else {
            XCTAssertEqual(
                best?.directory.path,
                userDirectory.path,
                "the user-level directory must be the fallback install target"
            )
        }
    }
}
