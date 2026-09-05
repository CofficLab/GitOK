import Foundation

/// 提交作者头像服务：优先从 GitHub 获取头像 URL，并在列表生命周期内缓存结果。
actor CommitAvatarService {
    static let shared = CommitAvatarService()

    private var avatarCache: [String: URL] = [:]
    private var failedCache: [String: Date] = [:]
    private var pendingFetches: [String: Task<URL?, Never>] = [:]
    private let failedCacheTimeout: TimeInterval = 5 * 60

    func avatarURL(author: String, email: String) async -> URL? {
        let normalizedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cacheKey = normalizedEmail.isEmpty ? normalizedAuthor.lowercased() : normalizedEmail
        guard !cacheKey.isEmpty, !normalizedAuthor.isEmpty else { return nil }

        if let cached = avatarCache[cacheKey] {
            return cached
        }
        if let failedAt = failedCache[cacheKey], Date().timeIntervalSince(failedAt) < failedCacheTimeout {
            return nil
        }
        if let pending = pendingFetches[cacheKey] {
            return await pending.value
        }

        let fetch = Task.detached(priority: .utility) {
            await Self.fetchGitHubAvatarURL(username: normalizedAuthor)
        }
        pendingFetches[cacheKey] = fetch
        let result = await fetch.value
        pendingFetches[cacheKey] = nil

        if let result {
            avatarCache[cacheKey] = result
        } else {
            failedCache[cacheKey] = Date()
        }
        return result
    }

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
}

private struct GitHubUserResponse: Decodable {
    let avatarURL: String

    enum CodingKeys: String, CodingKey {
        case avatarURL = "avatar_url"
    }
}
