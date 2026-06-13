import Foundation

/// 更新信息模型
public struct UpdateInfo: Codable, Equatable, Sendable {
    public let version: String
    public let buildNumber: Int
    public let releaseDate: String
    public let downloadUrls: [String]  // 优先级：[R2, GitHub]
    public let releaseNotes: String
    public let minimumSystemVersion: String
    public let fileSize: Int64?

    public init(
        version: String,
        buildNumber: Int,
        releaseDate: String,
        downloadUrls: [String],
        releaseNotes: String,
        minimumSystemVersion: String = "14.0",
        fileSize: Int64? = nil
    ) {
        self.version = version
        self.buildNumber = buildNumber
        self.releaseDate = releaseDate
        self.downloadUrls = downloadUrls
        self.releaseNotes = releaseNotes
        self.minimumSystemVersion = minimumSystemVersion
        self.fileSize = fileSize
    }

    /// 是否比当前版本新
    public var isNewerThanCurrent: Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return version.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    /// 优先下载 URL（R2）
    public var preferredDownloadURL: String? {
        downloadUrls.first
    }

    /// 备用下载 URL（GitHub）
    public var fallbackDownloadURL: String? {
        downloadUrls.count > 1 ? downloadUrls[1] : nil
    }
}

/// 服务端响应模型（官网 API）
struct OfficialAPIResponse: Codable {
    let version: String
    let buildNumber: Int
    let releaseDate: String
    let downloadUrls: [String]
    let releaseNotes: String
    let minimumSystemVersion: String
    let architecture: String?
    let fileSize: Int64?
}

/// GitHub API 响应模型
struct GitHubReleaseResponse: Codable {
    let tag_name: String
    let id: Int
    let published_at: String
    let body: String
    let assets: [GitHubAsset]
}

struct GitHubAsset: Codable {
    let name: String
    let browser_download_url: String
    let size: Int64
}