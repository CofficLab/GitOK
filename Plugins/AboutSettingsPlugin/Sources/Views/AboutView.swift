import GitOKAppCore
import Foundation
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

/// 关于应用视图
public struct AboutView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "ℹ️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 应用信息
    let appInfo = AppInfo()

    public var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 32) {
                Spacer().frame(height: 40)

                // App 图标和名称
                VStack(spacing: 16) {
                    // App 图标
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .gitOKUIClipRounded(20)
                            .shadow(radius: 5)
                    }

                    // App 名称
                    Text(appInfo.name)
                        .font(.title)
                        .fontWeight(.bold)

                    // App 版本
                    VStack(spacing: 4) {
                        Text(String.localizedStringWithFormat(AboutSettingsPluginLocalization.string("Version %@"), appInfo.version))
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text(String.localizedStringWithFormat(AboutSettingsPluginLocalization.string("Build %@"), appInfo.build))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 信息区域
                VStack(spacing: 24) {
                    // 描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AboutSettingsPluginLocalization.string("About"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(AboutSettingsPluginLocalization.string("App Description"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()

                    // 基本信息
                    GitOKUI.AppSettingsSection(title: AboutSettingsPluginLocalization.string("App Info")) {
                        infoRow(
                            title: AboutSettingsPluginLocalization.string("App Name"),
                            value: appInfo.name,
                            icon: "gearshape"
                        )
                        infoRow(
                            title: AboutSettingsPluginLocalization.string("Version"),
                            value: appInfo.version,
                            icon: "speaker.wave.2"
                        )
                        infoRow(
                            title: AboutSettingsPluginLocalization.string("Build"),
                            value: appInfo.build,
                            icon: "list.bullet"
                        )
                        infoRow(
                            title: AboutSettingsPluginLocalization.string("Bundle ID"),
                            value: appInfo.bundleIdentifier,
                            icon: "info.circle"
                        )
                    }

                    // 链接
                    GitOKUI.AppSettingsSection(title: AboutSettingsPluginLocalization.string("Links")) {
                        linkRow(
                            title: AboutSettingsPluginLocalization.string("Website"),
                            url: appInfo.website,
                            icon: "safari"
                        )

                        if !appInfo.repository.isEmpty {
                            linkRow(
                                title: AboutSettingsPluginLocalization.string("Source Code"),
                                url: appInfo.repository,
                                icon: "calendar"
                            )
                        }

                        linkRow(
                            title: AboutSettingsPluginLocalization.string("Release Notes"),
                            url: "https://github.com/CofficLab/GitOK/releases/latest",
                            icon: "doc.text"
                        )
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationTitle(Text(AboutSettingsPluginLocalization.string("About")))
    }

    // MARK: - View Components

    private func infoRow(title: String, value: String, icon: String) -> some View {
        settingsRow(title: title, description: value, icon: icon) {
            EmptyView()
        }
    }

    private func linkRow(title: String, url: String, icon: String) -> some View {
        settingsRow(title: title, description: url, icon: icon) {
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

// MARK: - Preview

#Preview("About View") {
    AboutView()
}
