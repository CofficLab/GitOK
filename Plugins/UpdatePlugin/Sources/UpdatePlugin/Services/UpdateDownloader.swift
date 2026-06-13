import Foundation
import OSLog

/// 文件下载服务（支持进度 + 多 URL fallback）
@MainActor
public class UpdateDownloader: ObservableObject {
    nonisolated public static let emoji = "⬇️"

    @Published public var downloadProgress: Double = 0
    @Published public var downloadSpeed: String = ""
    @Published public var downloadedBytes: Int64 = 0
    @Published public var totalBytes: Int64 = 0
    @Published public var isDownloading = false
    @Published public var downloadedFileURL: URL?

    private var downloadTask: Task<Void, Error>?
    private var startTime: Date?
    private let session = URLSession.shared

    public init() {}

    /// 下载更新（优先 R2，失败 fallback GitHub）
    public func downloadUpdate(updateInfo: UpdateInfo) async throws {
        isDownloading = true
        downloadProgress = 0
        downloadedBytes = 0
        totalBytes = 0
        startTime = Date()

        // 优先级：R2 → GitHub Releases
        let urls = updateInfo.downloadUrls

        for url in urls {
            guard !url.isEmpty else { continue }

            do {
                let fileURL = try await downloadFromURL(url)
                downloadedFileURL = fileURL
                os_log(.info, "[UpdateDownloader] ✓ Downloaded from %{public}s", url)
                isDownloading = false
                return
            } catch {
                os_log(.error, "[UpdateDownloader] ✗ Failed from %{public}s: %{public}s", url, error.localizedDescription)
                downloadProgress = 0  // 重置进度
                continue
            }
        }

        isDownloading = false
        throw UpdateError.allDownloadURLsFailed
    }

    /// 从指定 URL 下载文件
    private func downloadFromURL(_ urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        // 使用 URLSession download 方法
        let (localURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed
        }

        return localURL
    }

    /// 取消下载
    public func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0
        downloadedBytes = 0
        totalBytes = 0
        downloadSpeed = ""
    }

    /// 格式化下载速度
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let mbps = bytesPerSecond / 1024 / 1024
        return String(format: "%.2f MB/s", mbps)
    }
}