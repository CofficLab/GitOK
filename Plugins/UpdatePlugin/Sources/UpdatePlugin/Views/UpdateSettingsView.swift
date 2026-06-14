import SwiftUI
import OSLog
import GitOKAppCore
import GitOKUI

/// 更新设置视图
public struct UpdateSettingsView: View {
    @StateObject private var checker = UpdateChecker.shared
    @StateObject private var downloader = UpdateDownloader()
    @StateObject private var installer = UpdateInstaller()

    @EnvironmentObject var data: DataVM

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 当前版本信息
                GroupBox("当前版本") {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GitOK")
                                .font(.headline)
                            Text("版本: \(currentVersion)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Build: \(currentBuild)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if checker.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .padding()
                }

                // 检查更新按钮
                Button(action: {
                    Task {
                        await checker.checkForUpdates()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(checker.isChecking ? "正在检查..." : "检查更新")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(checker.isChecking || downloader.isDownloading || installer.isInstalling)

                // 更新信息（如果有）
                if let updateInfo = checker.latestVersion, updateInfo.isNewerThanCurrent {
                    GroupBox("发现新版本") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("版本 \(updateInfo.version)")
                                .font(.headline)

                            ScrollView {
                                Text(updateInfo.releaseNotes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxHeight: 150)

                            // 下载进度或安装进度
                            if downloader.isDownloading {
                                UpdateProgressView(downloader: downloader)
                            } else if installer.isInstalling {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(installer.installProgress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else {
                                Button("下载并安装") {
                                    Task {
                                        await downloadAndInstall(updateInfo: updateInfo)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    }
                }

                // 错误信息
                if checker.hasError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(checker.errorMessage ?? "未知错误")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let installError = installer.installError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(installError)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(Text("更新"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(String(localized: "Done"), style: .secondary, size: .small) {
                    // 关闭设置视图（通过通知）
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
    }

    private func downloadAndInstall(updateInfo: UpdateInfo) async {
        do {
            // 下载 DMG
            _ = try await downloader.downloadUpdate(updateInfo: updateInfo)

            // 安装更新
            if let dmgFile = downloader.downloadedFileURL {
                try await installer.installUpdate(dmgURL: dmgFile)
            }
        } catch {
            os_log(.error, "[UpdateSettingsView] Download or install failed: %{public}s", error.localizedDescription)
        }
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
    }

    private var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知"
    }
}