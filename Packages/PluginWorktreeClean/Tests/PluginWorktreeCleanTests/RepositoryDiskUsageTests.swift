import Foundation
import KitGit
import Testing
@testable import PluginWorktreeClean

@Suite("RepositoryDiskUsage")
struct RepositoryDiskUsageTests {

    @Test("calculate returns nil for non-directory")
    func calculateNonDirectory() {
        let missing = URL(fileURLWithPath: "/tmp/gitok-missing-\(UUID().uuidString)")
        #expect(RepositoryDiskUsage.calculate(at: missing) == nil)
    }

    @Test("calculate sums allocated sizes in a temp directory")
    func calculateSumsFiles() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gitok-disk-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("hello\n".utf8).write(to: root.appendingPathComponent("a.txt"))
        try Data("world\n".utf8).write(to: root.appendingPathComponent("b.txt"))

        let total = try #require(RepositoryDiskUsage.calculate(at: root))
        #expect(total > 0)
    }

    @Test("calculate honors pre-cancelled request")
    func calculateCancelled() {
        let cancellation = GitProcessCancellation()
        cancellation.cancel()
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
        #expect(RepositoryDiskUsage.calculate(at: root, cancellation: cancellation) == nil)
    }

    @Test("cache round-trips byte count")
    func cacheRoundTrip() throws {
        let caches = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gitok-cache-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: caches) }
        let cache = RepositoryDiskUsageCache(directoryURL: caches)
        let repo = URL(fileURLWithPath: "/tmp/some-repo")

        #expect(cache.load(at: repo) == nil)
        cache.store(123_456, at: repo)
        let value = try #require(cache.load(at: repo))
        #expect(value.byteCount == 123_456)
        #expect(value.repositoryPath == repo.standardizedFileURL.path)
    }

    @Test("cache rejects negative byte counts on store")
    func cacheRejectsNegative() throws {
        let caches = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("gitok-cache2-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: caches) }
        let cache = RepositoryDiskUsageCache(directoryURL: caches)
        let repo = URL(fileURLWithPath: "/tmp/another-repo")
        cache.store(-5, at: repo)
        #expect(cache.load(at: repo) == nil)
    }
}
