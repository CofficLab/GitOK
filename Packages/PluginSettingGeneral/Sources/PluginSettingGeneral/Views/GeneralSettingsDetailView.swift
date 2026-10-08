import AppKit
import LumiUI
import ProviderDocsView
import ProviderGit
import SwiftUI

/// 通用设置详情视图 —— 设置窗口「通用」标签页。
///
/// 从 Lumi 复刻并删减：移除新手引导，保留网站入口、更新入口、
/// 说明书（依赖 `DocsViewProviding`，无手册时自动隐藏）与应用信息。
struct GeneralSettingsDetailView: View {
    /// 官网地址（展示文本与打开目标共用）。
    static let websiteURLString = "coffic.cn/gitok"

    /// 官网可点击链接。
    private static let websiteURL = URL(string: "https://\(websiteURLString)")

    let docsProvider: (any DocsViewProviding)?
    let gitBackends: [GitBackendDescriptor]

    /// 是否展示说明书浏览器。
    @State private var isPresentingManuals = false

    /// App bundle 元数据（名称 / 包名 / 版本 / 构建）。
    private let bundleInfo = AppBundleInfo()

    /// 所有提供了说明书的文档条目（来自 `DocsViewProviding`）。
    private var manuals: [DocsEntry] {
        docsProvider?.manualEntries ?? []
    }

    var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 24) {
#if DEBUG
                debugHeader
#endif
                if !gitBackends.isEmpty {
                    GitBackendSectionView(backends: gitBackends)
                }
                websiteSection
                updatesSection
                if !manuals.isEmpty {
                    manualsSection
                }
                appSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $isPresentingManuals) {
            if !manuals.isEmpty {
                ManualsBrowserView(manuals: manuals)
            }
        }
    }

    // MARK: - 网站

    /// 官网链接；点击「访问」使用系统默认浏览器打开。
    private var websiteSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Website"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string("Official Website"),
                description: Self.websiteURLString,
                icon: "globe"
            ) {
                AppButton(
                    pluginLocalization.string("Visit"),
                    systemImage: "arrow.up.forward.square",
                    style: .secondary,
                    size: .small
                ) {
                    openWebsite()
                }
            }
        }
    }

    // MARK: - 更新

    private var updatesSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Updates"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string("Check for Updates"),
                icon: "arrow.triangle.2.circlepath"
            ) {
                AppButton(
                    pluginLocalization.string("Check"),
                    systemImage: "arrow.clockwise",
                    style: .secondary,
                    size: .small
                ) {
                    NotificationCenter.default.post(
                        name: Notification.Name("checkForUpdates"),
                        object: nil
                    )
                }
            }
        }
    }

    // MARK: - Debug Header

    #if DEBUG
    private var debugHeader: some View {
        HStack(spacing: 10) {
            Spacer()
            AppButton(pluginLocalization.string("Open Data Directory"), systemImage: "folder", style: .warning, size: .small) {
                openDataDirectory()
            }
        }
        .font(.appCaption)
    }
    #endif

    // MARK: - 说明书

    private var manualsSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("User Manual"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string("User Manual"),
                description: pluginLocalization.string("Guides for each feature."),
                icon: "book"
            ) {
                AppButton(
                    pluginLocalization.string("Open"),
                    systemImage: "book.pages",
                    style: .secondary,
                    size: .small
                ) {
                    isPresentingManuals = true
                }
            }
        }
    }

    // MARK: - GitOK（应用信息）

    private var appSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("GitOK"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: pluginLocalization.string("Name"),
                    description: bundleInfo.name,
                    icon: "app"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Bundle ID"),
                    description: bundleInfo.bundleIdentifier,
                    icon: "number"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Version"),
                    description: bundleInfo.version ?? pluginLocalization.string("Not Set"),
                    icon: "info.circle"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Build"),
                    description: bundleInfo.build ?? pluginLocalization.string("Not Set"),
                    icon: "hammer"
                ) {
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Actions

    /// 用系统默认浏览器打开官网。
    private func openWebsite() {
        guard let url = Self.websiteURL else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Debug Helpers

    #if DEBUG
    private func openDataDirectory() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("com.yueyi.GitOK", isDirectory: true)
        guard let url = appSupport else { return }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }
    #endif
}
