import SwiftUI

/// 更新通知弹窗
public struct UpdateNotificationView: View {
    @ObservedObject var notifier = UpdateNotifier.shared
    @ObservedObject var downloader = UpdateDownloader()
    @ObservedObject var installer = UpdateInstaller()
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            // 标题
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("发现新版本")
                .font(.title2)
                .fontWeight(.bold)

            if let updateInfo = notifier.updateInfo {
                Text("GitOK \(updateInfo.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 发布说明
                ScrollView {
                    Text(updateInfo.releaseNotes)
                        .font(.body)
                        .padding()
                }
                .frame(maxHeight: 200)

                // 操作按钮
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
                    HStack(spacing: 12) {
                        Button("稍后提醒") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)

                        Button("立即更新") {
                            Task {
                                await downloadAndInstall(updateInfo: updateInfo)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .padding()
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
            notifier.errorMessage = error.localizedDescription
        }
    }
}