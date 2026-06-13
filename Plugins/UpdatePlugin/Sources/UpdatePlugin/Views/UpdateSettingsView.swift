import SwiftUI
import OSLog

/// 更新设置视图
public struct UpdateSettingsView: View {
    @StateObject private var checker = UpdateChecker()

    public init() {}

    public var body: some View {
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
            .disabled(checker.isChecking)

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

                        Button("下载并安装") {
                            // TODO: 实现下载和安装逻辑
                        }
                        .buttonStyle(.borderedProminent)
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

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
    }

    private var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知"
    }
}