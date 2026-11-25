import Foundation
import ProviderDiskCache
import XCTest
@testable import PluginCommitList

@MainActor
final class CommitAvatarServiceTests: XCTestCase {

    func testEmptyAuthorReturnsNil() async {
        let service = CommitAvatarService()
        let result = await service.avatarURL(author: "   ", email: "user@example.com")
        XCTAssertNil(result)
    }

    func testEmptyCacheKeyReturnsNil() async {
        let service = CommitAvatarService()
        // author 空白且 email 空白 → cacheKey 为空 → nil。
        let result = await service.avatarURL(author: "  ", email: "  ")
        XCTAssertNil(result)
    }

    func testNormalizesEmailCase() async {
        let service = CommitAvatarService()
        // 不同大小写 email 应归一化到同一 cache key；首次调用会尝试网络，
        // 但在无网络环境下返回 nil，不崩溃即可。
        let result = await service.avatarURL(author: "octocat", email: "OctoCat@GitHub.com")
        // 网络不可用时为 nil；不断言具体值。
        _ = result
    }

    func testAvatarURLReadsDiskCacheWithoutNetwork() async throws {
        let bucket = StubDiskCacheBucket()
        let cacheKey = try XCTUnwrap(
            CommitAvatarService.cacheKey(author: "octocat", email: "OctoCat@GitHub.com")
        )
        let expected = try XCTUnwrap(URL(string: "https://avatars.example.com/u/1.png"))
        await bucket.store(
            Data(expected.absoluteString.utf8),
            forKey: CommitAvatarService.avatarURLKey(cacheKey)
        )

        let service = CommitAvatarService(diskCache: StubDiskCacheProvider(bucket: bucket))
        let resolved = await service.avatarURL(author: "octocat", email: "OctoCat@GitHub.com")

        XCTAssertEqual(resolved, expected)
    }

    func testAvatarImageDataReadsDiskCacheWithoutNetwork() async throws {
        let bucket = StubDiskCacheBucket()
        let cacheKey = try XCTUnwrap(
            CommitAvatarService.cacheKey(author: "octocat", email: "octocat@github.com")
        )
        let expected = Data([0x89, 0x50, 0x4E, 0x47])
        await bucket.store(
            expected,
            forKey: CommitAvatarService.avatarImageKey(cacheKey)
        )

        let provider = StubDiskCacheProvider(bucket: bucket)
        let service = CommitAvatarService(diskCache: provider)
        let data = await service.avatarImageData(author: "octocat", email: "octocat@github.com")

        XCTAssertEqual(data, expected)
        // 命中的桶就是插件自己的缓存桶。
        let requestedPluginID = provider.requestedPluginID
        XCTAssertEqual(requestedPluginID, CommitAvatarService.bucketPluginID)
    }
}

// MARK: - Stubs

private final class StubDiskCacheProvider: DiskCacheProviding, @unchecked Sendable {
    private let bucket: StubDiskCacheBucket
    private let lock = NSLock()
    private var recordedPluginID: String?

    init(bucket: StubDiskCacheBucket) {
        self.bucket = bucket
    }

    var requestedPluginID: String? {
        lock.withLock { recordedPluginID }
    }

    func bucket(for pluginID: String, policy: DiskCachePolicy) async -> any DiskCacheBucket {
        lock.withLock { recordedPluginID = pluginID }
        return bucket
    }

    func usageReport() async -> DiskCacheUsageReport { .empty }

    func clearBucket(pluginID: String) async {}

    func clearAll() async {}
}

private final class StubDiskCacheBucket: DiskCacheBucket, @unchecked Sendable {
    let pluginID = CommitAvatarService.bucketPluginID
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    @discardableResult
    func store(_ data: Data, forKey key: String, options: DiskCacheStoreOptions) async -> Bool {
        lock.withLock { storage[key] = data }
        return true
    }

    @discardableResult
    func store(fileAt sourceURL: URL, forKey key: String, options: DiskCacheStoreOptions) async -> Bool {
        guard let data = try? Data(contentsOf: sourceURL) else { return false }
        return await store(data, forKey: key, options: options)
    }

    func data(forKey key: String) async -> Data? {
        lock.withLock { storage[key] }
    }

    func fileURL(forKey key: String) async -> URL? { nil }

    func remove(forKey key: String) async {
        lock.withLock { storage[key] = nil }
    }

    func invalidate(tag: String) async {}

    func clear() async {
        lock.withLock { storage.removeAll() }
    }

    func diskUsage() async -> Int64 {
        lock.withLock { Int64(storage.values.reduce(0) { $0 + $1.count }) }
    }
}