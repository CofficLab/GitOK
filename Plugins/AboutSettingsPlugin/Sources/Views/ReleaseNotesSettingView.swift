import GitOKAppCore
import GitOKUI
import GitOKSupportKit
import Sparkle
import SwiftUI

public struct ReleaseNotesSettingView: View {
    private let appInfo = AppInfo()
    private let updater = AppUpdateController.shared.updater

    @ObservedObject private var updateViewModel: CheckForUpdatesViewModel

    init() {
        updateViewModel = CheckForUpdatesViewModel(updater: AppUpdateController.shared.updater)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                currentVersionSection
                updateSection
                releaseNotesSection
            }
            .padding()
        }
        .navigationTitle("更新")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton("完成", style: .secondary, size: .small) {
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
    }

    private var currentVersionSection: some View {
        GitOKUI.AppSettingsSection(title: "当前版本") {
            settingsRow(
                title: "版本",
                description: "\(appInfo.version) (\(appInfo.build))",
                icon: "info.circle"
            ) {
                EmptyView()
            }
            settingsRow(
                title: "更新源",
                description: updateViewModel.feedURL?.absoluteString ?? "未配置",
                icon: "antenna.radiowaves.left.and.right"
            ) {
                EmptyView()
            }
        }
    }

    private var updateSection: some View {
        GitOKUI.AppSettingsSection(title: "更新检查") {
            GitOKUI.AppSettingsRow(verticalPadding: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.secondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("后台自动检查")
                            .font(.system(size: 13, weight: .medium))

                        Text("开启后 Sparkle 会按系统更新周期在后台检查新版本。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { updateViewModel.automaticallyChecksForUpdates },
                        set: { updater.automaticallyChecksForUpdates = $0 }
                    ))
                    .labelsHidden()
                }
            }

            settingsRow(
                title: "手动检查",
                description: "立即检查新版本；失败后可再次点击重试。",
                icon: "arrow.clockwise"
            ) {
                UpdaterView(updater: updater)
            }
        }
    }

    private var releaseNotesSection: some View {
        GitOKUI.AppSettingsSection(title: "版本更新说明") {
            releaseLinkRow(
                title: "最新版本说明",
                description: "打开 GitHub 最新 Release",
                url: "https://github.com/CofficLab/GitOK/releases/latest"
            )
            releaseLinkRow(
                title: "所有版本",
                description: "查看完整 Release 历史",
                url: "https://github.com/CofficLab/GitOK/releases"
            )
        }
    }

    private func releaseLinkRow(title: String, description: String, url: String) -> some View {
        settingsRow(title: title, description: description, icon: "doc.text") {
            AppIconButton(systemImage: "safari", size: .regular) {
                if let url = URL(string: url) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func settingsRow<Accessory: View>(
        title: String,
        description: String,
        icon: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()

                accessory()
            }
        }
    }
}
