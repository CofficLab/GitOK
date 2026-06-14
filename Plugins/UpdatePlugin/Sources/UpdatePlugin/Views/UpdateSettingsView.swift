import GitOKAppCore
import GitOKUI
import OSLog
import Sparkle
import SwiftUI

/// 更新设置视图（基于 Sparkle 2.x）
public struct UpdateSettingsView: View {
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
                    }
                    .padding()
                }

                // 检查更新按钮（由 Sparkle 处理，会自动弹出更新 UI）
                Button(action: {
                    SUUpdater.shared()?.checkForUpdates(nil)
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("检查更新")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                // 自动更新选项
                Toggle("自动检查更新", isOn: Binding(
                    get: { SUUpdater.shared()?.automaticallyChecksForUpdates ?? true },
                    set: { SUUpdater.shared()?.automaticallyChecksForUpdates = $0 }
                ))
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(Text("更新"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(String(localized: "Done"), style: .secondary, size: .small) {
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知"
    }

    private var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知"
    }
}
