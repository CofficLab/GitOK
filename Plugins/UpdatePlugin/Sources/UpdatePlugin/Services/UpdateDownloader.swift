import Foundation
import OSLog

/// 文件下载服务（支持进度 + 多 URL fallback）
@MainActor
public class UpdateDownloader: NSObject, ObservableObject {
    nonisolated public static let emoji = "📥"

    @Published public var downloadProgress: Double = 0
    @Published public var downloadSpeed: String = ""
    @Published public var downloadedBytes: Int64 = 0
    @Published public var totalBytes: Int64 = 0
    @Published public var isDownloading = false
    @Published public var downloadedFileURL: URL?

    private var downloadTask: URLSessionDownloadTask?
    private var startTime: Date?
    
    // URLSession 必须设置 delegate 才能接收进度回调
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        // delegate 必须是 self，delegateQueue 用 nil 让系统管理
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // 用于接收进度回调
    private var continuation: CheckedContinuation<URL, Error>?

    override public init() {
        super.init()
    }
    
    /// 下载更新（优先 R2，失败 fallback GitHub）
    public func downloadUpdate(updateInfo: UpdateInfo) async throws {
        isDownloading = true
        downloadProgress = 0
        downloadedBytes = 0
        totalBytes = 0
        downloadSpeed = ""
        startTime = Date()

        // 优先级：R2 → GitHub Releases
        let urls = updateInfo.downloadUrls

        for url in urls {
            guard !url.isEmpty else { continue }

            do {
                let fileURL = try await downloadFromURL(url, version: updateInfo.version)
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

    /// 从指定 URL 下载文件，并移动到 Downloads 目录
    private func downloadFromURL(_ urlString: String, version: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let task = session.downloadTask(with: url)
            task.taskDescription = version
            self.downloadTask = task
            task.resume()
        }
    }
    
    /// 将 URLSession 临时文件移到 Caches（必须在 delegate 回调返回前同步完成）
    nonisolated private func moveDownloadedFile(from tempURL: URL, version: String) throws -> URL {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let updateDir = cachesDir.appendingPathComponent("com.cofficlab.gitok.updates", isDirectory: true)

        if !FileManager.default.fileExists(atPath: updateDir.path) {
            try FileManager.default.createDirectory(at: updateDir, withIntermediateDirectories: true)
        }

        let finalURL = updateDir.appendingPathComponent("GitOK-\(version).dmg")

        if FileManager.default.fileExists(atPath: finalURL.path) {
            try FileManager.default.removeItem(at: finalURL)
        }

        try FileManager.default.moveItem(at: tempURL, to: finalURL)
        return finalURL
    }

    /// 取消下载
    public func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0
        downloadedBytes = 0
        totalBytes = 0
        downloadSpeed = ""
        continuation?.resume(throwing: UpdateError.downloadFailed)
        continuation = nil
    }

    /// 格式化下载速度
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let mbps = bytesPerSecond / 1024 / 1024
        return String(format: "%.2f MB/s", mbps)
    }
}

// MARK: - URLSessionDownloadDelegate

extension UpdateDownloader: URLSessionDownloadDelegate {
    nonisolated public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 临时文件仅在 delegate 方法执行期间有效，必须同步移动
        let version = downloadTask.taskDescription ?? "latest"
        do {
            let finalURL = try moveDownloadedFile(from: location, version: version)
            Task { @MainActor in
                os_log(.info, "[UpdateDownloader] Moved temp file to %{public}s", finalURL.path)
                self.downloadProgress = 1.0
                self.continuation?.resume(returning: finalURL)
                self.continuation = nil
            }
        } catch {
            Task { @MainActor in
                os_log(.error, "[UpdateDownloader] Failed to move file: %{public}s", error.localizedDescription)
                self.continuation?.resume(throwing: error)
                self.continuation = nil
            }
        }
    }
    
    nonisolated public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            if let error = error {
                os_log(.error, "[UpdateDownloader] Download failed: %{public}s", error.localizedDescription)
                self.continuation?.resume(throwing: error)
                self.continuation = nil
            }
        }
    }
    
    nonisolated public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                                        didWriteData bytesWritten: Int64,
                                        totalBytesWritten: Int64,
                                        totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            self.downloadedBytes = totalBytesWritten
            self.totalBytes = totalBytesExpectedToWrite
            
            if totalBytesExpectedToWrite > 0 {
                self.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            }
            
            // 计算速度
            if let startTime = self.startTime {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > 0 {
                    let speed = Double(totalBytesWritten) / elapsed
                    self.downloadSpeed = self.formatSpeed(speed)
                }
            }
        }
    }
}
