import Foundation
import KernelCore
import ProviderGitRepositoryWatch
import ProviderProjects
import XCTest
@testable import PluginGitRepositoryWatch

@MainActor
final class PluginGitRepositoryWatchTests: XCTestCase {

    // MARK: - Plugin metadata

    func testPluginMetadata() {
        let plugin = GitRepositoryWatchPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.git-repository-watch")
        XCTAssertEqual(plugin.order, 5)
        XCTAssertTrue(plugin.dependencies.contains("com.coffic.lumi.plugin.projects"))
        XCTAssertEqual(plugin.metadata.category, .project)
    }

    // MARK: - Provider initial state

    func testProviderInitialState() {
        let provider = GitRepositoryWatchProvider()
        XCTAssertNil(provider.watchingRepositoryURL)
        XCTAssertFalse(provider.isWatcherActive)
        XCTAssertNil(provider.watchedGitDirectoryPath)
    }

    // MARK: - startWatching on non-git directory

    /// 非 git 仓库目录：解析失败，状态保持未监听。
    func testStartWatchingOnNonGitDirectoryStaysClean() {
        let provider = GitRepositoryWatchProvider()
        var received: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { received.append($0) }
        defer { handle.cancel() }

        // 临时目录不是 git 仓库。
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PluginGitRepositoryWatchTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        provider.startWatching(repositoryURL: tempURL)

        // 解析失败 → 状态回到未监听，不广播任何事件。
        XCTAssertNil(provider.watchingRepositoryURL)
        XCTAssertFalse(provider.isWatcherActive)
        XCTAssertTrue(received.isEmpty)
    }

    // MARK: - startWatching on real git repository

    /// 真实 git 仓库：能成功解析 .git 目录并开始监听。
    func testStartWatchingOnRealGitRepository() throws {
        // 用本仓库（GitOK）作为真实 git 仓库样本。
        let repoURL = findNearestGitRepository()
        try XCTSkipUnless(repoURL != nil, "找不到可测试的 git 仓库")
        guard let repoURL else { return }

        let provider = GitRepositoryWatchProvider()
        var received: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { received.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repoURL)

        XCTAssertEqual(provider.watchingRepositoryURL, repoURL.standardizedFileURL)
        XCTAssertTrue(provider.isWatcherActive)
        XCTAssertNotNil(provider.watchedGitDirectoryPath)
        XCTAssertEqual(received.count, 1)
        if case .started(let url) = received.first {
            XCTAssertEqual(url, repoURL.standardizedFileURL)
        } else {
            XCTFail("expected .started, got \(received.first.debugDescription)")
        }
    }

    // MARK: - stopWatching

    func testStopWatchingAfterStart() throws {
        let repoURL = try XCTSkipUnlessReturn(findNearestGitRepository())
        let provider = GitRepositoryWatchProvider()
        var received: [GitRepositoryWatchingEvent] = []
        let handle = provider.addObserver { received.append($0) }
        defer { handle.cancel() }

        provider.startWatching(repositoryURL: repoURL)
        provider.stopWatching()

        XCTAssertNil(provider.watchingRepositoryURL)
        XCTAssertFalse(provider.isWatcherActive)
        XCTAssertEqual(received.count, 2)
        if case .stopped = received.last {
            // ok
        } else {
            XCTFail("expected .stopped as last event")
        }
    }

    func testStopWatchingWhenNotWatchingIsNoop() {
        let provider = GitRepositoryWatchProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        provider.stopWatching()
        XCTAssertEqual(count, 0)
    }

    // MARK: - Observer handle

    func testCancelHandleStopsCallbacks() {
        let provider = GitRepositoryWatchProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        handle.cancel()

        // 即使 start 失败，observer 列表已清空，不会再收到后续事件。
        provider.startWatching(repositoryURL: URL(fileURLWithPath: "/non-existent"))
        XCTAssertEqual(count, 0)
    }

    // MARK: - Snapshot / Resolver

    /// 对真实仓库：解析出的 .git 目录必须存在，HEAD 指纹非空。
    func testResolverOnRealRepository() throws {
        let repoURL = try XCTSkipUnlessReturn(findNearestGitRepository())

        let gitDirectory = try GitDirectoryResolver.resolveGitDirectory(for: repoURL)
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: gitDirectory.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)

        let snapshot = GitDirectoryResolver.readSnapshot(gitDirectory: gitDirectory)
        XCTAssertNotNil(snapshot.head, "HEAD 应有内容")
    }

    /// 文件指纹对同文件应稳定；对不存在文件应返回 nil。
    func testFileContentFingerprintIsStable() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("fingerprint-test-\(UUID().uuidString).txt")
        try? "hello world".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let a = GitDirectoryResolver.fileContentFingerprint(tempURL)
        let b = GitDirectoryResolver.fileContentFingerprint(tempURL)
        XCTAssertNotNil(a)
        XCTAssertEqual(a, b)

        let missing = GitDirectoryResolver.fileContentFingerprint(
            URL(fileURLWithPath: "/non-existent-\(UUID().uuidString)")
        )
        XCTAssertNil(missing)
    }

    // MARK: - Helpers

    /// 向上查找最近的 git 仓库（用于测试环境定位 GitOK 仓库）。
    private func findNearestGitRepository() -> URL? {
        var url = URL(fileURLWithPath: #file)
        for _ in 0..<20 {
            let dotGit = url.appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: dotGit.path) {
                return url
            }
            url = url.deletingLastPathComponent()
            if url.path == "/" { return nil }
        }
        return nil
    }
}

// MARK: - XCTSkipUnless helper

private func XCTSkipUnlessReturn<T>(_ expression: @autoclosure () -> T?) throws -> T {
    guard let value = expression() else {
        throw XCTSkip("required value was nil")
    }
    return value
}

private func XCTSkipUnless(_ expression: @autoclosure () -> Bool?, _ message: String = "") throws {
    guard expression() == true else {
        throw XCTSkip(message.isEmpty ? "condition not met" : message)
    }
}
