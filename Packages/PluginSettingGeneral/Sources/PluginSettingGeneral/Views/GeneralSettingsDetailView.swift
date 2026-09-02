import AppKit
import LumiUI
import ProviderDocsView
import SwiftUI

/// 通用设置详情视图 —— 设置窗口「通用」标签页。
///
/// 从 Lumi 复刻并删减：移除新手引导 / 网站 / 更新三个分组
/// （GitOK 无 onboarding、独立官网与 Sparkle 更新链路），
/// 保留说明书（依赖 `DocsViewProviding`，无手册时自动隐藏）与应用信息。
struct GeneralSettingsDetailView: View {
    let docsProvider: (any DocsViewProviding)?

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

    // MARK: - Debug Header

    #if DEBUG
    private var debugHeader: some View {
        HStack(spacing: 10) {
            Spacer()
            AppButton(LumiPluginLocalization.string("Open Data Directory", bundle: .module), systemImage: "folder", style: .warning, size: .small) {
                openDataDirectory()
            }
        }
        .font(.appCaption)
    }
    #endif

    // MARK: - 说明书

    private var manualsSection: some View {
        AppSettingSection(
            title: "说明书",
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: "说明书",
                description: "各功能的使用指南。",
                icon: "book"
            ) {
                AppButton(
                    "打开",
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
            title: "GitOK",
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: "Name",
                    description: bundleInfo.name,
                    icon: "app"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: "Bundle ID",
                    description: bundleInfo.bundleIdentifier,
                    icon: "number"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: "Version",
                    description: bundleInfo.version ?? "Not Set",
                    icon: "info.circle"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: "Build",
                    description: bundleInfo.build ?? "Not Set",
                    icon: "hammer"
                ) {
                    EmptyView()
                }
            }
        }
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
