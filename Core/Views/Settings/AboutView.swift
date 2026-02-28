import Foundation
import MagicKit
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
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }

                    // App 名称
                    Text(appInfo.name)
                        .font(.title)
                        .fontWeight(.bold)

                    // App 版本
                    VStack(spacing: 4) {
                        Text(String.localizedStringWithFormat(String(localized: "版本 %@", table: "Core"), appInfo.version))
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text(String.localizedStringWithFormat(NSLocalizedString("Build %@", tableName: "Core", comment: ""), appInfo.build))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 信息区域
                VStack(spacing: 24) {
                    // 描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("关于", tableName: "Core")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(localized: .init(appInfo.description), table: "Core"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()

                    // 基本信息
                    MagicSettingSection(title: String(localized: "应用信息", table: "Core"), titleAlignment: .leading) {
                        VStack(spacing: 0) {
                            infoRow(
                                title: String(localized: "应用名称", table: "Core"),
                                value: appInfo.name,
                                icon: .iconGear
                            )

                            Divider()

                            infoRow(
                                title: String(localized: "版本", table: "Core"),
                                value: appInfo.version,
                                icon: .iconVolume
                            )

                            Divider()

                            infoRow(
                                title: String(localized: "Build", table: "Core"),
                                value: appInfo.build,
                                icon: .iconBulletList
                            )

                            Divider()

                            infoRow(
                                title: String(localized: "Bundle ID", table: "Core"),
                                value: appInfo.bundleIdentifier,
                                icon: .iconInfo
                            )
                        }
                    }

                    // 链接
                    MagicSettingSection(title: String(localized: "链接", table: "Core"), titleAlignment: .leading) {
                        VStack(spacing: 0) {
                            linkRow(
                                title: String(localized: "官方网站", table: "Core"),
                                url: appInfo.website,
                                icon: .iconSafari
                            )

                            if !appInfo.repository.isEmpty {
                                Divider()

                                linkRow(
                                    title: String(localized: "源代码", table: "Core"),
                                    url: appInfo.repository,
                                    icon: .iconCalendar
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationTitle(Text("关于", tableName: "Core"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "完成", table: "Core")) {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
    }

    // MARK: - View Components

    private func infoRow(title: String, value: String, icon: String) -> some View {
        MagicSettingRow(
            title: title,
            description: value,
            icon: icon
        ) {
            EmptyView()
        }
    }

    private func linkRow(title: String, url: String, icon: String) -> some View {
        MagicSettingRow(
            title: title,
            description: url,
            icon: icon
        ) {
            Image.safari.inButtonWithAction {
                if let url = URL(string: url) {
                    NSWorkspace.shared.open(url)
                }
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
