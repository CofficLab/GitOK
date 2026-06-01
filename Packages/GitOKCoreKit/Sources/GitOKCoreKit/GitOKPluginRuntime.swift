import Foundation
import GitOKUI
import SwiftUI

@MainActor
public final class GitOKPluginRuntime {
    public private(set) var plugins: [any SuperPlugin] = []

    private var registeredPlugins: [any SuperPlugin] = []
    private var usedLabels: Set<String> = []
    private let settingsStore: PluginSettingsStore

    public init(settingsStore: PluginSettingsStore = .shared) {
        self.settingsStore = settingsStore
    }

    public var registeredCount: Int {
        registeredPlugins.count
    }

    public func clearRegisteredPlugins() {
        registeredPlugins.removeAll()
        usedLabels.removeAll()
        plugins.removeAll()
    }

    public func register(_ plugin: any SuperPlugin) {
        let label = plugin.instanceLabel

        if usedLabels.contains(label) {
            let pluginType = String(describing: type(of: plugin))
            assertionFailure("Duplicate plugin label '\(label)' in \(pluginType)")
            return
        }

        usedLabels.insert(label)
        registeredPlugins.append(plugin)
        plugins = sortedRegisteredPlugins()
    }

    public func sortedRegisteredPlugins() -> [any SuperPlugin] {
        registeredPlugins.sorted { $0.pluginOrder < $1.pluginOrder }
    }

    public func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        if !plugin.pluginAllowUserToggle {
            return true
        }

        let pluginId = plugin.instanceLabel
        if settingsStore.hasUserConfigured(pluginId) {
            return settingsStore.isPluginEnabled(pluginId, defaultEnabled: plugin.pluginDefaultEnabled)
        }

        return plugin.pluginDefaultEnabled
    }

    public var tabNames: [String] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addTabItem() }
    }

    public var configurablePlugins: [PluginInfo] {
        plugins
            .filter { $0.pluginAllowUserToggle }
            .map { plugin in
                let tableName = plugin.pluginTableName
                return PluginInfo(
                    id: plugin.instanceLabel,
                    name: String(localized: .init(stringLiteral: plugin.pluginDisplayName), table: tableName),
                    description: String(localized: .init(stringLiteral: plugin.pluginDescription), table: tableName),
                    icon: plugin.pluginIconName,
                    defaultEnabled: plugin.pluginDefaultEnabled,
                    isDeveloperEnabled: { true }
                )
            }
            .sorted { $0.name < $1.name }
    }

    public func enabledToolbarLeadingViews(context: GitOKPluginContext) -> [(plugin: any SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarLeadingView(context: context) else { return nil }
            return (plugin, view)
        }
    }

    public func enabledToolbarTrailingViews(context: GitOKPluginContext) -> [(plugin: any SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarTrailingView(context: context) else { return nil }
            return (plugin, view)
        }
    }

    public func enabledListViews(
        tab: String,
        projectURL: URL?,
        context: GitOKPluginContext
    ) -> [(plugin: any SuperPlugin, view: AnyView)] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addListView(tab: tab, projectURL: projectURL, context: context) else { return nil }
            return (plugin, view)
        }
    }

    public func enabledDetailView(for tab: String, context: GitOKPluginContext) -> AnyView? {
        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
            if let view = plugin.addDetailView(for: tab, context: context) {
                return view
            }
        }
        return nil
    }

    public func enabledStatusBarLeadingViews(context: GitOKPluginContext) -> [AnyView] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarLeadingView(context: context) }
    }

    public func enabledStatusBarCenterViews(context: GitOKPluginContext) -> [AnyView] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarCenterView(context: context) }
    }

    public func enabledStatusBarTrailingViews(context: GitOKPluginContext) -> [AnyView] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarTrailingView(context: context) }
    }

    public func themeContributions() -> [GitOKUIThemeContribution] {
        plugins.flatMap { plugin -> [GitOKUIThemeContribution] in
            guard isPluginEnabled(plugin) else { return [] }
            let pluginOrder = plugin.pluginOrder
            return plugin.addThemeContributions().map { contribution in
                GitOKUIThemeContribution(
                    sortKey: ThemeSortKey(pluginOrder: pluginOrder, themeId: contribution.id),
                    chromeTheme: contribution.chromeTheme,
                    editorThemeId: contribution.editorThemeId,
                    uiTheme: contribution.uiTheme,
                    attachments: contribution.attachments
                )
            }
        }
    }

    public func rootViewWrapper<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
        var wrapped = AnyView(content())

        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
            wrapped = plugin.wrapRoot(wrapped)
        }

        return wrapped
    }
}
