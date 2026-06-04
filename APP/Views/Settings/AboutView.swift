import Foundation
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

/// 关于应用视图
struct AboutView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "ℹ️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 应用信息
    let appInfo = AppInfo()

    var body: some View {
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
                        Text(String.localizedStringWithFormat(String(localized: "Version %@"), appInfo.version))
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text(String.localizedStringWithFormat(NSLocalizedString("Build %@", comment: ""), appInfo.build))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 信息区域
                VStack(spacing: 24) {
                    // 描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("关于")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(localized: .init(appInfo.description)))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()

                    // 基本信息
                    GitOKUI.AppSettingsSection(title: String(localized: "App Info")) {
                        infoRow(
                            title: String(localized: "App Name"),
                            value: appInfo.name,
                            icon: "gearshape"
                        )
                        infoRow(
                            title: String(localized: "Version"),
                            value: appInfo.version,
                            icon: "speaker.wave.2"
                        )
                        infoRow(
                            title: String(localized: "Build"),
                            value: appInfo.build,
                            icon: "list.bullet"
                        )
                        infoRow(
                            title: String(localized: "Bundle ID"),
                            value: appInfo.bundleIdentifier,
                            icon: "info.circle"
                        )
                    }

                    // 链接
                    GitOKUI.AppSettingsSection(title: String(localized: "Links")) {
                        linkRow(
                            title: String(localized: "Website"),
                            url: appInfo.website,
                            icon: "safari"
                        )

                        if !appInfo.repository.isEmpty {
                            linkRow(
                                title: String(localized: "Source Code"),
                                url: appInfo.repository,
                                icon: "calendar"
                            )
                        }

                        linkRow(
                            title: "版本更新说明",
                            url: "https://github.com/CofficLab/GitOK/releases/latest",
                            icon: "doc.text"
                        )
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationTitle(Text("关于"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(String(localized: "Done"), style: .secondary, size: .small) {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
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

// MARK: - AppInfo

/// 应用信息模型
struct AppInfo {
    let name: String
    let version: String
    let build: String
    let bundleIdentifier: String
    let description: String
    let website: String
    let repository: String

    init() {
        // 从 Bundle 中获取信息
        let bundle = Bundle.main

        self.name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "GitOK"
        self.version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        self.build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        self.bundleIdentifier = bundle.bundleIdentifier ?? "com.cofficlab.GitOK"
        self.description = bundle.object(forInfoDictionaryKey: "CFBundleGetInfoString") as? String
            ?? "一个现代化的 Git 客户端，让 Git 操作更加简单高效。"
        self.website = bundle.object(forInfoDictionaryKey: "Website") as? String
            ?? "https://github.com/CofficLab/GitOK"
        self.repository = bundle.object(forInfoDictionaryKey: "Repository") as? String
            ?? "https://github.com/CofficLab/GitOK"
    }
}

// MARK: - Preview

#Preview("About View") {
    AboutView()
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
