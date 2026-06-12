import GitOKAppCore
import GitOKCoreKit
import SwiftUI

/// 主窗口左侧项目侧边栏。
struct SidebarView: View {
    @EnvironmentObject var themeProvider: AppThemeVM
    @EnvironmentObject var pluginProvider: PluginService
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var projectVM: ProjectVM
    @EnvironmentObject var app: AppVM

    private var pluginContext: GitOKPluginContext {
        pluginProvider.makeContext(
            projects: data.projects.map { GitOKProjectSummary(url: $0.url, title: $0.title, path: $0.path) },
            selectedProjectURL: projectVM.project?.url,
            isSidebarVisible: app.sidebarVisibility,
            onProjectSelection: { url in
                if let project = data.projects.first(where: { $0.url == url }) {
                    projectVM.setProject(project, reason: "SidebarSelection")
                }
            }
        )
    }

    var body: some View {
        Group {
            if let sidebar = pluginProvider.sidebarPaneItems(context: pluginContext).first {
                sidebar.view
            } else {
                Text("No sidebar")
            }
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
        .background(themeProvider.activeChromeTheme.sidebarBackgroundColor())
        .toolbar {
            ToolbarItem {
                BtnAdd()
            }
        }
    }
}

#Preview("Sidebar") {
    NavigationSplitView {
        SidebarView()
    } detail: {
        Text("Detail")
    }
    .inRootView()
    .frame(width: 800, height: 600)
}
