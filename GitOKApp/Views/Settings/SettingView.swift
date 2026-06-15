import Foundation
import GitOKAppCore
import GitOKCoreKit
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

/// 设置视图 - 入口索引视图
struct SettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var app: AppVM
    @EnvironmentObject var pluginProvider: PluginService

    /// 默认显示的 Tab id
    var defaultTabID: String = "userInfo"

    /// 当前选中的 Tab id
    @State private var selectedTabID: String

    init(defaultTabID: String = "userInfo") {
        self.defaultTabID = defaultTabID
        self._selectedTabID = State(initialValue: defaultTabID)
    }

    /// 插件贡献 + 内置插件管理页
    private var settingsPanes: [GitOKSettingsPaneItem] {
        var panes = pluginProvider.settingsPaneItems(context: pluginProvider.makeContext())
        panes.append(
            GitOKSettingsPaneItem(
                id: "plugins",
                title: String(localized: String.LocalizationValue("插件管理")),
                systemImage: "puzzlepiece.extension",
                order: 80,
                view: AnyView(PluginSettingsView())
            )
        )
        return panes.sorted { $0.order < $1.order }
    }

    /// 应用信息
    private var appInfo: AppInfo {
        AppInfo()
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                sidebarHeader

                Divider()

                List(settingsPanes, id: \.id, selection: $selectedTabID) { pane in
                    NavigationLink(value: pane.id) {
                        Label(pane.title, systemImage: pane.systemImage)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 200)
        } detail: {
            if let pane = settingsPanes.first(where: { $0.id == selectedTabID }) {
                pane.view
                    .environmentObject(data)
            } else if let first = settingsPanes.first {
                first.view
                    .environmentObject(data)
            } else {
                PluginSettingsView()
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            applySelectedTab(app.defaultSettingTab ?? defaultTabID)
        }
        .onChange(of: app.defaultSettingTab) { _, tab in
            applySelectedTab(tab ?? defaultTabID)
        }
        .onDisappear {
            app.defaultSettingTab = nil
        }
    }

    // MARK: - View Components

    private func applySelectedTab(_ tabID: String) {
        if settingsPanes.contains(where: { $0.id == tabID }) {
            selectedTabID = tabID
        } else if let first = settingsPanes.first {
            selectedTabID = first.id
        }
    }

    /// 侧边栏头部 - 应用信息
    private var sidebarHeader: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer().frame(height: 20)

            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .gitOKUIClipRounded(14)
                    .shadow(radius: 3)
            }

            Text(appInfo.name)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .center, spacing: 2) {
                Text(String.localizedStringWithFormat(NSLocalizedString("v%@", comment: ""), appInfo.version))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(String.localizedStringWithFormat(NSLocalizedString("Build %@", comment: ""), appInfo.build))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Setting") {
    SettingView()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
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
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
