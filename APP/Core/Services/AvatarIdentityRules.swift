import CryptoKit
import Foundation

enum AvatarIdentityRules {
    static let botAvatarCache: [String: String] = [
        "dependabot[bot]": "https://github.com/dependabot.png",
        "github-actions[bot]": "https://github.com/github-actions.png",
        "github-pages[bot]": "https://github.com/github-pages.png",
        "renovate[bot]": "https://github.com/renovatebot.png",
        "greenkeeper[bot]": "https://github.com/greenkeeper.png"
    ]

    static func normalizeEmail(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func cacheKey(name: String, email: String) -> String {
        let normalizedEmail = normalizeEmail(email)
        return normalizedEmail.isEmpty ? name : normalizedEmail
    }

    static func gravatarURL(email: String, size: Int = 64) -> URL {
        let hash = md5Hash(string: normalizeEmail(email))

        var components = URLComponents(string: "https://www.gravatar.com/avatar/\(hash)")!
        components.queryItems = [
            URLQueryItem(name: "s", value: "\(size)"),
            URLQueryItem(name: "d", value: "identicon")
        ]

        return components.url!
    }

    static func botAvatarURL(email: String, name: String) -> URL? {
        let normalizedEmail = normalizeEmail(email)

        let botEmailPattern = #"^(\d+)\+([\w-]+)\[bot\]@users\.noreply\.github\.com$"#
        if let regex = try? NSRegularExpression(pattern: botEmailPattern),
           let match = regex.firstMatch(in: normalizedEmail, range: NSRange(normalizedEmail.startIndex..., in: normalizedEmail)) {
            let botName = (normalizedEmail as NSString).substring(with: match.range(at: 2))
            return URL(string: "https://github.com/\(botName).png")
        }

        let botName = name.replacingOccurrences(of: "\\[bot\\]", with: "[bot]", options: .regularExpression)
        if let botAvatarURL = botAvatarCache[botName] {
            return URL(string: botAvatarURL)
        }

        return nil
    }

    private static func md5Hash(string: String) -> String {
        let hash = Insecure.MD5.hash(data: Data(string.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
