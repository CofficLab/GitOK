import Foundation
import OSLog

/// 版本检查服务（支持多 URL fallback）
@MainActor
public class UpdateChecker: ObservableObject {
    nonisolated public static let emoji = "🔍"

    @Published public var isChecking = false
    @Published public var latestVersion: UpdateInfo?
    @Published public var hasError = false
    @Published public var errorMessage: String?

    private let session = URLSession.shared

    // URL fallback 策略：官网 API → GitHub API
    private let primaryURL = "https://api.kuaiyizhi.cn/gitok/version"
    private let fallbackURL = "https://api.github.com/repos/CofficLab/GitOK/releases/latest"

    public init() {}

    /// 检查更新（支持多 URL fallback）
    public func checkForUpdates() async {
        isChecking = true
        hasError = false
        errorMessage = nil

        let urls = [primaryURL, fallbackURL]

        for url in urls {
            do {
                let updateInfo = try await fetchUpdateInfo(from: url)
                latestVersion = updateInfo
                os_log(.info, "[UpdateChecker] ✓ Successfully fetched from %{public}s", url)
                isChecking = false
                return
            } catch {
                os_log(.error, "[UpdateChecker] ✗ Failed from %{public}s: %{public}s", url, error.localizedDescription)
                continue
            }
        }

        // 所有 URL 都失败
        hasError = true
        errorMessage = "无法检查更新，请检查网络连接"
        isChecking = false
    }

    /// 从指定 URL 获取更新信息
    private func fetchUpdateInfo(from urlString: String) async throws -> UpdateInfo {
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10  // 10秒超时

        // GitHub API 需要设置 Accept header
        if urlString.contains("api.github.com") {
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.networkError
        }

        // 根据不同 API 解析
        if urlString.contains("api.kuaiyizhi.cn") {
            return try parseOfficialAPI(data)
        } else {
            return try parseGitHubAPI(data)
        }
    }

    /// 解析官网 API 响应
    private func parseOfficialAPI(_ data: Data) throws -> UpdateInfo {
        let json = try JSONDecoder().decode(OfficialAPIResponse.self, from: data)
        return UpdateInfo(
            version: json.version,
            buildNumber: json.buildNumber,
            releaseDate: json.releaseDate,
            downloadUrls: json.downloadUrls,
            releaseNotes: json.releaseNotes,
            minimumSystemVersion: json.minimumSystemVersion,
            fileSize: json.fileSize
        )
    }

    /// 解析 GitHub API 响应
    private func parseGitHubAPI(_ data: Data) throws -> UpdateInfo {
        let json = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)

        // 提取对应架构的下载 URL
        #if arch(arm64)
        let downloadUrl = json.assets.first { $0.name.contains("arm64") }?.browser_download_url
        #else
        let downloadUrl = json.assets.first { $0.name.contains("x86_64") }?.browser_download_url
        #endif

        return UpdateInfo(
            version: json.tag_name,
            buildNumber: json.id,
            releaseDate: json.published_at,
            downloadUrls: [downloadUrl ?? ""],
            releaseNotes: json.body,
            minimumSystemVersion: "14.0"
        )
    }
}