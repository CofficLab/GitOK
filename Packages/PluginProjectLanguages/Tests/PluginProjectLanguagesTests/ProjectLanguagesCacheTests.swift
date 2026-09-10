import Foundation
import ProviderProjectLanguages
import Testing
@testable import PluginProjectLanguages

@Suite("ProjectLanguagesCache")
struct ProjectLanguagesCacheTests {
    @Test("stores and loads a snapshot for the exact cache key")
    func storesAndLoadsSnapshot() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = ProjectLanguagesCache(directoryURL: directory)
        let key = ProjectLanguagesCacheKey(
            repositoryPath: "/tmp/project",
            headHash: "abc123",
            analyzerVersion: 1
        )
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: key.repositoryPath,
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 42)]
        )

        cache.store(snapshot, for: key)

        #expect(cache.load(for: key) == snapshot)
    }

    @Test("misses when HEAD or analyzer version changes")
    func missesForChangedKey() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = ProjectLanguagesCache(directoryURL: directory)
        let key = ProjectLanguagesCacheKey(
            repositoryPath: "/tmp/project",
            headHash: "abc123",
            analyzerVersion: 1
        )
        let snapshot = ProjectLanguagesSnapshot(
            repositoryPath: key.repositoryPath,
            languages: [ProjectLanguage(id: "swift", name: "Swift", byteCount: 42)]
        )
        cache.store(snapshot, for: key)

        #expect(cache.load(for: ProjectLanguagesCacheKey(
            repositoryPath: key.repositoryPath,
            headHash: "def456",
            analyzerVersion: key.analyzerVersion
        )) == nil)
        #expect(cache.load(for: ProjectLanguagesCacheKey(
            repositoryPath: key.repositoryPath,
            headHash: key.headHash,
            analyzerVersion: 2
        )) == nil)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectLanguagesCacheTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
