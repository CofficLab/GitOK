import Foundation
import ProviderProjectLanguages
import Testing
@testable import PluginProjectLanguages

@Suite("LocalProjectLanguagesProvider")
struct LocalProjectLanguagesProviderTests {
    @Test("cancels stale analysis and publishes only the newest project")
    @MainActor
    func cancelsStaleAnalysis() async throws {
        let analyzer = ControlledAnalyzer()
        let cacheDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let cache = ProjectLanguagesCache(directoryURL: cacheDirectory)
        let provider = LocalProjectLanguagesProvider(
            analyzer: analyzer,
            cache: cache
        )
        let firstRepository = URL(fileURLWithPath: "/tmp/first-project")
        let secondRepository = URL(fileURLWithPath: "/tmp/second-project")

        provider.refresh(for: firstRepository)
        let firstAnalysisStarted = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(
                    returning: analyzer.firstAnalysisStarted.wait(timeout: .now() + 2) == .success
                )
            }
        }
        #expect(firstAnalysisStarted)

        provider.refresh(for: secondRepository)
        for _ in 0..<100 {
            if provider.currentSnapshot?.repositoryPath == secondRepository.path { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(provider.currentSnapshot?.repositoryPath == secondRepository.path)

        analyzer.releaseFirstAnalysis.signal()
        try await Task.sleep(for: .milliseconds(50))
        #expect(provider.currentSnapshot?.repositoryPath == secondRepository.path)
        #expect(cache.load(for: ProjectLanguagesCacheKey(
            repositoryPath: secondRepository.path,
            headHash: secondRepository.lastPathComponent,
            analyzerVersion: 1
        ))?.repositoryPath == secondRepository.path)
    }

    @Test("loads a clean snapshot from disk without re-analyzing")
    @MainActor
    func loadsCachedSnapshot() async throws {
        let analyzer = ControlledAnalyzer()
        let cacheDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }
        let cache = ProjectLanguagesCache(directoryURL: cacheDirectory)
        let repository = URL(fileURLWithPath: "/tmp/cached-project")
        let key = ProjectLanguagesCacheKey(
            repositoryPath: repository.path,
            headHash: repository.lastPathComponent,
            analyzerVersion: 1
        )
        let cachedSnapshot = ProjectLanguagesSnapshot(
            repositoryPath: repository.path,
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 10)]
        )
        cache.store(cachedSnapshot, for: key)

        let provider = LocalProjectLanguagesProvider(analyzer: analyzer, cache: cache)
        provider.refresh(for: repository)
        for _ in 0..<100 {
            if provider.currentSnapshot != nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(provider.currentSnapshot == cachedSnapshot)
        #expect(analyzer.numberOfAnalyses == 0)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalProjectLanguagesProviderTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private final class ControlledAnalyzer: RepositoryLanguageAnalyzing, @unchecked Sendable {
        let firstAnalysisStarted = DispatchSemaphore(value: 0)
        let releaseFirstAnalysis = DispatchSemaphore(value: 0)
        private let lock = NSLock()
        private var analysisCount = 0

        var numberOfAnalyses: Int {
            lock.lock()
            defer { lock.unlock() }
            return analysisCount
        }

        func context(for repository: URL) throws -> RepositoryLanguageAnalysisContext {
            RepositoryLanguageAnalysisContext(
                cacheKey: ProjectLanguagesCacheKey(
                    repositoryPath: repository.path,
                    headHash: repository.lastPathComponent,
                    analyzerVersion: 1
                ),
                isWorktreeClean: true
            )
        }

        func analyze(repository: URL) throws -> ProjectLanguagesSnapshot {
            let isFirstAnalysis: Bool
            lock.lock()
            analysisCount += 1
            isFirstAnalysis = analysisCount == 1
            lock.unlock()

            if isFirstAnalysis {
                firstAnalysisStarted.signal()
                releaseFirstAnalysis.wait()
            }

            return ProjectLanguagesSnapshot(
                repositoryPath: repository.path,
                languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 1)]
            )
        }
    }
}
