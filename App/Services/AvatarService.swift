import Combine
import CryptoKit
import Foundation
import MagicKit
import OSLog

/// 头像服务：负责获取用户头像 URL
/// 优先级：GitHub API > Gravatar > 默认头像
@MainActor
class AvatarService: ObservableObject, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    static let verbose = true
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
    ///   - userUseGravatar: 用户是否使用 Gravatar
    /// - Returns: 头像 URL，如果获取失败返回 nil
    func getAvatarURL(name: String, email: String, userUseGravatar: Bool = false) async -> URL? {
        if Self.verbose {
            os_log("\(self.t)🔍 尝试从AvatarService获取头像URL: \(name) <\(email)>，userUseGravatar: \(userUseGravatar)")
        }

        let normalizedEmail = normalizeEmail(email)

        // 确定缓存 key：邮箱不为空时用邮箱，否则用用户名
        let cacheKey = normalizedEmail.isEmpty ? name : normalizedEmail

        if Self.verbose {
            os_log("\(self.t)🔑 使用缓存key: \(cacheKey)")
        }

        // 检查是否是 bot 账户
        if let botURL = checkBotAccount(email: normalizedEmail, name: name) {
            if Self.verbose {
                os_log("\(self.t)✅ 成功获取 bot 账户头像URL: \(botURL)")
            }
            return botURL
        }

        // 检查缓存
        if let cachedURL = avatarCache[cacheKey] {
            if Self.verbose {
                os_log("\(self.t)✅ 成功获取缓存头像URL: \(cachedURL)")
            }
            return cachedURL
        }

        // 检查失败缓存
        if let failedDate = failedCache[cacheKey],
           Date().timeIntervalSince(failedDate) < failedCacheTimeout {
            if userUseGravatar {
                if Self.verbose {
                    os_log("\(self.t)❌ 失败缓存中获取头像URL，回退到 Gravatar: \(cacheKey)")
                }
                return getGravatarURL(email: normalizedEmail)
            } else {
                if Self.verbose {
                    os_log("\(self.t)❌ 失败缓存中且不允许使用 Gravatar: \(cacheKey)")
                }
                return nil
            }
        }

        // 尝试获取头像
        if let avatarURL = await fetchAvatarURL(name: name, email: normalizedEmail) {
            avatarCache[cacheKey] = avatarURL
            if Self.verbose {
                os_log("\(self.t)✅ 获取头像URL: \(avatarURL.absoluteString)")
            }
            return avatarURL
        }

        // 如果用户允许使用 Gravatar，返回 Gravatar URL
        if userUseGravatar {
            let gravatarURL = getGravatarURL(email: normalizedEmail)
            avatarCache[cacheKey] = gravatarURL
            if Self.verbose {
                os_log("\(self.t)🔄 未找到 GitHub 头像，使用 Gravatar: \(gravatarURL.absoluteString)")
            }
            return gravatarURL
        }

        // 用户不允许使用 Gravatar，标记为失败
        failedCache[cacheKey] = Date()
        if Self.verbose {
            os_log("\(self.t)❌ 未找到头像且不允许使用 Gravatar: \(cacheKey)")
        }
        return nil
    }

    /// 获取 Gravatar URL
    /// - Parameters:
    ///   - email: 邮箱地址
    ///   - size: 头像尺寸，默认 64
    /// - Returns: Gravatar URL
    private func getGravatarURL(email: String, size: Int = 64) -> URL {
        let normalizedEmail = normalizeEmail(email)
        let hash = md5Hash(string: normalizedEmail)

        var components = URLComponents(string: "https://www.gravatar.com/avatar/\(hash)")!
        components.queryItems = [
            URLQueryItem(name: "s", value: "\(size)"),
            URLQueryItem(name: "d", value: "identicon")
        ]

        let url = components.url!
        if Self.verbose {
            os_log("\(self.t)🔄 生成 Gravatar URL: \(url)")
        }

        return url
    }

    // MARK: - 私有方法

    /// 获取头像 URL（优先级策略）
    private func fetchAvatarURL(name: String, email: String, userUseGravatar: Bool = false) async -> URL? {
        // 优先级 1: 尝试 GitHub API（需要用户名）
        if !name.isEmpty {
            if Self.verbose {
                os_log("\(self.t)🔍 尝试从 GitHub API 获取头像: \(name)")
            }
            if let githubURL = await fetchGitHubAvatarURL(username: name) {
                return githubURL
            }
        }

        // 优先级 2: 使用 Gravatar
        if userUseGravatar {
            return getGravatarURL(email: email)
        }
        return nil
    }

    /// 从 GitHub API 获取头像 URL
    /// - Parameters:
    ///   - username: GitHub 用户名
    /// - Returns: 头像 URL，如果获取失败返回 nil
    private func fetchGitHubAvatarURL(username: String) async -> URL? {
        let urlString = "https://api.github.com/users/\(username)"

        guard let url = URL(string: urlString) else {
            if Self.verbose {
                os_log("\(self.t)❌ 无效的 GitHub API URL: \(urlString)")
            }
            return nil
        }

        do {
            if Self.verbose {
                os_log("\(self.t)🌐 请求 GitHub API: \(urlString)")
            }

            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let avatarURL = json["avatar_url"] as? String,
               let url = URL(string: avatarURL) {

                if Self.verbose {
                    os_log("\(self.t)✅ 成功从 GitHub API 获取头像: \(url)")
                }
                return url
            } else {
                if Self.verbose {
                    os_log("\(self.t)❌ GitHub API 响应中没有找到头像URL")
                }
            }
        } catch {
            if Self.verbose {
                os_log("\(self.t)❌ GitHub API 请求失败: \(username) - \(error.localizedDescription)")
            }
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
                if Self.verbose {
                    os_log("\(self.t)🤖 识别到邮箱模式的 bot 账户: \(botName)")
                }
                return botURL
            }
        }

        // 检查预定义的 bot 名称
        let botName = name.replacingOccurrences(of: "\\[bot\\]", with: "[bot]", options: .regularExpression)
        if let botAvatarURL = botAvatarCache[botName],
           let url = URL(string: botAvatarURL) {
            if Self.verbose {
                os_log("\(self.t)🤖 识别到预定义 bot 账户: \(botName)")
            }
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

        if Self.verbose {
            os_log("\(self.t)🧹 已清除头像缓存")
        }
    }
}
