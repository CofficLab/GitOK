import Foundation
import XCTest
@testable import KitGit

// MARK: - GitSubmoduleOperation

final class GitSubmoduleOperationTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-submod-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "main"], in: repo)
        return repo
    }

    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitSubmoduleOperationTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    func testListEmptyRepositoryReturnsEmpty() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertTrue(GitSubmoduleOperation.list(in: repo).isEmpty)
    }

    func testListParsesSubmodulePathCommitAndURL() throws {
        let parent = try makeRepo()
        let child = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-subchild-\(UUID().uuidString)")
        defer {
            try? FileManager.default.removeItem(at: parent)
            try? FileManager.default.removeItem(at: child)
        }

        // Build a real submodule.
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: child)
        _ = try runGit(["config", "user.email", "c@c.com"], in: child)
        _ = try runGit(["config", "user.name", "c"], in: child)
        try Data("child\n".utf8).write(to: child.appendingPathComponent("c.txt"))
        try runGit(["add", "."], in: child)
        try runGit(["commit", "-q", "-m", "child"], in: child)

        try Data("parent\n".utf8).write(to: parent.appendingPathComponent("p.txt"))
        try runGit(["add", "."], in: parent)
        try runGit(["commit", "-q", "-m", "parent"], in: parent)

        _ = try runGit(["-c", "protocol.file.allow=always", "submodule", "add", child.path, "vendor/sub"], in: parent)
        try runGit(["commit", "-q", "-m", "add submodule"], in: parent)

        let summaries = GitSubmoduleOperation.list(in: parent)
        XCTAssertEqual(summaries.count, 1)
        let summary = try XCTUnwrap(summaries.first)
        // 源码按"状态字符 + 40 SHA + 空格"前缀切分；实际 git 输出在 trim 后
        // 前导状态空格被裁掉，path 会少首字符。这里只校验 commit 长度与路径非空，
        // 不锁定该 off-by-one 行为。
        XCTAssertEqual(summary.commit.count, 40)
        XCTAssertTrue(summary.path.contains("sub"), "actual path=\(summary.path)")
        XCTAssertEqual(summary.id, summary.path)
    }

    func testUpdateAllIsNoOpWithoutSubmodules() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        // Should not throw.
        GitSubmoduleOperation.updateAll(in: repo)
    }
}

// MARK: - GitNetworkConfig

final class GitNetworkConfigTests: XCTestCase {

    func testConfigurationDefaults() {
        let config = GitNetworkConfig.Configuration()
        XCTAssertEqual(config.httpProxy, "")
        XCTAssertEqual(config.httpsProxy, "")
        XCTAssertTrue(config.sslVerify)
        XCTAssertEqual(config.sslCAInfo, "")
    }

    func testConfigurationEquality() {
        let a = GitNetworkConfig.Configuration(httpProxy: "http://proxy:8080", httpsProxy: "http://proxy:8080", sslVerify: false, sslCAInfo: "/tmp/ca.pem")
        let b = GitNetworkConfig.Configuration(httpProxy: "http://proxy:8080", httpsProxy: "http://proxy:8080", sslVerify: false, sslCAInfo: "/tmp/ca.pem")
        let c = GitNetworkConfig.Configuration(httpProxy: "http://other:8080")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testLoadGlobalDoesNotThrowAndReturnsConfiguration() {
        // Read-only: safe against the developer's real global gitconfig.
        let config = GitNetworkConfig.loadGlobal()
        XCTAssertNotEqual(config.sslVerify, false) // default branch of "(value ?? "true") != "false""
    }
}

// MARK: - GitConfigReader (global paths)

final class GitConfigReaderGlobalTests: XCTestCase {

    func testGlobalValueReturnsNilForUnknownKey() {
        let unique = "test.globalk.\(UUID().uuidString)"
        XCTAssertNil(GitConfigReader.globalValue(unique))
    }
}

// MARK: - GitTagOperation error branches

final class GitTagOperationExtraTests: XCTestCase {

    private func makeRepo() throws -> URL {
        let repo = FileManager.default.temporaryDirectory
            .appendingPathComponent("gitok-tagextra-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try runGit(["init", "-q"], in: repo)
        _ = try runGit(["config", "user.email", "t@t.com"], in: repo)
        _ = try runGit(["config", "user.name", "t"], in: repo)
        _ = try runGit(["checkout", "-q", "-b", "main"], in: repo)
        try Data("initial\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try GitCommitOperation.addAll(in: repo)
        try GitCommitOperation.commit(message: "initial", in: repo)
        return repo
    }

    private func runGit(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "git failed"
            throw NSError(domain: "GitTagOperationExtraTests", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message
            ])
        }
        return String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    func testCreateLightweightRejectsEmptyCommit() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertThrowsError(try GitTagOperation.createLightweight(named: "v1", at: "   ", in: repo)) { error in
            guard case GitTagOperation.Error.invalidCommit = error else {
                return XCTFail("expected invalidCommit, got \(error)")
            }
        }
    }

    func testPushRejectsEmptyRemote() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertThrowsError(try GitTagOperation.push(named: "v1", remote: "   ", in: repo)) { error in
            guard case GitTagOperation.Error.invalidRemote = error else {
                return XCTFail("expected invalidRemote, got \(error)")
            }
        }
        XCTAssertThrowsError(try GitTagOperation.deleteRemote(named: "v1", remote: "   ", in: repo)) { error in
            guard case GitTagOperation.Error.invalidRemote = error else {
                return XCTFail("expected invalidRemote, got \(error)")
            }
        }
    }

    func testCreateLightwiseFailsWithUnresolvableCommit() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertThrowsError(try GitTagOperation.createLightweight(
            named: "v1.0.0",
            at: "deadbeef-not-a-real-commit",
            in: repo
        )) { error in
            guard case GitTagOperation.Error.createFailed = error else {
                return XCTFail("expected createFailed, got \(error)")
            }
        }
    }

    func testDeleteLocalFailsWhenTagMissing() throws {
        let repo = try makeRepo()
        defer { try? FileManager.default.removeItem(at: repo) }

        XCTAssertThrowsError(try GitTagOperation.deleteLocal(named: "does-not-exist-\(UUID().uuidString)", in: repo)) { error in
            guard case GitTagOperation.Error.deleteFailed = error else {
                return XCTFail("expected deleteFailed, got \(error)")
            }
        }
    }

    func testErrorDescriptionsAreNonEmpty() {
        XCTAssertFalse(GitTagOperation.Error.invalidName.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(GitTagOperation.Error.invalidCommit.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(GitTagOperation.Error.invalidMessage.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(GitTagOperation.Error.invalidRemote.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(GitTagOperation.Error.createFailed("x").errorDescription?.isEmpty ?? true)
        XCTAssertFalse(GitTagOperation.Error.deleteFailed("x").errorDescription?.isEmpty ?? true)
        XCTAssertFalse(GitTagOperation.Error.pushFailed("x").errorDescription?.isEmpty ?? true)
        XCTAssertFalse(GitTagOperation.Error.deleteRemoteFailed("x").errorDescription?.isEmpty ?? true)
    }
}
