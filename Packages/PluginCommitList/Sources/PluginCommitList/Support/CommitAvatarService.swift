import Foundation
import ProviderDiskCache

/// 提交作者头像服务：解析 GitHub 头像地址并下载图片。
///
/// 解析结果与图片数据都落宿主注册的磁盘缓存桶（`DiskCacheProviding`），
/// 设置里的「缓存」页可查看体积并按桶清理；内存层只做本次运行内的短路。
actor CommitAvatarService {
    static let bucketPluginID = "com.coffic.gitok.plugin.commit-list"
    /// 头像体积很小；给桶设个小水位，避免异常数据把缓存撑大。
    static let cachePolicy = DiskCachePolicy(
        sizeLimit: 20 * 1024 * 1024,
        targetSize: 16 * 1024 * 1024
    )

    private let diskCache: (any DiskCacheProviding)?
    private var bucket: (any DiskCacheBucket)?

    private var avatarURLCache: [String: URL] = [:]
    private var imageCache: [String: Data] = [:]
    private var failedCache: [String: Date] = [:]
    private var pendingURLFetches: [String: Task<URL?, Never>] = [:]
    private var pendingImageFetches: [String: Task<Data?, Never>] = [:]

    private let failedCacheTimeout: TimeInterval = 5 * 60
    private let urlTTL: TimeInterval = 7 * 24 * 3600
    private let imageTTL: TimeInterval = 30 * 24 * 3600

    init(diskCache: (any DiskCacheProviding)? = nil) {
        self.diskCache = diskCache
    }

    func avatarImageData(author: String, email: String) async -> Data? {
        guard let cacheKey = Self.cacheKey(author: author, email: email) else { return nil }
        if let cached = imageCache[cacheKey] {
            return cached
        }
        if let pending = pendingImageFetches[cacheKey] {
            return await pending.value
        }

        let normalizedAuthor = Self.normalizedAuthor(author)
        let fetch = Task {
            await self.loadImage(cacheKey: cacheKey, author: normalizedAuthor)
        }
        pendingImageFetches[cacheKey] = fetch
        let result = await fetch.value
        pendingImageFetches[cacheKey] = nil
        return result
    }

    func avatarURL(author: String, email: String) async -> URL? {
        guard let cacheKey = Self.cacheKey(author: author, email: email) else { return nil }
        return await resolveAvatarURL(cacheKey: cacheKey, author: Self.normalizedAuthor(author))
    }

    // MARK: - Cache Keys

    nonisolated static func cacheKey(author: String, email: String) -> String? {
        let normalizedAuthor = normalizedAuthor(author)
        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let key = normalizedEmail.isEmpty ? normalizedAuthor.lowercased() : normalizedEmail
        guard !key.isEmpty, !normalizedAuthor.isEmpty else { return nil }
        return key
    }

    nonisolated static func avatarURLKey(_ cacheKey: String) -> String {
        "avatar-url/\(cacheKey)"
    }

    nonisolated static func avatarImageKey(_ cacheKey: String) -> String {
        "avatar-image/\(cacheKey)"
    }

    private nonisolated static func normalizedAuthor(_ author: String) -> String {
        author.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Image

    private func loadImage(cacheKey: String, author: String) async -> Data? {
        if let cached = imageCache[cacheKey] {
            return cached
        }
        let bucket = await diskBucket()
        if let bucket,
           let data = await bucket.data(forKey: Self.avatarImageKey(cacheKey)) {
            imageCache[cacheKey] = data
            return data
        }
        guard let url = await resolveAvatarURL(cacheKey: cacheKey, author: author),
              let data = await Self.fetchImageData(from: url) else {
            return nil
        }
        imageCache[cacheKey] = data
        if let bucket {
            await bucket.store(
                data,
                forKey: Self.avatarImageKey(cacheKey),
                options: DiskCacheStoreOptions(ttl: .seconds(imageTTL))
            )
        }
        return data
    }

    // MARK: - URL Resolution

    private func resolveAvatarURL(cacheKey: String, author: String) async -> URL? {
        if let cached = avatarURLCache[cacheKey] {
            return cached
        }
        if let failedAt = failedCache[cacheKey], Date().timeIntervalSince(failedAt) < failedCacheTimeout {
            return nil
        }

        let bucket = await diskBucket()
        if let bucket,
           let data = await bucket.data(forKey: Self.avatarURLKey(cacheKey)),
           let url = URL(string: String(decoding: data, as: UTF8.self)) {
            avatarURLCache[cacheKey] = url
            return url
        }

        if let pending = pendingURLFetches[cacheKey] {
            return await pending.value
        }

        let fetch = Task.detached(priority: .utility) {
            await Self.fetchGitHubAvatarURL(username: author)
        }
        pendingURLFetches[cacheKey] = fetch
        let result = await fetch.value
        pendingURLFetches[cacheKey] = nil

        if let result {
            avatarURLCache[cacheKey] = result
            if let bucket {
                await bucket.store(
                    Data(result.absoluteString.utf8),
                    forKey: Self.avatarURLKey(cacheKey),
                    options: DiskCacheStoreOptions(ttl: .seconds(urlTTL))
                )
            }
        } else {
            failedCache[cacheKey] = Date()
        }
        return result
    }

    private func diskBucket() async -> (any DiskCacheBucket)? {
        if let bucket {
            return bucket
        }
        guard let diskCache else { return nil }
        let resolved = await diskCache.bucket(for: Self.bucketPluginID, policy: Self.cachePolicy)
        bucket = resolved
        return resolved
    }

    // MARK: - Network

    private nonisolated static func fetchGitHubAvatarURL(username: String) async -> URL? {
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let endpoint = URL(string: "https://api.github.com/users/\(encodedUsername)") else {
            return nil
        }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 5
        request.setValue("GitOK", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode) else {
                return nil
            }
            let payload = try JSONDecoder().decode(GitHubUserResponse.self, from: data)
            return URL(string: payload.avatarURL)
        } catch {
            return nil
        }
    }

    private nonisolated static func fetchImageData(from url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("GitOK", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  !data.isEmpty else {
                return nil
            }
            return data
        } catch {
            return nil
        }
    }
}

private struct GitHubUserResponse: Decodable {
    let avatarURL: String

    enum CodingKeys: String, CodingKey {
        case avatarURL = "avatar_url"
    }
}