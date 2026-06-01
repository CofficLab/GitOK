import GitOKCoreKit
import MagicKit
import SwiftUI

/// 主窗口右侧内容区域。
struct DetailView: View {
    @EnvironmentObject var app: AppVM
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var p: PluginVM
    @EnvironmentObject var themeProvider: AppThemeVM
    @EnvironmentObject var vm: ProjectVM

    let tab: String
    let pluginListViews: [(plugin: SuperPlugin, view: AnyView)]
    let statusBarVisibility: Bool

    var body: some View {
        Group {
            if g.projects.isEmpty {
                NoRepositoriesGuideView()
            } else if vm.projectExists == false {
                GuideView(
                    systemImage: "folder.badge.questionmark",
                    title: "项目不存在"
                ).setIconColor(.red.opacity(0.5))
            } else {
                content
            }
        }
        .background(themeProvider.activeChromeTheme.workspaceBackgroundColor())
    }

    @ViewBuilder
    private var content: some View {
        if pluginListViews.isEmpty {
            VStack(spacing: 0) {
                tabDetailView
                statusBar
            }
            .frame(maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                HSplitView {
                    pluginList
                    tabDetailView
                }.frame(maxHeight: .infinity)

                statusBar
            }
        }
    }

    private var pluginList: some View {
        VStack(spacing: 0) {
            ForEach(pluginListViews, id: \.plugin.instanceLabel) { item in
                item.view
            }
        }
        .frame(idealWidth: 200)
        .frame(minWidth: 120)
        .frame(maxWidth: 300)
        .frame(maxHeight: .infinity)
        .background(themeProvider.activeChromeTheme.sidebarBackgroundColor().opacity(0.92))
    }

    @ViewBuilder
    private var tabDetailView: some View {
        if p.hasPlugins, let tabDetailView = p.getEnabledTabDetailView(tab: tab, projectURL: vm.project?.url) {
            tabDetailView
        } else {
            GuideView(
                systemImage: "puzzlepiece.extension",
                title: "暂无可用视图",
                subtitle: "请在设置中启用相关插件以显示内容",
                action: {
                    app.openPluginSettings()
                },
                actionLabel: "打开插件设置"
            )
            .setIconColor(.secondary)
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        if statusBarVisibility {
            StatusBar()
        }
    }
}

#Preview("Detail") {
    DetailView(
        tab: "",
        pluginListViews: [],
        statusBarVisibility: true
    )
    .inRootView()
    .frame(width: 800, height: 600)
}
