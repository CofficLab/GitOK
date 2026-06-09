import Foundation
import OSLog

/// 头像服务：负责获取用户头像 URL
/// 优先级：GitHub API > Gravatar > 默认头像
public actor AvatarService {
    /// 是否启用详细日志输出
    public nonisolated static let verbose = false
    public static let shared = AvatarService()

    private init() {}

    // MARK: - 缓存

    /// 头像 URL 缓存：key 是 email，value 是 avatar URL
    private var avatarCache: [String: URL] = [:]
    private var avatarCacheAccessOrder: [String] = []
    private let maxAvatarCacheEntries = 500

    /// 失败缓存：记录获取失败的头像，避免重复请求
    private var failedCache: [String: Date] = [:]
    private var failedCacheAccessOrder: [String] = []
    private let failedCacheTimeout: TimeInterval = 5 * 60 // 5分钟
    private let maxFailedCacheEntries = 500

    /// 正在进行的请求：同一个用户在列表里重复出现时复用同一个网络请求
    private var pendingFetches: [String: Task<URL?, Never>] = [:]

    // MARK: - 公共方法

    /// 获取头像 URL
    /// - Parameters:
    ///   - name: 用户名
    ///   - email: 邮箱
    ///   - userUseGravatar: 用户是否使用 Gravatar
    /// - Returns: 头像 URL，如果获取失败返回 nil
    public func getAvatarURL(name: String, email: String, userUseGravatar: Bool = false) async -> URL? {
        if Self.verbose {
            os_log("尝试从AvatarService获取头像URL: \(name) <\(email)>，userUseGravatar: \(userUseGravatar)")
        }

        let normalizedEmail = AvatarIdentityRules.normalizeEmail(email)

        // 确定缓存 key：邮箱不为空时用邮箱，否则用用户名
        let cacheKey = AvatarIdentityRules.cacheKey(name: name, email: normalizedEmail)

        if Self.verbose {
            os_log("使用缓存key: \(cacheKey)")
        }

        // 检查是否是 bot 账户
        if let botURL = AvatarIdentityRules.botAvatarURL(email: normalizedEmail, name: name) {
            if Self.verbose {
                os_log("成功获取 bot 账户头像URL: \(botURL)")
            }
            return botURL
        }

        // 检查缓存
        if let cachedURL = avatarCache[cacheKey] {
            markAvatarCacheAccess(cacheKey)
            if Self.verbose {
                os_log("成功获取缓存头像URL: \(cachedURL)")
            }
            return cachedURL
        }

        // 检查失败缓存
        pruneExpiredFailedCache()
        if let failedDate = failedCache[cacheKey],
           Date().timeIntervalSince(failedDate) < failedCacheTimeout {
            markFailedCacheAccess(cacheKey)
            if userUseGravatar {
                if Self.verbose {
                    os_log("失败缓存中获取头像URL，回退到 Gravatar: \(cacheKey)")
                }
                return AvatarIdentityRules.gravatarURL(email: normalizedEmail)
            } else {
                if Self.verbose {
                    os_log("失败缓存中且不允许使用 Gravatar: \(cacheKey)")
                }
                return nil
            }
        }

        // 尝试获取头像
        let avatarURL = await fetchAvatarURL(cacheKey: cacheKey, name: name, email: normalizedEmail)
        if let avatarURL {
            storeAvatarURL(avatarURL, for: cacheKey)
            if Self.verbose {
                os_log("获取头像URL: \(avatarURL.absoluteString)")
            }
            return avatarURL
        }

        // 如果用户允许使用 Gravatar，返回 Gravatar URL
        if userUseGravatar {
            let gravatarURL = AvatarIdentityRules.gravatarURL(email: normalizedEmail)
            storeAvatarURL(gravatarURL, for: cacheKey)
            if Self.verbose {
                os_log("未找到 GitHub 头像，使用 Gravatar: \(gravatarURL.absoluteString)")
            }
            return gravatarURL
        }

        // 用户不允许使用 Gravatar，标记为失败
        storeFailedCacheEntry(for: cacheKey)
        if Self.verbose {
            os_log("未找到头像且不允许使用 Gravatar: \(cacheKey)")
        }
        return nil
    }

    /// 获取 Gravatar URL
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - size: 头像尺寸，默认 64
    /// - Returns: Gravatar URL
    private nonisolated func getGravatarURL(email: String, size: Int = 64) -> URL {
        let url = AvatarIdentityRules.gravatarURL(email: email, size: size)
        if Self.verbose {
            os_log("生成 Gravatar URL: \(url)")
        }

        return url
    }

    // MARK: - 私有方法

    /// 获取头像 URL（优先级策略）
    private func fetchAvatarURL(
        cacheKey: String,
        name: String,
        email: String,
        userUseGravatar: Bool = false
    ) async -> URL? {
        if let pendingFetch = pendingFetches[cacheKey] {
            return await pendingFetch.value
        }

        let fetchTask = Task.detached(priority: .utility) {
            await Self.fetchAvatarURLInBackground(
                name: name,
                email: email,
                userUseGravatar: userUseGravatar
            )
        }
        pendingFetches[cacheKey] = fetchTask
        let url = await fetchTask.value
        pendingFetches[cacheKey] = nil
        return url
    }

    private nonisolated static func fetchAvatarURLInBackground(
        name: String,
        email: String,
        userUseGravatar: Bool
    ) async -> URL? {
        // 优先级 1: 尝试 GitHub API（需要用户名）
        if !name.isEmpty {
            if Self.verbose {
                os_log("尝试从 GitHub API 获取头像: \(name)")
            }
            if let githubURL = await fetchGitHubAvatarURL(username: name) {
                return githubURL
            }
        }

        // 优先级 2: 使用 Gravatar
        if userUseGravatar {
            return AvatarIdentityRules.gravatarURL(email: email)
        }
        return nil
    }

    /// 从 GitHub API 获取头像 URL
    /// - Parameters:
    ///   - username: GitHub 用户名
    /// - Returns: 头像 URL，如果获取失败返回 nil
    private nonisolated static func fetchGitHubAvatarURL(username: String) async -> URL? {
        let urlString = "https://api.github.com/users/\(username)"

        guard let url = URL(string: urlString) else {
            if Self.verbose {
                os_log("无效的 GitHub API URL: \(urlString)")
            }
            return nil
        }

        do {
            if Self.verbose {
                os_log("请求 GitHub API: \(urlString)")
            }

            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let avatarURL = json["avatar_url"] as? String,
               let url = URL(string: avatarURL) {

                if Self.verbose {
                    os_log("成功从 GitHub API 获取头像: \(url)")
                }
                return url
            } else {
                if Self.verbose {
                    os_log("GitHub API 响应中没有找到头像URL")
                }
            }
        } catch {
            if Self.verbose {
                os_log("GitHub API 请求失败: \(username) - \(error.localizedDescription)")
            }
        }

        return nil
    }

    /// 清除缓存
    public func clearCache() {
        avatarCache.removeAll()
        avatarCacheAccessOrder.removeAll()
        failedCache.removeAll()
        failedCacheAccessOrder.removeAll()

        if Self.verbose {
            os_log("已清除头像缓存")
        }
    }

    private func storeAvatarURL(_ url: URL, for cacheKey: String) {
        avatarCache[cacheKey] = url
        markAvatarCacheAccess(cacheKey)
        pruneAvatarCacheIfNeeded()
    }

    private func storeFailedCacheEntry(for cacheKey: String) {
        failedCache[cacheKey] = Date()
        markFailedCacheAccess(cacheKey)
        pruneFailedCacheIfNeeded()
    }

    private func markAvatarCacheAccess(_ cacheKey: String) {
        avatarCacheAccessOrder.removeAll { $0 == cacheKey }
        avatarCacheAccessOrder.append(cacheKey)
    }

    private func markFailedCacheAccess(_ cacheKey: String) {
        failedCacheAccessOrder.removeAll { $0 == cacheKey }
        failedCacheAccessOrder.append(cacheKey)
    }

    private func pruneAvatarCacheIfNeeded() {
        while avatarCacheAccessOrder.count > maxAvatarCacheEntries,
              let oldestKey = avatarCacheAccessOrder.first {
            avatarCacheAccessOrder.removeFirst()
            avatarCache.removeValue(forKey: oldestKey)
        }
    }

    private func pruneFailedCacheIfNeeded() {
        while failedCacheAccessOrder.count > maxFailedCacheEntries,
              let oldestKey = failedCacheAccessOrder.first {
            failedCacheAccessOrder.removeFirst()
            failedCache.removeValue(forKey: oldestKey)
        }
    }

    private func pruneExpiredFailedCache() {
        let now = Date()
        failedCache = failedCache.filter { _, failedDate in
            now.timeIntervalSince(failedDate) < failedCacheTimeout
        }
        failedCacheAccessOrder.removeAll { failedCache[$0] == nil }
    }
}
