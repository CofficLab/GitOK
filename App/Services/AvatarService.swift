import Combine
import CryptoKit
import Foundation
import OSLog

/// 头像服务：负责获取用户头像 URL
/// 优先级：GitHub API > Gravatar > 默认头像
@MainActor
class AvatarService: ObservableObject {
    static let shared = AvatarService()

    private let logger = OSLog(subsystem: "GitOK.AvatarService", category: "Avatar")

    private init() {}

    // MARK: - 缓存

    /// 头像 URL 缓存：key 是 email，value 是 avatar URL
    private var avatarCache: [String: URL] = [:]

    /// 失败缓存：记录获取失败的头像，避免重复请求
    private var failedCache: [String: Date] = [:]
    private let failedCacheTimeout: TimeInterval = 5 * 60 // 5分钟

    /// Bot 头像缓存
    private let botAvatarCache: [String: String] = [
        "dependabot[bot]": "https://github.com/dependabot.png",
        "github-actions[bot]": "https://github.com/github-actions.png",
        "github-pages[bot]": "https://github.com/github-pages.png",
        "renovate[bot]": "https://github.com/renovatebot.png",
        "greenkeeper[bot]": "https://github.com/greenkeeper.png"
    ]

    // MARK: - 公共方法

    /// 获取头像 URL
    /// - Parameters:
    ///   - name: 用户名
    ///   - email: 邮箱
    /// - Returns: 头像 URL，如果获取失败返回 nil
    func getAvatarURL(name: String, email: String) async -> URL? {
        let normalizedEmail = normalizeEmail(email)

        // 检查是否是 bot 账户
        if let botURL = checkBotAccount(email: normalizedEmail, name: name) {
            return botURL
        }

        // 检查缓存
        if let cachedURL = avatarCache[normalizedEmail] {
            return cachedURL
        }

        // 检查失败缓存
        if let failedDate = failedCache[normalizedEmail],
           Date().timeIntervalSince(failedDate) < failedCacheTimeout {
            return nil
        }

        // 尝试获取头像
        if let avatarURL = await fetchAvatarURL(name: name, email: normalizedEmail) {
            avatarCache[normalizedEmail] = avatarURL
            return avatarURL
        }

        // 标记为失败
        failedCache[normalizedEmail] = Date()
        return nil
    }

    /// 获取 Gravatar URL
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - size: 头像尺寸，默认 64
    /// - Returns: Gravatar URL
    func getGravatarURL(email: String, size: Int = 64) -> URL {
        let normalizedEmail = normalizeEmail(email)
        let hash = md5Hash(string: normalizedEmail)

        var components = URLComponents(string: "https://www.gravatar.com/avatar/\(hash)")!
        components.queryItems = [
            URLQueryItem(name: "s", value: "\(size)"),
            URLQueryItem(name: "d", value: "identicon")
        ]

        return components.url!
    }

    // MARK: - 私有方法

    /// 获取头像 URL（优先级策略）
    private func fetchAvatarURL(name: String, email: String) async -> URL? {
        // 优先级 1: 尝试 GitHub API（需要用户名）
        if !name.isEmpty, let githubURL = await fetchGitHubAvatarURL(username: name) {
            return githubURL
        }

        // 优先级 2: 使用 Gravatar
        return getGravatarURL(email: email)
    }

    /// 从 GitHub API 获取头像 URL
    /// - Parameter username: GitHub 用户名
    /// - Returns: 头像 URL，如果获取失败返回 nil
    private func fetchGitHubAvatarURL(username: String) async -> URL? {
        let urlString = "https://api.github.com/users/\(username)"

        guard let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let avatarURL = json["avatar_url"] as? String,
               let url = URL(string: avatarURL) {

                return url
            }
        } catch {
            os_log("%{public}⚠️ Failed to fetch GitHub avatar for %{public}:", username, error.localizedDescription)
        }

        return nil
    }

    /// 检查是否是 bot 账户并返回头像
    /// - Parameters:
    ///   - email: 邮箱
    ///   - name: 用户名
    /// - Returns: bot 头像 URL，如果不是 bot 返回 nil
    private func checkBotAccount(email: String, name: String) -> URL? {
        // 检查 bot 邮箱模式
        let botEmailPattern = #"^(\d+)\+([\w-]+)\[bot\]@users\.noreply\.github\.com$"#
        if let regex = try? NSRegularExpression(pattern: botEmailPattern),
           let match = regex.firstMatch(in: email, range: NSRange(email.startIndex..., in: email)) {

            let botName = (email as NSString).substring(with: match.range(at: 2))

            // 从邮箱中提取 bot 名称（例如 "dependabot[bot]"）
            if let botURL = URL(string: "https://github.com/\(botName).png") {
                return botURL
            }
        }

        // 检查预定义的 bot 名称
        let botName = name.replacingOccurrences(of: "\\[bot\\]", with: "[bot]", options: .regularExpression)
        if let botAvatarURL = botAvatarCache[botName],
           let url = URL(string: botAvatarURL) {
            return url
        }

        return nil
    }

    /// 标准化邮箱地址
    /// - Parameter email: 原始邮箱
    /// - Returns: 标准化后的邮箱（小写、去除空格）
    private func normalizeEmail(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 计算 MD5 哈希
    /// - Parameter string: 输入字符串
    /// - Returns: MD5 哈希值（小写十六进制）
    private func md5Hash(string: String) -> String {
        let hash = Insecure.MD5.hash(data: Data(string.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// 清除缓存
    func clearCache() {
        avatarCache.removeAll()
        failedCache.removeAll()
    }
}
