import Foundation
import GitOKUI
import SwiftUI

@MainActor
public final class GitOKPluginRuntime {
    private var pluginTypes: [any GitOKPlugin.Type] = []
    private let settingsStore: PluginSettingsStore

    public init(settingsStore: PluginSettingsStore = .shared) {
        self.settingsStore = settingsStore
    }

    public var registeredCount: Int {
        pluginTypes.count
    }

    public var registeredPluginLabels: [String] {
        pluginTypes.map { $0.metadata.id }
    }

    public func clearRegisteredPlugins() {
        pluginTypes.removeAll()
    }

    public func register(_ pluginType: any GitOKPlugin.Type) {
        let label = pluginType.metadata.id
        guard !pluginTypes.contains(where: { $0.metadata.id == label }) else {
            assertionFailure("Duplicate plugin id '\(label)'")
            return
        }
        pluginTypes.append(pluginType)
        pluginTypes.sort { $0.metadata.order < $1.metadata.order }
    }

    private func isPluginEnabled(_ pluginType: any GitOKPlugin.Type) -> Bool {
        let policy = pluginType.policy
        guard policy.shouldRegister else { return false }
        guard policy.allowUserToggle else { return policy.defaultEnabled }
        return settingsStore.isPluginEnabled(
            pluginType.metadata.id,
            defaultEnabled: policy.defaultEnabled
        )
    }

    public var tabNames: [String] {
        pluginTypes
            .filter { isPluginEnabled($0) }
            .flatMap { $0.tabItems(context: GitOKPluginContext()) }
            .sorted { $0.order < $1.order }
            .map(\.name)
    }

    public var configurablePlugins: [PluginInfo] {
        pluginTypes
            .filter { $0.policy.allowUserToggle }
            .map { type in
                PluginInfo(
                    id: type.metadata.id,
                    name: type.metadata.displayName,
                    description: type.metadata.description,
                    icon: type.metadata.iconName,
                    defaultEnabled: type.metadata.defaultEnabled,
                    allowUserToggle: type.policy.allowUserToggle,
                    isDeveloperEnabled: { type.policy.shouldRegister }
                )
            }
            .sorted { $0.name < $1.name }
    }

    public var managedPlugins: [PluginInfo] {
        pluginTypes
            .filter { $0.policy.shouldRegister }
            .map { type in
                PluginInfo(
                    id: type.metadata.id,
                    name: type.metadata.displayName,
                    description: type.metadata.description,
                    icon: type.metadata.iconName,
                    defaultEnabled: type.metadata.defaultEnabled,
                    allowUserToggle: type.policy.allowUserToggle,
                    isDeveloperEnabled: { type.policy.shouldRegister }
                )
            }
            .sorted { $0.name < $1.name }
    }

    public func enabledToolbarLeadingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        pluginTypes.flatMap { type -> [GitOKPluginViewContribution] in
            guard isPluginEnabled(type) else { return [] }
            return type.toolbarLeadingItems(context: context).map {
                GitOKPluginViewContribution(id: $0.id, view: $0.view)
            }
        }
    }

    public func enabledToolbarTrailingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        pluginTypes.flatMap { type -> [GitOKPluginViewContribution] in
            guard isPluginEnabled(type) else { return [] }
            return type.toolbarTrailingItems(context: context).map {
                GitOKPluginViewContribution(id: $0.id, view: $0.view)
            }
        }
    }

    public func enabledListViews(
        tab: String,
        projectURL: URL?,
        context: GitOKPluginContext
    ) -> [GitOKPluginViewContribution] {
        pluginTypes.flatMap { type -> [GitOKPluginViewContribution] in
            guard isPluginEnabled(type) else { return [] }
            return type.listPaneItems(context: context, tab: tab)
        }
    }

    public func enabledDetailView(for tab: String, context: GitOKPluginContext) -> AnyView? {
        for type in pluginTypes {
            guard isPluginEnabled(type) else { continue }
            for item in type.detailPaneItems(context: context, tab: tab) {
                return item.view
            }
        }
        return nil
    }

    public func enabledStatusBarLeadingViews(context: GitOKPluginContext) -> [AnyView] {
        pluginTypes.flatMap { type -> [AnyView] in
            guard isPluginEnabled(type) else { return [] }
            return type.statusBarLeadingItems(context: context).map(\.view)
        }
    }

    public func enabledStatusBarCenterViews(context: GitOKPluginContext) -> [AnyView] {
        pluginTypes.flatMap { type -> [AnyView] in
            guard isPluginEnabled(type) else { return [] }
            return type.statusBarCenterItems(context: context).map(\.view)
        }
    }

    public func enabledStatusBarTrailingViews(context: GitOKPluginContext) -> [AnyView] {
        pluginTypes.flatMap { type -> [AnyView] in
            guard isPluginEnabled(type) else { return [] }
            return type.statusBarTrailingItems(context: context).map(\.view)
        }
    }

    public func themeContributions() -> [GitOKUIThemeContribution] {
        let context = GitOKPluginContext()
        return pluginTypes.flatMap { type -> [GitOKUIThemeContribution] in
            guard isPluginEnabled(type) else { return [] }
            let pluginOrder = type.metadata.order
            return type.themeContributions(context: context).map { contribution in
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

        for type in pluginTypes {
            guard isPluginEnabled(type) else { continue }
            if let overlay = type.rootOverlay(context: context, content: wrapped) {
                wrapped = overlay
            }
        }

        return wrapped
    }

    public func enabledSettingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        pluginTypes.flatMap { type -> [GitOKSettingsPaneItem] in
            guard isPluginEnabled(type) else { return [] }
            return type.settingsPaneItems(context: context)
        }
        .sorted { $0.order < $1.order }
    }

    public func enabledSidebarPaneItems(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        pluginTypes.flatMap { type -> [GitOKPluginViewContribution] in
            guard isPluginEnabled(type) else { return [] }
            return type.sidebarPaneItems(context: context)
        }
    }

    public func enabledOnboardingPaneItems(context: GitOKPluginContext) -> [GitOKOnboardingPaneItem] {
        pluginTypes.flatMap { type -> [GitOKOnboardingPaneItem] in
            guard isPluginEnabled(type) else { return [] }
            return type.onboardingPaneItems(context: context)
        }
    }

    public func enabledOnboardingView(
        kind: GitOKOnboardingKind,
        context: GitOKPluginContext
    ) -> AnyView? {
        for item in enabledOnboardingPaneItems(context: context) where item.kind == kind {
            return item.view
        }
        return nil
    }

    public func pluginIntroductionView(
        pluginID: String,
        context: GitOKPluginContext
    ) -> AnyView? {
        guard let type = pluginTypes.first(where: { $0.metadata.id == pluginID }) else { return nil }
        return type.pluginIntroductionView(context: context)
    }
}
