import MagicKit
import GitOKPluginKit
import GitOKUI
import SwiftUI

/// 状态栏视图
struct StatusBar: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "📊"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 插件提供者环境对象
    @EnvironmentObject var p: PluginVM

    @EnvironmentObject var data: DataVM

    @EnvironmentObject var themeProvider: AppThemeVM

    @EnvironmentObject var projectVM: ProjectVM

    /// 视图主体
    var body: some View {
        HStack(spacing: 0) {
            // 状态栏左侧区域
            ForEach(Array(p.getEnabledStatusBarLeadingViews(
                selectedFilePath: projectVM.file?.file,
                projectPath: projectVM.project?.path
            ).enumerated()), id: \.offset) { _, view in
                view
            }

            Spacer()

            // 状态栏中间区域
            ForEach(Array(p.getEnabledStatusBarCenterViews(activityStatus: data.activityStatus).enumerated()), id: \.offset) { _, view in
                view
            }

            Spacer()

            // 状态栏右侧区域
            ForEach(Array(p.getEnabledStatusBarTrailingViews(
                projectURL: projectVM.project?.url,
                projectPath: projectVM.project?.path,
                projectTitle: projectVM.project?.title,
                branchName: data.branch?.name,
                isGitRepository: projectVM.project?.isGitRepo ?? false
            ).enumerated()), id: \.offset) { _, view in
                view
                    .environmentObject(GitOKUIThemeRegistry.shared)
                    .environment(\.gitOKThemeSelectionHandler) { themeId in
                        themeProvider.selectTheme(themeId)
                    }
            }
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(themeProvider.activeChromeTheme.workspaceSecondaryTextColor())
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(themeProvider.activeChromeTheme.sidebarBackgroundColor().opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(themeProvider.activeChromeTheme.accentColors().primary.opacity(0.2))
                .frame(height: 1)
        }
    }
}

// MARK: - Preview

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
