import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 设置视图 - 入口索引视图
struct SettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider
    @Environment(\.dismiss) private var dismiss

    /// 默认显示的 Tab
    var defaultTab: SettingTab = .userInfo

    /// 当前选中的 Tab
    @State private var selectedTab: SettingTab

    /// 设置 Tab 枚举
    enum SettingTab: String, CaseIterable {
        case userInfo = "用户信息"
        case commitStyle = "Commit 风格"
//        case appearance = "外观"
//        case systemInfo = "系统信息"
        case plugins = "插件管理"
        case about = "关于"

        var icon: String {
            switch self {
            case .userInfo: return "person.circle"
            case .commitStyle: return "text.alignleft"
//            case .appearance: return "paintbrush"
//            case .systemInfo: return "desktopcomputer.trianglebadge.exclamationmark"
            case .plugins: return "puzzlepiece.extension"
            case .about: return "info.circle"
            }
        }
    }

    init(defaultTab: SettingTab = .userInfo) {
        self.defaultTab = defaultTab
        self._selectedTab = State(initialValue: defaultTab)
    }

    /// 应用信息
    private var appInfo: AppInfo {
        AppInfo()
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // 应用信息头部
                sidebarHeader

                Divider()

                // 设置列表
                List(SettingTab.allCases, id: \.self, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 200)
        } detail: {
            // Detail 内容
            switch selectedTab {
            case .userInfo:
                GitUserInfoSettingView()
                    .environmentObject(data)

            case .commitStyle:
                CommitStyleSettingView()
                    .environmentObject(data)

//            case .appearance:
//                AppAppearanceSettingView()

//            case .systemInfo:
//                SystemInfoSettingView()

            case .plugins:
                PluginSettingsView()

            case .about:
                AboutView()
            }
        }
        .frame(width: 700, height: 800)
        .onReceive(NotificationCenter.default.publisher(for: .didSaveGitUserConfig)) { _ in
            dismiss()
        }
    }

    // MARK: - View Components

    /// 侧边栏头部 - 应用信息
    private var sidebarHeader: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer().frame(height: 20)

            // App 图标
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(14)
                    .shadow(radius: 3)
            }

            // App 名称
            Text(appInfo.name)
                .font(.headline)
                .fontWeight(.semibold)

            // 版本和 Build 信息
            VStack(alignment: .center, spacing: 2) {
                Text("v\(appInfo.version)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Build \(appInfo.build)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 16)
        }
        .frame(maxWidth: .infinity)
        // .background(Color(nsColor: .controlBackgroundColor))
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
