import GitOKUI
import SwiftUI

open class GitOKPluginAdapter<Plugin: GitOKPlugin>: SuperPlugin {
    public let plugin: Plugin

    private let listViewProvider: ((String, URL?, GitOKPluginContext) -> AnyView?)?
    private let detailViewProvider: (@MainActor (String, GitOKPluginContext) -> AnyView?)?
    private let toolBarLeadingViewProvider: (() -> AnyView?)?
    private let toolBarTrailingViewProvider: (() -> AnyView?)?
    private let statusBarLeadingViewProvider: (() -> AnyView?)?
    private let statusBarTrailingViewProvider: (() -> AnyView?)?

    public init(
        _ plugin: Plugin = Plugin.shared,
        listViewProvider: ((String, URL?, GitOKPluginContext) -> AnyView?)? = nil,
        detailViewProvider: (@MainActor (String, GitOKPluginContext) -> AnyView?)? = nil,
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

    open var instanceLabel: String {
        plugin.instanceLabel
    }

    open var pluginOrder: Int {
        Plugin.metadata.order
    }

    open var pluginDisplayName: String {
        Plugin.metadata.displayName
    }

    open var pluginDescription: String {
        Plugin.metadata.description
    }

    open var pluginIconName: String {
        Plugin.metadata.iconName
    }

    open class var policy: GitOKPluginPolicy {
        Plugin.policy
    }

    open var pluginPolicy: GitOKPluginPolicy {
        Plugin.policy
    }

    open var pluginAllowUserToggle: Bool {
        pluginPolicy.allowUserToggle
    }

    open var pluginDefaultEnabled: Bool {
        pluginPolicy.defaultEnabled
    }

    open var pluginTableName: String {
        Plugin.metadata.tableName
    }

    open class var shouldRegister: Bool {
        Plugin.shouldRegister
    }

    open func addTabItem() -> String? {
        plugin.tabItem()
    }

    @MainActor
    open func addListView(tab: String, projectURL: URL?, context: GitOKPluginContext) -> AnyView? {
        listViewProvider?(tab, projectURL, context)
    }

    @MainActor
    open func addDetailView(for tab: String, context: GitOKPluginContext) -> AnyView? {
        detailViewProvider?(tab, context)
    }

    @MainActor
    open func addToolBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        toolBarLeadingViewProvider?() ?? plugin.toolBarLeadingView(context: context)
    }

    @MainActor
    open func addToolBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        toolBarTrailingViewProvider?() ?? plugin.toolBarTrailingView(context: context)
    }

    open func addRootView<Content>(@ViewBuilder content: () -> Content) -> AnyView? where Content: View {
        nil
    }

    @MainActor
    open func addStatusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        statusBarLeadingViewProvider?() ?? plugin.statusBarLeadingView(context: context)
    }

    @MainActor
    open func addStatusBarCenterView(context: GitOKPluginContext) -> AnyView? {
        plugin.statusBarCenterView(context: context)
    }

    @MainActor
    open func addStatusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        statusBarTrailingViewProvider?() ?? plugin.statusBarTrailingView(context: context)
    }

    @MainActor
    open func addThemeContributions() -> [GitOKUIThemeContribution] {
        plugin.themeContributions()
    }

    open func viewWithProjectURL(_ view: AnyView, projectURL: URL?) -> AnyView {
        view
    }
}
