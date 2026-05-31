import GitCoreKit
import GitOKPluginKit
import GitOKUI
import SwiftUI

final class PackagedPluginAdapter<Plugin: GitOKPackagedPlugin>: SuperPlugin {
    private let plugin: Plugin
    private let listViewProvider: ((String, Project?) -> AnyView?)?
    private let detailViewProvider: (@MainActor (String) -> AnyView?)?
    private let toolBarLeadingViewProvider: (() -> AnyView?)?
    private let toolBarTrailingViewProvider: (() -> AnyView?)?
    private let statusBarLeadingViewProvider: (() -> AnyView?)?
    private let statusBarTrailingViewProvider: (() -> AnyView?)?

    init(
        _ plugin: Plugin = Plugin.shared,
        listViewProvider: ((String, Project?) -> AnyView?)? = nil,
        detailViewProvider: (@MainActor (String) -> AnyView?)? = nil,
        toolBarLeadingViewProvider: (() -> AnyView?)? = nil,
        toolBarTrailingViewProvider: (() -> AnyView?)? = nil,
        statusBarLeadingViewProvider: (() -> AnyView?)? = nil,
        statusBarTrailingViewProvider: (() -> AnyView?)? = nil
    ) {
        self.plugin = plugin
        self.listViewProvider = listViewProvider
        self.detailViewProvider = detailViewProvider
        self.toolBarLeadingViewProvider = toolBarLeadingViewProvider
        self.toolBarTrailingViewProvider = toolBarTrailingViewProvider
        self.statusBarLeadingViewProvider = statusBarLeadingViewProvider
        self.statusBarTrailingViewProvider = statusBarTrailingViewProvider
    }

    var instanceLabel: String {
        plugin.instanceLabel
    }

    var pluginOrder: Int {
        Plugin.metadata.order
    }

    var pluginDisplayName: String {
        Plugin.metadata.displayName
    }

    var pluginDescription: String {
        Plugin.metadata.description
    }

    var pluginIconName: String {
        Plugin.metadata.iconName
    }

    var pluginAllowUserToggle: Bool {
        Plugin.metadata.allowUserToggle
    }

    var pluginDefaultEnabled: Bool {
        Plugin.metadata.defaultEnabled
    }

    var pluginTableName: String {
        Plugin.metadata.tableName
    }

    static var shouldRegister: Bool {
        Plugin.shouldRegister
    }

    func addTabItem() -> String? {
        plugin.tabItem()
    }

    func addListView(tab: String, project: Project?) -> AnyView? {
        listViewProvider?(tab, project)
    }

    @MainActor
    func addDetailView(for tab: String) -> AnyView? {
        detailViewProvider?(tab)
    }

    @MainActor
    func addToolBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        toolBarLeadingViewProvider?() ?? plugin.toolBarLeadingView(context: context)
    }

    @MainActor
    func addToolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        toolBarTrailingViewProvider?() ?? plugin.toolBarTrailingView(context: context)
    }

    func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        AnyView(PackagedPluginRootHost(plugin: plugin, content: content()))
    }

    @MainActor
    func addStatusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        statusBarLeadingViewProvider?() ?? plugin.statusBarLeadingView(context: context)
    }

    @MainActor
    func addStatusBarCenterView(context: GitOKPluginContext) -> AnyView? {
        plugin.statusBarCenterView(context: context)
    }

    @MainActor
    func addStatusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        statusBarTrailingViewProvider?() ?? plugin.statusBarTrailingView(context: context)
    }

    @MainActor
    func addThemeContributions() -> [GitOKUIThemeContribution] {
        plugin.themeContributions()
    }

    func viewWithProjectURL(_ view: AnyView, projectURL: URL?) -> AnyView {
        AnyView(view.environment(\.gitOKProjectURL, projectURL))
    }
}

private struct PackagedPluginRootHost<Plugin: GitOKPackagedPlugin, Content: View>: View {
    let plugin: Plugin
    let content: Content

    @EnvironmentObject private var projectVM: ProjectVM

    var body: some View {
        let base = AnyView(content)
        let wrapped = plugin.rootView(base) ?? base

        return wrapped
            .environment(\.gitOKProjectURL, projectVM.project?.url)
            .environment(\.gitOKCleanStatusUpdateHandler) { isClean in
                projectVM.updateIsClean(isClean)
            }
            .environment(\.gitOKGitDirectoryChangeHandler) { change in
                postGitDirectoryChange(change)
            }
            .environment(\.gitOKUnpushedCommitsUpdateHandler) { count, hashes in
                projectVM.updateUnpushedCommits(count, hashes: hashes)
            }
            .environment(\.gitOKRemoteTrackingUpdateHandler) { status, fetchedAt in
                if let status {
                    projectVM.updateAheadBehind(
                        GitCoreKit.GitAheadBehind(
                            ahead: status.ahead,
                            behind: status.behind,
                            hasUpstream: status.hasUpstream
                        )
                    )
                } else {
                    projectVM.resetRemoteTrackingState()
                }

                if let fetchedAt {
                    projectVM.updateLastFetchedAt(fetchedAt)
                }
            }
    }

    private func postGitDirectoryChange(_ change: GitOKGitDirectoryChange) {
        guard let project = projectVM.project else { return }
        guard project.url.standardizedFileURL == change.projectURL.standardizedFileURL else { return }

        var additionalInfo: [String: Any] = [
            "gitPath": change.gitDirectoryPath,
            "changeKind": change.changeKind,
            "headChanged": change.headChanged,
            "indexChanged": change.indexChanged,
            "stashChanged": change.stashChanged,
            "refsChanged": change.refsChanged
        ]

        if let previousHead = change.previousHead {
            additionalInfo["previousHead"] = previousHead
        }

        if let head = change.head {
            additionalInfo["head"] = head
        }

        project.postEvent(
            name: .projectGitDirectoryDidChange,
            operation: "gitDirectoryChanged",
            additionalInfo: additionalInfo
        )

        if change.headChanged {
            project.postEvent(name: .projectGitHeadDidChange, operation: "gitHeadChanged", additionalInfo: additionalInfo)
        }

        if change.indexChanged {
            project.postEvent(name: .projectGitIndexDidChange, operation: "gitIndexChanged", additionalInfo: additionalInfo)
        }

        if change.stashChanged {
            project.postEvent(name: .projectGitStashDidChange, operation: "gitStashChanged", additionalInfo: additionalInfo)
        }

        if change.refsChanged {
            project.postEvent(name: .projectGitRefsDidChange, operation: "gitRefsChanged", additionalInfo: additionalInfo)
        }
    }
}
