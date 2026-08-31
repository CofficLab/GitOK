import GitOKAppCore
import Combine
import KitGitOKCore
import GitOKUI
import SwiftUI

/// Host engine of the factory layer (Lumi FactoryCore equivalent).
///
/// Aggregates plugin contributions for the app shell. The concrete plugin
/// list is injected by the composition root; this type stays plugin-agnostic.
@MainActor
public final class PluginService: ObservableObject {
    private let runtime: GitOKPluginRuntime
    private let pluginDependencies: GitOKPluginDependencies
    private var cancellables = Set<AnyCancellable>()

    public init(
        pluginDependencies: GitOKPluginDependencies,
        pluginTypes: [any GitOKPlugin.Type]
    ) {
        self.pluginDependencies = pluginDependencies
        self.runtime = GitOKPluginRuntime()
        for pluginType in pluginTypes where pluginType.shouldRegister {
            runtime.register(pluginType)
        }

        PluginSettingsStore.shared.$settings
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// Runs the two-phase boot sequence once the shell finished registering
    /// its services. Throws when required services are missing.
    public func startupPlugins() throws {
        try runtime.startup(dependencies: pluginDependencies)
    }

    public var hasPlugins: Bool { registeredPluginCount > 0 }
    public var registeredPluginCount: Int { runtime.registeredCount }
    public var configurablePlugins: [PluginInfo] { runtime.configurablePlugins }

    public func makeContext(
        projectURL: URL? = nil,
        projectPath: String? = nil,
        projectTitle: String? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false,
        selectedFilePath: String? = nil,
        remoteTrackingStatus: GitOKRemoteTrackingStatus? = nil,
        projects: [GitOKProjectSummary] = [],
        selectedProjectURL: URL? = nil,
        isSidebarVisible: Bool = true,
        activityStatus: String? = nil,
        canImportRepository: Bool = false,
        onProjectSelection: @escaping GitOKProjectSelectionHandler = { _ in },
        onProjectExists: @escaping GitOKProjectExistenceHandler = { _ in false },
        onRepositoryImported: @escaping GitOKRepositoryImportCompletionHandler = { _ in false },
        onActivityStatusUpdate: @escaping GitOKActivityStatusUpdateHandler = { _ in },
        onInfoMessage: @escaping GitOKUserMessageHandler = { _ in },
        onThemeSelection: @escaping GitOKThemeSelectionHandler = { _ in },
        onCleanStatusUpdate: @escaping GitOKCleanStatusUpdateHandler = { _ in },
        onGitDirectoryChange: @escaping GitOKGitDirectoryChangeHandler = { _ in },
        onUnpushedCommitsUpdate: @escaping GitOKUnpushedCommitsUpdateHandler = { _, _ in },
        onRemoteTrackingUpdate: @escaping GitOKRemoteTrackingUpdateHandler = { _, _ in }
    ) -> GitOKPluginContext {
        GitOKPluginContext(
            dependencies: pluginDependencies,
            projectURL: projectURL,
            projectPath: projectPath,
            projectTitle: projectTitle,
            branchName: branchName,
            isGitRepository: isGitRepository,
            selectedFilePath: selectedFilePath,
            remoteTrackingStatus: remoteTrackingStatus,
            projects: projects,
            selectedProjectURL: selectedProjectURL,
            isSidebarVisible: isSidebarVisible,
            activityStatus: activityStatus,
            canImportRepository: canImportRepository,
            onProjectSelection: onProjectSelection,
            onProjectExists: onProjectExists,
            onRepositoryImported: onRepositoryImported,
            onActivityStatusUpdate: onActivityStatusUpdate,
            onInfoMessage: onInfoMessage,
            onThemeSelection: onThemeSelection,
            onCleanStatusUpdate: onCleanStatusUpdate,
            onGitDirectoryChange: onGitDirectoryChange,
            onUnpushedCommitsUpdate: onUnpushedCommitsUpdate,
            onRemoteTrackingUpdate: onRemoteTrackingUpdate
        )
    }

    public func getEnabledToolbarLeadingViews(
        projectURL: URL? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false,
        projects: [GitOKProjectSummary] = [],
        selectedProjectURL: URL? = nil,
        isSidebarVisible: Bool = true,
        onSelectProject: @escaping GitOKProjectSelectionHandler = { _ in },
        canImportRepository: Bool = false,
        onProjectExists: @escaping GitOKProjectExistenceHandler = { _ in false },
        onRepositoryImported: @escaping GitOKRepositoryImportCompletionHandler = { _ in false },
        onActivityStatusUpdate: @escaping GitOKActivityStatusUpdateHandler = { _ in },
        onInfoMessage: @escaping GitOKUserMessageHandler = { _ in }
    ) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        let context = makeContext(
            projectURL: projectURL,
            branchName: branchName,
            isGitRepository: isGitRepository,
            projects: projects,
            selectedProjectURL: selectedProjectURL,
            isSidebarVisible: isSidebarVisible,
            canImportRepository: canImportRepository,
            onProjectSelection: onSelectProject,
            onProjectExists: onProjectExists,
            onRepositoryImported: onRepositoryImported,
            onActivityStatusUpdate: onActivityStatusUpdate,
            onInfoMessage: onInfoMessage
        )
        return runtime.enabledToolbarLeadingViews(context: context)
    }

    public func getEnabledToolbarTrailingViews(
        projectURL: URL? = nil,
        branchName: String? = nil,
        remoteTrackingStatus: GitOKRemoteTrackingStatus? = nil,
        isGitRepository: Bool = false
    ) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        let context = makeContext(
            projectURL: projectURL,
            branchName: branchName,
            isGitRepository: isGitRepository,
            remoteTrackingStatus: remoteTrackingStatus
        )
        return runtime.enabledToolbarTrailingViews(context: context)
    }

    public func getEnabledRailViews(
        tab: GitOKAppTab,
        project: Project?,
        isGitRepository: Bool = false
    ) -> [GitOKRailItem] {
        guard hasPlugins else { return [] }
        let context = makeContext(
            projectURL: project?.url,
            projectPath: project.map { $0.url.path },
            projectTitle: project?.title,
            isGitRepository: isGitRepository
        )
        return runtime.enabledRailViews(tab: tab, context: context)
    }

    public func getEnabledPluginListViews(
        tab: GitOKAppTab,
        project: Project?,
        isGitRepository: Bool = false
    ) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        let context = makeContext(
            projectURL: project?.url,
            projectPath: project.map { $0.url.path },
            projectTitle: project?.title,
            isGitRepository: isGitRepository
        )
        return runtime.enabledListViews(tab: tab, projectURL: project?.url, context: context)
    }

    public func getEnabledStatusBarLeadingViews(selectedFilePath: String? = nil, projectPath: String? = nil) -> [AnyView] {
        guard hasPlugins else { return [] }
        let context = makeContext(projectPath: projectPath, selectedFilePath: selectedFilePath)
        return runtime.enabledStatusBarLeadingViews(context: context)
    }

    public func getEnabledStatusBarCenterViews(activityStatus: String? = nil) -> [AnyView] {
        guard hasPlugins else { return [] }
        let context = makeContext(activityStatus: activityStatus)
        return runtime.enabledStatusBarCenterViews(context: context)
    }

    public func getEnabledStatusBarTrailingViews(
        projectURL: URL? = nil,
        projectPath: String? = nil,
        projectTitle: String? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false,
        onThemeSelection: @escaping GitOKThemeSelectionHandler = { _ in }
    ) -> [AnyView] {
        guard hasPlugins else { return [] }
        let context = makeContext(
            projectURL: projectURL,
            projectPath: projectPath,
            projectTitle: projectTitle,
            branchName: branchName,
            isGitRepository: isGitRepository,
            onThemeSelection: onThemeSelection
        )
        return runtime.enabledStatusBarTrailingViews(context: context)
    }

    public func getThemeContributions() -> [GitOKUIThemeContribution] {
        guard hasPlugins else { return [] }
        return runtime.themeContributions()
    }

    public func getRootViewWrapper<Content: View>(
        context: GitOKPluginContext,
        @ViewBuilder content: () -> Content
    ) -> AnyView {
        guard hasPlugins else { return AnyView(content()) }
        return runtime.rootViewWrapper(context: context, content: content)
    }

    public func toolbarLeadingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledToolbarLeadingViews(context: context)
    }

    public func toolbarTrailingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledToolbarTrailingViews(context: context)
    }

    public func railViews(tab: GitOKAppTab, context: GitOKPluginContext) -> [GitOKRailItem] {
        guard hasPlugins else { return [] }
        return runtime.enabledRailViews(tab: tab, context: context)
    }

    public func listViews(tab: GitOKAppTab, context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledListViews(tab: tab, projectURL: context.projectURL, context: context)
    }

    public func detailView(tab: GitOKAppTab, context: GitOKPluginContext) -> AnyView? {
        guard hasPlugins else { return nil }
        return runtime.enabledDetailView(for: tab, context: context)
    }

    public func statusBarLeadingViews(context: GitOKPluginContext) -> [AnyView] {
        guard hasPlugins else { return [] }
        return runtime.enabledStatusBarLeadingViews(context: context)
    }

    public func statusBarCenterViews(context: GitOKPluginContext) -> [AnyView] {
        guard hasPlugins else { return [] }
        return runtime.enabledStatusBarCenterViews(context: context)
    }

    public func statusBarTrailingViews(context: GitOKPluginContext) -> [AnyView] {
        guard hasPlugins else { return [] }
        return runtime.enabledStatusBarTrailingViews(context: context)
    }

    public func themeContributions() -> [GitOKUIThemeContribution] {
        getThemeContributions()
    }

    public func rootViewWrapper(context: GitOKPluginContext, @ViewBuilder content: () -> some View) -> AnyView {
        getRootViewWrapper(context: context, content: content)
    }

    public func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        guard hasPlugins else { return [] }
        return runtime.enabledSettingsPaneItems(context: context)
    }

    public func sidebarPaneItems(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledSidebarPaneItems(context: context)
    }

    public func onboardingView(kind: GitOKOnboardingKind, context: GitOKPluginContext) -> AnyView? {
        guard hasPlugins else { return nil }
        return runtime.enabledOnboardingView(kind: kind, context: context)
    }

    public func pluginIntroductionView(pluginID: String, context: GitOKPluginContext) -> AnyView? {
        guard hasPlugins else { return nil }
        return runtime.pluginIntroductionView(pluginID: pluginID, context: context)
    }
}

extension PluginService: GitOKThemeContributionsProviding {}
