import Foundation
import KitGit
import ProviderProjectLanguages
import Testing
@testable import PluginProjectLanguages

/// `LocalProjectLanguagesProvider` 的观察者与取消路径覆盖。
@MainActor
@Suite("LocalProjectLanguagesProvider 观察者")
struct LocalProjectLanguagesProviderObserverTests {

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LanguagesObserverTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// 可控的分析器：可以按需抛错 / 提前取消。
    private final class ScriptedAnalyzer: RepositoryLanguageAnalyzing, @unchecked Sendable {
        /// 非取消类错误：触发 provider 的通用错误分支（结束加载状态）。
        struct AnalysisFailure: Error {}

        private let lock = NSLock()
        private var _analysisCount = 0
        private var _failAnalysis = false
        private var _contextThrows = false

        var analysisCount: Int {
            lock.lock(); defer { lock.unlock() }; return _analysisCount
        }

        func setFailAnalysis(_ value: Bool) {
            lock.lock(); defer { lock.unlock() }; _failAnalysis = value
        }

        func setContextThrows(_ value: Bool) {
            lock.lock(); defer { lock.unlock() }; _contextThrows = value
        }

        func context(for repository: URL) throws -> RepositoryLanguageAnalysisContext {
            if _contextThrows {
                throw CancellationError()
            }
            return RepositoryLanguageAnalysisContext(
                cacheKey: ProjectLanguagesCacheKey(
                    repositoryPath: repository.path,
                    headHash: repository.lastPathComponent,
                    analyzerVersion: 1
                ),
                isWorktreeClean: true
            )
        }

        func analyze(repository: URL) throws -> ProjectLanguagesSnapshot {
            lock.lock()
            _analysisCount += 1
            let shouldFail = _failAnalysis
            lock.unlock()
            if shouldFail {
                throw AnalysisFailure()
            }
            return ProjectLanguagesSnapshot(
                repositoryPath: repository.path,
                languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
            )
        }
    }

    @Test("观察者能收到加载状态与快照变化")
    func observerReceivesEvents() async throws {
        let cacheDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let repository = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: repository) }

        let provider = LocalProjectLanguagesProvider(
            analyzer: ScriptedAnalyzer(),
            cache: ProjectLanguagesCache(directoryURL: cacheDirectory)
        )
        var events: [ProjectLanguagesEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.refresh(for: repository)
        #expect(provider.isLoading)
        #expect(events.contains(.loadingChanged))

        for _ in 0..<200 {
            if provider.currentSnapshot != nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(provider.currentSnapshot != nil)
        #expect(events.contains(.snapshotChanged))
        #expect(!provider.isLoading)
    }

    @Test("取消订阅后不再收到事件")
    func cancelledObserverStopsReceivingEvents() async throws {
        let cacheDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let repository = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: repository) }

        let provider = LocalProjectLanguagesProvider(
            analyzer: ScriptedAnalyzer(),
            cache: ProjectLanguagesCache(directoryURL: cacheDirectory)
        )
        var events: [ProjectLanguagesEvent] = []
        let handle = provider.addObserver { events.append($0) }

        provider.refresh(for: repository)
        for _ in 0..<200 {
            if provider.currentSnapshot != nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(events.contains(.snapshotChanged))

        handle.cancel()
        // 重复取消是空操作。
        handle.cancel()

        let countAfterCancel = events.count
        provider.refresh(for: repository)
        try await Task.sleep(for: .milliseconds(50))
        #expect(events.count == countAfterCancel, "取消后不应再收到事件")
    }

    @Test("分析失败时结束加载状态并保留观察者可用")
    func failedAnalysisEndsLoading() async throws {
        let cacheDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let repository = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: repository) }

        let analyzer = ScriptedAnalyzer()
        analyzer.setFailAnalysis(true)
        let provider = LocalProjectLanguagesProvider(
            analyzer: analyzer,
            cache: ProjectLanguagesCache(directoryURL: cacheDirectory)
        )
        var events: [ProjectLanguagesEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.refresh(for: repository)
        for _ in 0..<200 {
            if !provider.isLoading && provider.currentSnapshot == nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(!provider.isLoading, "分析失败后应结束加载状态")
        #expect(provider.currentSnapshot == nil)
        #expect(events.contains(.loadingChanged))
    }
}

/// `RepositoryLanguageAnalyzer` 的上下文与按文件名识别语言的覆盖。
@Suite("RepositoryLanguageAnalyzer 上下文")
struct RepositoryLanguageAnalyzerContextTests {

    private func makeRepository() throws -> URL {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent("LanguagesContextTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        try runGit(["init", "-q"], in: repository)
        try runGit(["config", "user.email", "test@example.com"], in: repository)
        try runGit(["config", "user.name", "Test"], in: repository)
        return repository
    }

    private func write(_ content: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func commit(_ repository: URL) throws {
        try runGit(["add", "."], in: repository)
        try runGit(["commit", "-qm", "test"], in: repository)
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
            throw NSError(domain: "RepositoryLanguageAnalyzerContextTests", code: Int(process.terminationStatus))
        }
        return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }

    @Test("context 读取 HEAD 与工作区状态并生成缓存键")
    func contextReadsHeadAndStatus() throws {
        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }
        try write("let value = 1\n", to: repository.appendingPathComponent("Sources/App.swift"))
        try commit(repository)

        let context = try RepositoryLanguageAnalyzer().context(for: repository)

        #expect(context.cacheKey.repositoryPath == repository.standardizedFileURL.path)
        #expect(context.cacheKey.analyzerVersion == RepositoryLanguageAnalyzer.cacheVersion)
        #expect(context.cacheKey.headHash.isEmpty == false)
        #expect(context.isWorktreeClean)
    }

    @Test("没有提交时 context 抛出错误")
    func contextWithoutCommitThrows() throws {
        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }

        do {
            _ = try RepositoryLanguageAnalyzer().context(for: repository)
            Issue.record("没有提交时 context 应抛出错误")
        } catch {
            // 预期：仓库没有任何 commit，无法解析 HEAD。
        }
    }

    @Test("按文件名识别的语言（Makefile / Dockerfile）被统计")
    func filenameBasedLanguagesAreCounted() throws {
        let repository = try makeRepository()
        defer { try? FileManager.default.removeItem(at: repository) }
        try write("all:\n\techo hi\n", to: repository.appendingPathComponent("Makefile"))
        try write("FROM alpine\n", to: repository.appendingPathComponent("Dockerfile"))
        try commit(repository)

        let snapshot = try RepositoryLanguageAnalyzer().analyze(repository: repository)

        #expect(snapshot.languages.map(\.id).sorted() == ["dockerfile", "makefile"])
    }
}

/// `ProjectLanguagesCache` 的容错路径覆盖。
@Suite("ProjectLanguagesCache 容错")
struct ProjectLanguagesCacheFailureTests {

    @Test("缓存目录不可写时写入失败但不影响调用方")
    func unwritableCacheDirectoryIsIgnored() throws {
        // 用一个普通文件占住目录位置，使 createDirectory 必然失败。
        let blocker = FileManager.default.temporaryDirectory
            .appendingPathComponent("LanguagesCacheBlocker-\(UUID().uuidString)", isDirectory: false)
        try Data("not a directory".utf8).write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }

        let cache = ProjectLanguagesCache(directoryURL: blocker.appendingPathComponent("nested", isDirectory: true))
        let key = ProjectLanguagesCacheKey(
            repositoryPath: "/tmp/project",
            headHash: "abc123",
            analyzerVersion: 1
        )
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: key.repositoryPath,
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
        )

        cache.store(snapshot, for: key)

        #expect(cache.load(for: key) == nil)
    }

    @Test("缓存文件内容损坏时按未命中处理")
    func corruptedCacheFileIsIgnored() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LanguagesCacheCorrupt-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = ProjectLanguagesCache(directoryURL: directory)
        let key = ProjectLanguagesCacheKey(
            repositoryPath: "/tmp/project",
            headHash: "abc123",
            analyzerVersion: 1
        )

        // 先写入一份正常缓存，再把缓存文件替换成非法 JSON。
        cache.store(
            ProjectLanguagesSnapshot(repositoryPath: key.repositoryPath, languages: []),
            for: key
        )
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let file = try #require(files.first)
        try Data("not json".utf8).write(to: file)

        #expect(cache.load(for: key) == nil)
    }
}
