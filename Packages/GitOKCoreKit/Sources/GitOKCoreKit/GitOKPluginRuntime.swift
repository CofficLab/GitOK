import Foundation
import GitOKUI
import SwiftUI

@MainActor
public final class GitOKPluginRuntime {
    private var plugins: [any SuperPlugin] = []
    private let settingsStore: PluginSettingsStore

    private var usedLabels: Set<String> = []

    public init(settingsStore: PluginSettingsStore = .shared) {
        self.settingsStore = settingsStore
    }

    public var registeredCount: Int {
        plugins.count
    }

    public var registeredPluginLabels: [String] {
        plugins.map(\.instanceLabel)
    }

    public func clearRegisteredPlugins() {
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
        plugins.append(plugin)
        plugins.sort { $0.pluginOrder < $1.pluginOrder }
    }

    private func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        let policy = plugin.pluginPolicy

        guard policy.shouldRegister else { return false }
        guard policy.allowUserToggle else { return policy.defaultEnabled }

        return settingsStore.isPluginEnabled(
            plugin.instanceLabel,
            defaultEnabled: policy.defaultEnabled
        )
    }

    public var tabNames: [String] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addTabItem() }
    }

    public var configurablePlugins: [PluginInfo] {
        plugins
            .filter { $0.pluginPolicy.allowUserToggle }
            .map { plugin in
                return PluginInfo(
                    id: plugin.instanceLabel,
                    name: String(localized: .init(stringLiteral: plugin.pluginDisplayName), bundle: .module),
                    description: String(localized: .init(stringLiteral: plugin.pluginDescription), bundle: .module),
                    icon: plugin.pluginIconName,
                    defaultEnabled: plugin.pluginPolicy.defaultEnabled,
                    isDeveloperEnabled: { plugin.pluginPolicy.shouldRegister }
                )
            }
            .sorted { $0.name < $1.name }
    }

    public func enabledToolbarLeadingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarLeadingView(context: context) else { return nil }
            return GitOKPluginViewContribution(id: plugin.instanceLabel, view: view)
        }
    }

    public func enabledToolbarTrailingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarTrailingView(context: context) else { return nil }
            return GitOKPluginViewContribution(id: plugin.instanceLabel, view: view)
        }
    }

    public func enabledListViews(
        tab: String,
        projectURL: URL?,
        context: GitOKPluginContext
    ) -> [GitOKPluginViewContribution] {
        plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addListView(tab: tab, projectURL: projectURL, context: context) else { return nil }
            return GitOKPluginViewContribution(id: plugin.instanceLabel, view: view)
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

    public func rootViewWrapper<Content: View>(
        context: GitOKPluginContext = GitOKPluginContext(),
        @ViewBuilder content: () -> Content
    ) -> AnyView {
        var wrapped = AnyView(content())

        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
            wrapped = plugin.wrapRoot(wrapped, context: context)
        }

        return wrapped
    }
}
