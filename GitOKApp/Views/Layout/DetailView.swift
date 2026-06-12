import GitOKAppCore
import GitOKCoreKit
import GitOKSupportKit
import SwiftUI

/// 主窗口右侧内容区域。
struct DetailView: View {
    @EnvironmentObject var app: AppVM
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var p: PluginService
    @EnvironmentObject var themeProvider: AppThemeVM
    @EnvironmentObject var vm: ProjectVM

    let tab: String
    let pluginListViews: [GitOKPluginViewContribution]
    let statusBarVisibility: Bool

    private var pluginContext: GitOKPluginContext {
        p.makeContext(
            projectURL: vm.project?.url,
            isGitRepository: vm.currentProjectIsGitRepository,
            projects: g.projects.map { GitOKProjectSummary(url: $0.url, title: $0.title, path: $0.path) },
            selectedProjectURL: vm.project?.url,
            isSidebarVisible: app.sidebarVisibility
        )
    }

    var body: some View {
        Group {
            if g.projects.isEmpty {
                emptyProjectsView
            } else if vm.projectExists == false {
                projectNotFoundView
            } else {
                content
            }
        }
        .background(themeProvider.activeChromeTheme.workspaceBackgroundColor())
    }

    @ViewBuilder
    private var emptyProjectsView: some View {
        if let view = p.onboardingView(kind: .emptyProjects, context: pluginContext) {
            view
        } else {
            Text("No projects")
        }
    }

    @ViewBuilder
    private var projectNotFoundView: some View {
        if let view = p.onboardingView(kind: .projectNotFound, context: pluginContext) {
            view
        } else {
            Text("Project not found")
        }
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
            ForEach(pluginListViews) { item in
                item.view
            }
        }
        .frame(idealWidth: 200)
        .frame(minWidth: 120)
        .frame(maxWidth: 600)
        .frame(maxHeight: .infinity)
        .background(themeProvider.activeChromeTheme.sidebarBackgroundColor().opacity(0.92))
    }

    @ViewBuilder
    private var tabDetailView: some View {
        if p.hasPlugins, let tabDetailView = p.getEnabledTabDetailView(tab: tab, projectURL: vm.project?.url) {
            tabDetailView
        } else if let fallback = p.onboardingView(kind: .missingDetail, context: pluginContext) {
            fallback
        } else {
            Text("No detail view")
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
