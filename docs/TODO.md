# TODO

## P0：自写应用更新机制（UpdatePlugin）

### 背景

当前 GitOK 使用 Sparkle 框架进行应用更新，存在以下问题：
1. **Feed URL 单一**：Sparkle 的 appcast feed URL 指向 GitHub raw 文件，某些国家无法访问 GitHub
2. **下载 URL 也指向 GitHub**：双重访问障碍，导致无法检查更新和下载更新
3. **缺乏 fallback 机制**：Sparkle 不支持多 feed URL fallback，失败时无法自动切换到备用源
4. **用户体验不佳**：无法自定义更新 UI、进度显示、下载策略等

### 目标

实现完全自写的应用更新机制，具备以下特性：
1. ✅ **多 URL fallback**：优先官网 API/R2，失败后自动切换到 GitHub
2. ✅ **智能下载策略**：基于地理位置、成功率动态调整下载源
3. ✅ **自定义用户体验**：进度显示、下载速度、用户选择更新时机
4. ✅ **监控统计**：下载成功率、地区分布、失败原因分析
5. ✅ **插件化架构**：更新逻辑完全解耦，独立维护，未来可替换

### 技术方案

#### 1. 架构设计

**插件目录结构**：
```
Plugins/UpdatePlugin/
├── Package.swift                 # 插件定义（Swift 6.0, macOS 14+）
├── Sources/
│   ├── UpdatePlugin.swift       # 插件入口（GitOKPlugin 协议实现）
│   ├── Services/
│   │   ├── UpdateChecker.swift      # 版本检查服务（多 URL fallback）
│   │   ├── UpdateDownloader.swift   # 文件下载服务（支持进度）
│   │   ├── UpdateInstaller.swift    # DMG 安装服务
│   │   └── UpdateNotifier.swift     # 更新通知服务
│   │   └── UpdateAnalytics.swift    # 更新统计服务（可选）
│   ├── Views/
│   │   ├── UpdateSettingsView.swift    # 设置面板视图
│   │   ├── UpdateStatusView.swift      # 状态栏指示器
│   │   ├── UpdateNotificationView.swift # 更新通知弹窗
│   │   ├── UpdateProgressView.swift    # 下载进度视图
│   │   ├── UpdateErrorView.swift       # 错误处理视图
│   ├── Models/
│   │   ├── UpdateInfo.swift        # 更新信息模型
│   │   ├── UpdateState.swift       # 更新状态模型
│   │   ├── DownloadProgress.swift  # 下载进度模型
│   │   ├── UpdateError.swift       # 错误定义
│   ├── Utils/
│   │   ├── DMGMounter.swift        # DMG 挂载工具
│   │   ├── SignatureVerifier.swift # 签名验证工具
│   │   ├── AppRestarter.swift      # 应用重启工具
│   │   ├── URLFallbackStrategy.swift # URL fallback 策略
│   └── Localizable.xcstrings      # 本地化文件（en/zh-cn）
└── Tests/
    ├── UpdateCheckerTests.swift
    ├── UpdateDownloaderTests.swift
    ├── UpdateInstallerTests.swift
    └── UpdatePluginTests.swift
```

**插件入口设计**：
```swift
// UpdatePlugin.swift
public enum UpdatePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "UpdatePlugin",
        displayName: "应用更新",
        description: "检查和安装应用更新",
        iconName: "arrow.triangle.2.circlepath",
        order: 10,
        policy: .alwaysOn,  // 强制启用（核心功能）
        tableName: "Localizable"
    )

    // 设置面板：更新选项
    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "update",
                title: "更新",
                systemImage: "arrow.triangle.2.circlepath",
                order: 10,
                view: AnyView(UpdateSettingsView())
            )
        ]
    }

    // 状态栏：更新状态指示器（显示"有新版本"或下载进度）
    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        [
            GitOKStatusBarItem(
                id: "updateStatus",
                order: 5,
                view: AnyView(UpdateStatusView())
            )
        ]
    }

    // 根视图覆盖：更新通知弹窗
    @MainActor
    public static func rootOverlay(context: GitOKPluginContext, content: AnyView) -> AnyView? {
        AnyView(
            content
                .sheet(isPresented: UpdateNotifier.shared.showUpdateNotification) {
                    UpdateNotificationView()
                }
        )
    }
}
```

#### 2. 核心服务实现

**版本检查服务（多 URL fallback）**：
```swift
// UpdateChecker.swift
@MainActor
public class UpdateChecker: ObservableObject {
    @Published public var isChecking = false
    @Published public var latestVersion: UpdateInfo?
    @Published public var hasError = false
    @Published public var errorMessage: String?

    // URL fallback 策略
    private let urlStrategy = URLFallbackStrategy()

    public func checkForUpdates() async {
        isChecking = true
        hasError = false

        // 优先级：官网 API → GitHub API
        let urls = [
            "https://api.kuaiyizhi.cn/gitok/version",  // 优先
            "https://api.github.com/repos/CofficLab/GitOK/releases/latest"  // Fallback
        ]

        for url in urls {
            do {
                let updateInfo = try await fetchUpdateInfo(url)
                latestVersion = updateInfo
                os_log(.info, "[UpdateChecker] ✓ Successfully fetched from: \(url)")
                isChecking = false
                return
            } catch {
                os_log(.warning, "[UpdateChecker] ✗ Failed from \(url): \(error)")
                continue
            }
        }

        // 所有 URL 都失败
        hasError = true
        errorMessage = "无法检查更新，请检查网络连接"
        isChecking = false
    }

    private func fetchUpdateInfo(from urlString: String) async throws -> UpdateInfo {
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10  // 10秒超时

        let (data, response) = try await URLSession.shared.data(for: request)

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

    private func parseOfficialAPI(_ data: Data) throws -> UpdateInfo {
        let json = try JSONDecoder().decode(OfficialAPIResponse.self, from: data)
        return UpdateInfo(
            version: json.version,
            buildNumber: json.buildNumber,
            downloadUrls: json.downloadUrls,  // [R2 URL, GitHub URL]
            releaseNotes: json.releaseNotes,
            releaseDate: json.releaseDate
        )
    }

    private func parseGitHubAPI(_ data: Data) throws -> UpdateInfo {
        let json = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)
        let arm64Url = json.assets.first { $0.name.contains("arm64") }?.browser_download_url
        let x86Url = json.assets.first { $0.name.contains("x86_64") }?.browser_download_url

        #if arch(arm64)
        let downloadUrl = arm64Url ?? x86Url
        #else
        let downloadUrl = x86Url ?? arm64Url
        #endif

        return UpdateInfo(
            version: json.tag_name,
            buildNumber: json.id,
            downloadUrls: [downloadUrl],  // GitHub fallback 只有单一 URL
            releaseNotes: json.body,
            releaseDate: json.published_at
        )
    }
}
```

**文件下载服务（支持进度 + 多 URL fallback）**：
```swift
// UpdateDownloader.swift
@MainActor
public class UpdateDownloader: ObservableObject {
    @Published public var downloadProgress: Double = 0
    @Published public var downloadSpeed: String = ""
    @Published public var downloadedBytes: Int64 = 0
    @Published public var totalBytes: Int64 = 0
    @Published public var isDownloading = false
    @Published public var downloadedFileURL: URL?

    private var downloadTask: URLSessionDownloadTask?
    private var startTime: Date?

    public func downloadUpdate(updateInfo: UpdateInfo) async throws {
        isDownloading = true
        downloadProgress = 0
        startTime = Date()

        // 优先级：R2 → GitHub Releases
        let urls = updateInfo.downloadUrls

        for url in urls {
            do {
                let fileURL = try await downloadFromURL(url)
                downloadedFileURL = fileURL
                os_log(.info, "[UpdateDownloader] ✓ Downloaded from: \(url)")
                isDownloading = false
                return
            } catch {
                os_log(.warning, "[UpdateDownloader] ✗ Failed from \(url): \(error)")
                downloadProgress = 0  // 重置进度
                continue
            }
        }

        throw UpdateError.allDownloadURLsFailed
    }

    private func downloadFromURL(_ urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw UpdateError.invalidURL
        }

        // 使用 URLSessionDownloadTask + delegate 支持进度
        let (localURL, response) = try await URLSession.shared.download(from: url, delegate: self)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed
        }

        // 记录下载统计
        try await UpdateAnalytics.shared.recordDownload(
            url: urlString,
            success: true,
            duration: Date().timeIntervalSince(startTime ?? Date())
        )

        return localURL
    }

    public func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0
    }
}

// URLSessionDownloadDelegate
extension UpdateDownloader: URLSessionDownloadDelegate {
    nonisolated public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor in
            self.downloadedBytes = totalBytesWritten
            self.totalBytes = totalBytesExpectedToWrite
            self.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

            // 计算下载速度
            if let startTime = self.startTime {
                let duration = Date().timeIntervalSince(startTime)
                let speed = Double(totalBytesWritten) / duration  // bytes/sec
                self.downloadSpeed = formatSpeed(speed)
            }
        }
    }

    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let mbps = bytesPerSecond / 1024 / 1024
        return String(format: "%.2f MB/s", mbps)
    }
}
```

**DMG 安装服务**：
```swift
// UpdateInstaller.swift
@MainActor
public class UpdateInstaller: ObservableObject {
    @Published public var isInstalling = false
    @Published public var installProgress: String = ""
    @Published public var installError: String?

    public func installUpdate(dmgURL: URL) async throws {
        isInstalling = true
        installError = nil

        do {
            // 1. 验证签名
            installProgress = "验证文件签名..."
            try await SignatureVerifier.verify(dmgURL)

            // 2. 挂载 DMG
            installProgress = "挂载安装包..."
            let mountPath = try await DMGMounter.mount(dmgURL)

            // 3. 替换应用（需要管理员权限）
            installProgress = "安装新版本..."
            try await replaceAppBundle(mountPath)

            // 4. 清理
            installProgress = "清理临时文件..."
            try await DMGMounter.unmount(mountPath)
            try FileManager.default.removeItem(at: dmgURL)

            // 5. 重启应用
            installProgress = "重启应用..."
            await AppRestarter.restart()

            isInstalling = false
        } catch {
            installError = error.localizedDescription
            isInstalling = false
            throw error
        }
    }

    private func replaceAppBundle(_ mountPath: URL) async throws {
        let currentAppPath = Bundle.main.bundleURL
        let newAppPath = mountPath.appendingPathComponent("GitOK.app")

        // 使用 AppleScript 请求管理员权限
        let script = """
        do shell script "rm -rf '\(currentAppPath.path)' && cp -R '\(newAppPath.path)' '\(currentAppPath.path)'" with administrator privileges
        """

        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?

        guard let result = appleScript?.executeAndReturnError(&errorInfo) else {
            if let error = errorInfo {
                throw UpdateError.installationFailed(error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error")
            }
            throw UpdateError.installationFailed("AppleScript execution failed")
        }
    }
}
```

**签名验证工具**：
```swift
// SignatureVerifier.swift
public class SignatureVerifier {
    public static func verify(_ fileURL: URL) async throws {
        // 使用 codesign 命令验证签名
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = [
            "--verify",
            "--deep",
            "--strict",
            "--verbose",
            fileURL.path
        ]

        let pipe = Pipe()
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw UpdateError.signatureVerificationFailed(errorMessage)
        }

        // 验证开发者证书（可选）
        // 确保应用来自可信开发者
        try await verifyDeveloperCertificate(fileURL)
    }

    private static func verifyDeveloperCertificate(_ fileURL: URL) async throws {
        // 获取签名证书信息
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        task.arguments = ["-dvv", fileURL.path]

        let pipe = Pipe()
        task.standardOutput = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // 验证证书是否匹配预期开发者
        // 例如：检查 "Authority=CofficLab" 或特定 Team ID
        guard output.contains("Authority=") else {
            throw UpdateError.invalidDeveloperCertificate
        }
    }
}
```

**应用重启工具**：
```swift
// AppRestarter.swift
public class AppRestarter {
    @MainActor
    public static func restart() async {
        let appURL = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = true

        // 启动新实例
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            if let error = error {
                os_log(.error, "[AppRestarter] Failed to restart: \(error)")
            } else {
                os_log(.info, "[AppRestarter] ✓ Successfully restarted")
            }
        }

        // 等待短暂延迟后退出当前实例
        try? await Task.sleep(for: .seconds(1))
        NSApplication.shared.terminate(nil)
    }
}
```

#### 3. UI 视图设计

**更新通知弹窗**：
```swift
// UpdateNotificationView.swift
struct UpdateNotificationView: View {
    @ObservedObject var notifier = UpdateNotifier.shared
    @ObservedObject var downloader = UpdateDownloader.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("发现新版本")
                .font(.title2)
                .fontWeight(.bold)

            Text("GitOK \(notifier.updateInfo?.version ?? "")")
                .font(.caption)
                .foregroundColor(.secondary)

            // 发布说明
            ScrollView {
                Text(notifier.updateInfo?.releaseNotes ?? "")
                    .font(.body)
                    .padding()
            }
            .frame(maxHeight: 200)

            // 操作按钮
            if downloader.isDownloading {
                UpdateProgressView()
            } else {
                HStack(spacing: 12) {
                    Button("稍后提醒") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("立即更新") {
                        Task {
                            await downloadAndInstall()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 400, height: 500)
        .padding()
    }

    private func downloadAndInstall() async {
        guard let updateInfo = notifier.updateInfo else { return }

        do {
            let dmgFile = try await downloader.downloadUpdate(updateInfo: updateInfo)
            try await installer.installUpdate(dmgURL: dmgFile)
        } catch {
            // 显示错误
            notifier.showError(error)
        }
    }
}
```

**下载进度视图**：
```swift
// UpdateProgressView.swift
struct UpdateProgressView: View {
    @ObservedObject var downloader = UpdateDownloader.shared

    var body: some View {
        VStack(spacing: 16) {
            // 进度条
            ProgressView(value: downloader.downloadProgress) {
                Text("正在下载...")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(Int(downloader.downloadProgress * 100))%")
                    .font(.caption)
            }
            .progressViewStyle(.linear)
            .frame(width: 300)

            // 详细信息
            HStack {
                Text(downloader.downloadSpeed)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(formatBytes(downloader.downloadedBytes)) / \(formatBytes(downloader.totalBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 取消按钮
            Button("取消") {
                downloader.cancelDownload()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024 / 1024
        return String(format: "%.1f MB", mb)
    }
}
```

**状态栏指示器**：
```swift
// UpdateStatusView.swift
struct UpdateStatusView: View {
    @ObservedObject var notifier = UpdateNotifier.shared
    @ObservedObject var downloader = UpdateDownloader.shared

    var body: some View {
        Group {
            if downloader.isDownloading {
                // 下载中：显示进度图标
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("\(Int(downloader.downloadProgress * 100))%")
                        .font(.caption2)
                }
            } else if notifier.hasUpdate {
                // 有新版本：显示提示图标
                Button(action: { notifier.showUpdateNotification = true }) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .help("有新版本可用")
            } else {
                // 无更新：隐藏
                EmptyView()
            }
        }
    }
}
```

#### 4. 服务端 API 设计

**官网 API 端点**（coffic-server）：
```typescript
// apps/cf/src/routes/gitok.ts
gitok.get("/version", handleGitOKVersion);

// apps/cf/src/handlers/data-center/gitok-version.ts
export async function handleGitOKVersion(c: Context<{ Bindings: Env }>): Promise<Response> {
  const bucket = c.env.BUCKET;

  try {
    // 1. 尝试从 R2 查询最新版本
    const listed = await bucket.list({ prefix: "gitok/" });
    const dmgFiles = listed.objects.filter(obj => obj.key.endsWith(".dmg"));

    if (dmgFiles.length === 0) {
      // R2 无文件，fallback 到 GitHub API
      return await fetchGitHubVersionFallback(c);
    }

    // 2. 按上传时间排序，取最新版本
    dmgFiles.sort((a, b) => b.uploaded.getTime() - a.uploaded.getTime());
    const latestDmg = dmgFiles[0];

    // 3. 解析版本信息
    const version = parseVersion(latestDmg.key);
    const arch = parseArch(latestDmg.key);

    // 4. 生成下载 URL（优先 R2，备用 GitHub）
    const downloadUrls = [
      `https://s.kuaiyizhi.cn/${latestDmg.key}`,  // 优先 R2 CDN
      `https://github.com/CofficLab/GitOK/releases/latest/download/${parseFilename(latestDmg.key)}`  // Fallback GitHub
    ];

    // 5. 获取 Release Notes（从 GitHub releases）
    const releaseNotes = await fetchReleaseNotes(c.env);

    // 6. 返回 JSON
    return c.json({
      version: version,
      buildNumber: latestDmg.uploaded.getTime(),
      releaseDate: latestDmg.uploaded.toISOString(),
      downloadUrls: downloadUrls,
      releaseNotes: releaseNotes,
      minimumSystemVersion: "14.0",
      architecture: arch,
      fileSize: latestDmg.size
    }, 200, {
      'Cache-Control': 'public, max-age=300',  // 缓存 5 分钟
      'CDN-Cache-Control': 'public, max-age=60'  // CDN 缓存 1 分钟
    });
  } catch (error) {
    console.error('[GitOK Version] R2 query failed:', error);
    // 服务端 fallback 到 GitHub API
    return await fetchGitHubVersionFallback(c);
  }
}

// Fallback：从 GitHub API 获取版本信息
async function fetchGitHubVersionFallback(c: Context): Promise<Response> {
  try {
    const response = await fetch('https://api.github.com/repos/CofficLab/GitOK/releases/latest', {
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'GitOK-Updater'
      }
    });

    if (!response.ok) {
      return c.json({ error: 'Failed to fetch from GitHub' }, 500);
    }

    const release = await response.json();

    // 提取下载 URL
    const arm64Asset = release.assets.find(a => a.name.includes('arm64'));
    const x86Asset = release.assets.find(a => a.name.includes('x86_64'));

    return c.json({
      version: release.tag_name,
      buildNumber: release.id,
      releaseDate: release.published_at,
      downloadUrls: [
        arm64Asset?.browser_download_url,
        x86Asset?.browser_download_url
      ].filter(Boolean),
      releaseNotes: release.body,
      minimumSystemVersion: "14.0"
    });
  } catch (error) {
    return c.json({ error: 'All sources failed' }, 500);
  }
}

// 辅助函数
function parseVersion(key: string): string {
  const match = key.match(/(\d+\.\d+\.\d+)/);
  return match ? match[1] : '0.0.0';
}

function parseArch(key: string): string {
  if (key.includes('-arm64') || key.includes('_arm64')) return 'arm64';
  if (key.includes('-x86_64') || key.includes('_x86_64')) return 'x86_64';
  return 'universal';
}

function parseFilename(key: string): string {
  return key.replace('gitok/', '');
}

async function fetchReleaseNotes(env: Env): Promise<string> {
  try {
    const response = await fetch('https://api.github.com/repos/CofficLab/GitOK/releases/latest', {
      headers: { 'Accept': 'application/vnd.github+json' }
    });
    const release = await response.json();
    return release.body || '';
  } catch {
    return '';
  }
}
```

#### 5. 数据模型设计

**UpdateInfo 模型**：
```swift
// UpdateInfo.swift
public struct UpdateInfo: Codable, Equatable {
    public let version: String
    public let buildNumber: Int
    public let releaseDate: String
    public let downloadUrls: [String]  // 优先级：[R2, GitHub]
    public let releaseNotes: String
    public let minimumSystemVersion: String
    public let fileSize: Int64?

    public var isNewerThanCurrent: Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return version.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    public var preferredDownloadURL: String? {
        downloadUrls.first
    }

    public var fallbackDownloadURL: String? {
        downloadUrls.count > 1 ? downloadUrls[1] : nil
    }
}

// 服务端响应模型（官网 API）
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

// GitHub API 响应模型
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
```

**UpdateState 模型**：
```swift
// UpdateState.swift
public enum UpdateState: Equatable {
    case idle
    case checking
    case available(updateInfo: UpdateInfo)
    case downloading(progress: Double, speed: String)
    case installing(progress: String)
    case completed
    case error(message: String)
}

public enum UpdateError: Error, LocalizedError {
    case invalidURL
    case networkError
    case downloadFailed
    case allDownloadURLsFailed
    case signatureVerificationFailed(String)
    case invalidDeveloperCertificate
    case installationFailed(String)
    case dmgMountFailed
    case appReplacementFailed

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的下载链接"
        case .networkError: return "网络连接失败"
        case .downloadFailed: return "下载失败"
        case .allDownloadURLsFailed: return "所有下载源均失败"
        case .signatureVerificationFailed(let msg): return "签名验证失败: \(msg)"
        case .invalidDeveloperCertificate: return "开发者证书无效"
        case .installationFailed(let msg): return "安装失败: \(msg)"
        case .dmgMountFailed: return "DMG 挂载失败"
        case .appReplacementFailed: return "应用替换失败"
        }
    }
}
```

#### 6. 实现步骤

**Phase 1：基础框架（第 1 周）**
- [x] 创建 UpdatePlugin 插件目录结构
- [x] 实现 Package.swift 和插件入口
- [x] 实现基础数据模型（UpdateInfo、UpdateState、UpdateError）
- [x] 实现 UpdateChecker 版本检查服务（支持多 URL fallback）
- [x] 实现基础 UI（UpdateSettingsView、UpdateNotificationView）
- [x] 服务端新增 `/gitok/version` API 端点
- [ ] 单元测试：UpdateChecker、数据模型解析

**Phase 2：下载和安装（第 2 周）**
- [x] 实现 UpdateDownloader 下载服务（支持进度、多 URL fallback）
- [x] 实现 URLSessionDownloadDelegate 监听下载进度
- [x] 实现 SignatureVerifier 签名验证工具
- [x] 实现 DMGMounter DMG 挂载/卸载工具
- [x] 实现 UpdateInstaller 安装服务（包括权限请求）
- [x] 实现 AppRestarter 应用重启工具
- [x] 实现 UpdateProgressView 下载进度视图
- [ ] 测试完整安装流程（从下载到重启）

**Phase 3：优化和监控（第 3 周）**
- [x] 实现 UpdateNotifier 服务（自动检查、通知弹窗）
- [ ] 实现 UpdateAnalytics 统计服务（下载成功率、地区分布）
- [ ] 实现智能路由策略（基于地理位置、成功率）
- [x] 实现自动检查策略（启动时检查、定期检查）
- [ ] 实现错误处理和用户友好的错误提示
- [ ] 实现取消下载功能
- [ ] 实现延迟更新功能（用户可选择稍后更新）
- [ ] 优化用户体验（进度显示、下载速度显示）
- [ ] 完整单元测试覆盖
- [ ] 集成测试（模拟完整更新流程）

**Phase 4：清理和迁移（第 4 周）**
- [ ] 移除 Sparkle 框架依赖
- [ ] 清理 GitOKAppCore 中的旧更新代码（AppUpdateController、ReleaseNotesVM）
- [ ] 更新 AboutSettingsPlugin，移除 Sparkle 相关设置项
- [ ] 更新项目文档（README、架构文档）
- [ ] 性能测试和优化
- [ ] 发布新版本，测试实际更新流程

#### 7. 关键技术细节

**DMG 挂载实现**：
```swift
// DMGMounter.swift
public class DMGMounter {
    public static func mount(_ dmgURL: URL) async throws -> URL {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        task.arguments = ["attach", dmgURL.path, "-nobrowse", "-readonly", "-mountpoint", "/Volumes/GitOK"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw UpdateError.dmgMountFailed
        }

        return URL(fileURLWithPath: "/Volumes/GitOK")
    }

    public static func unmount(_ mountPath: URL) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        task.arguments = ["detach", mountPath.path, "-force"]

        try task.run()
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            os_log(.warning, "[DMGMounter] Unmount failed, but continuing")
        }
    }
}
```

**智能路由策略**（可选扩展）：
```swift
// URLFallbackStrategy.swift
public class URLFallbackStrategy {
    private var successHistory: [String: URLSuccessRecord] = [:]

    public func getOrderedURLs(baseURLs: [String]) -> [String] {
        // 基于历史成功率排序 URL
        let scoredURLs = baseURLs.map { url -> (String, Double) in
            let record = successHistory[url]
            let score = calculateScore(record)
            return (url, score)
        }

        return scoredURLs
            .sorted { $0.1 > $1.1 }  // 按分数降序
            .map { $0.0 }
    }

    private func calculateScore(_ record: URLSuccessRecord?) -> Double {
        guard let record = record else {
            return 0.5  // 新 URL 默认中等优先级
        }

        // 综合评分：成功率 + 最近成功时间 + 平均下载速度
        let successRate = Double(record.successCount) / Double(record.totalAttempts)
        let recentSuccessBonus = record.lastSuccessTime.timeIntervalSinceNow < 3600 ? 0.2 : 0
        let speedBonus = min(record.averageSpeed / 10.0, 0.3)  // 速度加分（上限 0.3）

        return successRate + recentSuccessBonus + speedBonus
    }

    public func recordSuccess(url: String, speed: Double) {
        let record = successHistory[url] ?? URLSuccessRecord(url: url)
        record.recordSuccess(speed: speed)
        successHistory[url] = record
    }

    public func recordFailure(url: String) {
        let record = successHistory[url] ?? URLSuccessRecord(url: url)
        record.recordFailure()
        successHistory[url] = record
    }
}

struct URLSuccessRecord {
    let url: String
    var successCount: Int = 0
    var failureCount: Int = 0
    var totalAttempts: Int = 0
    var lastSuccessTime: Date = Date.distantPast
    var averageSpeed: Double = 0

    func recordSuccess(speed: Double) {
        successCount += 1
        totalAttempts += 1
        lastSuccessTime = Date()
        averageSpeed = (averageSpeed * Double(successCount - 1) + speed) / Double(successCount)
    }

    func recordFailure() {
        failureCount += 1
        totalAttempts += 1
    }
}
```

**自动检查策略**：
```swift
// UpdateNotifier.swift
@MainActor
public class UpdateNotifier: ObservableObject {
    public static let shared = UpdateNotifier()

    @Published public var showUpdateNotification = false
    @Published public var updateInfo: UpdateInfo?
    @Published public var hasUpdate = false

    private let checker = UpdateChecker()
    private var autoCheckTimer: Timer?

    private init() {
        // 启动时检查（延迟 3 秒）
        Task {
            try? await Task.sleep(for: .seconds(3))
            await checkForUpdatesInBackground()
        }

        // 定期检查（每 24 小时）
        startAutoCheckTimer()
    }

    private func startAutoCheckTimer() {
        autoCheckTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            Task { @MainActor in
                await self.checkForUpdatesInBackground()
            }
        }
    }

    public func checkForUpdatesInBackground() async {
        await checker.checkForUpdates()

        if let updateInfo = checker.latestVersion, updateInfo.isNewerThanCurrent {
            self.updateInfo = updateInfo
            self.hasUpdate = true
            self.showUpdateNotification = true  // 显示通知弹窗
        }
    }

    public func checkForUpdatesManually() async {
        await checker.checkForUpdates()

        if let updateInfo = checker.latestVersion {
            if updateInfo.isNewerThanCurrent {
                self.updateInfo = updateInfo
                self.hasUpdate = true
                self.showUpdateNotification = true
            } else {
                // 显示"已是最新版本"提示
                showNoUpdateAvailable()
            }
        }
    }
}
```

#### 8. 测试计划

**单元测试**：
- [ ] UpdateChecker：版本解析、多 URL fallback、错误处理
- [ ] UpdateDownloader：进度计算、速度计算、取消下载
- [ ] UpdateInstaller：签名验证、DMG 挂载、应用替换
- [ ] 数据模型：JSON 解析、版本比较、URL 选择策略
- [ ] URLFallbackStrategy：评分算法、历史记录管理

**集成测试**：
- [ ] 完整更新流程：检查 → 下载 → 安装 → 重启
- [ ] 多 URL fallback：模拟第一个 URL 失败，自动切换到第二个
- [ ] 错误恢复：模拟网络错误、签名错误、安装错误
- [ ] 用户交互：取消下载、稍后更新、立即更新

**性能测试**：
- [ ] 下载速度：测量不同 URL 的下载速度
- [ ] 内存占用：监控下载过程中的内存使用
- [ ] 启动检查延迟：确保不影响应用启动速度

**真实环境测试**：
- [ ] 不同网络环境：国内网络、国外网络、无网络
- [ ] 不同 macOS 版本：macOS 14、macOS 15
- [ ] 不同架构：arm64、x86_64
- [ ] 实际更新流程：从旧版本更新到新版本

#### 9. 监控和统计

**UpdateAnalytics 服务**（可选）：
```swift
// UpdateAnalytics.swift
public class UpdateAnalytics {
    public static let shared = UpdateAnalytics()

    public func recordDownload(url: String, success: Bool, duration: TimeInterval, speed: Double? = nil) async throws {
        // 发送到服务端统计 API
        let payload = DownloadAnalyticsPayload(
            eventType: "gitok_update_download",
            url: url,
            success: success,
            duration: duration,
            speed: speed,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            architecture: getCurrentArchitecture()
        )

        // 发送到官网统计 API
        guard let apiUrl = URL(string: "https://api.kuaiyizhi.cn/gitok/analytics") else { return }

        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        try await URLSession.shared.upload(for: request, from: request.httpBody!)
    }

    private func getCurrentArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #else
        return "x86_64"
        #endif
    }
}

struct DownloadAnalyticsPayload: Codable {
    let eventType: String
    let url: String
    let success: Bool
    let duration: TimeInterval
    let speed: Double?
    let timestamp: Date
    let appVersion: String?
    let architecture: String
}
```

**服务端统计 API**（可选）：
```typescript
// apps/cf/src/handlers/data-center/gitok-analytics.ts
export async function handleGitOKAnalytics(c: Context): Promise<Response> {
  const payload = await c.req.json();

  // 存储到数据库或 KV
  await c.env.KV.put(
    `analytics:${payload.timestamp}`,
    JSON.stringify(payload),
    { expirationTtl: 2592000 }  // 保留 30 天
  );

  return c.json({ success: true });
}
```

#### 10. 优势总结

**插件化的优势**：
- ✅ **完全解耦**：更新逻辑独立于核心代码，易于维护
- ✅ **独立测试**：可以单独测试更新功能，不影响其他模块
- ✅ **灵活替换**：未来可以替换为其他更新方案（如重回 Sparkle）
- ✅ **插件复用**：其他 macOS 项目可以使用这个插件

**自写更新机制的优势**：
- ✅ **完全控制**：多 URL fallback、自定义 UI、进度显示、错误处理
- ✅ **智能路由**：基于地理位置、成功率动态调整下载源
- ✅ **监控统计**：下载成功率、地区分布、失败原因分析
- ✅ **用户体验**：更好的进度显示、下载速度显示、用户选择更新时机
- ✅ **国际化友好**：官网优先，解决 GitHub 访问问题

**与 Sparkle 对比**：
| 特性 | Sparkle | UpdatePlugin |
|------|---------|--------------|
| Feed URL fallback | ❌ 不支持 | ✅ 支持（官网 → GitHub） |
| 下载 URL fallback | ❌ 单一 URL | ✅ 多 URL fallback |
| 自定义 UI | ⚠️ 有限支持 | ✅ 完全自定义 |
| 进度显示 | ⚠️ 基础进度 | ✅ 详细进度 + 速度 |
| 智能路由 | ❌ 不支持 | ✅ 基于成功率/地理位置 |
| 监控统计 | ❌ 不支持 | ✅ 完整统计 |
| 国际化 | ⚠️ GitHub 依赖 | ✅ 官网优先 |

---

## P0：插件系统 Context 重构

### 已完成

- [x] Phase 1：BranchPlugin、CleanStatus 从 SwiftUI Environment 迁移到 PluginContext
- [x] Phase 2：toolbar 视图方法（`addToolBarLeadingView`、`addToolBarTrailingView`）注入 `GitOKPluginContext` 参数
- [x] Phase 2：statusBar 视图方法（`addStatusBarLeadingView`、`addStatusBarCenterView`、`addStatusBarTrailingView`）注入 `GitOKPluginContext` 参数
- [x] 扩充 `GitOKPluginContext`：添加 `remoteTrackingStatus`、`projects`、`selectedProjectURL`、`isSidebarVisible`、操作回调等属性
- [x] 更新 `SuperPlugin` 协议、`GitOKPlugin` 协议、`PluginAdapter` 和 13 个插件的 toolbar 方法签名
- [x] 更新架构文档（`architecture.md`、`quickstart.md`、`system.md`）
- [x] `addListView` / `addDetailView` 注入 `GitOKPluginContext`（协议、适配器、PluginVM）
- [x] 清理 PluginVM 中所有视图方法的冗余 `.environment()` 注入
- [x] 标记 17 个 EnvironmentKey 及 EnvironmentValues 扩展为 `@available(*, deprecated)`
- [x] 消除全部 13 处 `@Environment(\.gitOKProjectURL)`（StashPlugin 2 + BannerPlugin 3 + IconPlugin 4 + 其他 4）→ 全插件包归零 ✅

## P0：核心 Git 工作流

- [ ] OAuth/device-flow 登录、账号多配置、组织分页和头像/权限缓存
- [ ] 一键创建远程仓库、公开/私有选择、平台认证与远端仓库创建
- [ ] 过滤后提交前的最终确认摘要

## P1：高级 Git 操作

- [ ] 交互式 rebase 列表
- [ ] squash 前提交消息编辑预览
- [ ] reset 前自动 stash/备份提示

## P1：远程平台接入

- [ ] 应用内 PR 列表、当前分支关联 PR 状态、review/check 摘要和草稿 PR 创建
- [ ] 应用内未读计数、review/comment 通知流、标记已读和原生评论编辑
- [ ] 平台 issue 搜索、PR 文本编辑器内 autocomplete、用户头像/真实 handle、emoji 全量索引和离线缓存
- [ ] 应用内 check 状态、失败日志摘要、PR check 汇总、rerun 权限判断和原生 rerun 操作
- [ ] 各平台的 OAuth/token 配置界面

## P1：Diff 与设置

- [ ] 默认 diff mode、长行策略和折叠阈值提升为用户设置
- [ ] 语法高亮策略提升为用户设置
- [ ] 图片 diff 补尺寸、文件大小和缩放比例等元信息
- [ ] 超大 diff 阈值做成设置项

## P1：认证与网络

- [ ] 菜单触发的 fetch/pull/push 失败也接入认证弹窗，并补 OAuth/SSO 平台登录
- [ ] 接入原生 askpass/Keychain passphrase 写入，减少用户跳转终端的步骤
- [ ] PAC 自动发现、按仓库覆盖网络配置，以及更细的代理认证凭据保存

## P2：桌面体验

- [ ] Command Palette（可选）
- [ ] 真正的 crash reporter、持久化跨会话错误队列，以及错误弹窗中的"一键附加诊断信息"
- [ ] 更多插件自定义控件的细粒度 VoiceOver 文案

## 已有功能打磨

- [ ] Git-Clone 扩展 SSH passphrase、企业 SSO/OAuth 和平台仓库列表选择
