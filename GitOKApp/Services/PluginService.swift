import GitOKAppCore
import Combine
import GitOKCoreKit
import GitOKPluginRegistry
import GitOKUI
import SwiftUI

@MainActor
final class PluginService: ObservableObject {
    private let runtime: GitOKPluginRuntime
    private let pluginDependencies: GitOKPluginDependencies
    private var cancellables = Set<AnyCancellable>()

    init(pluginDependencies: GitOKPluginDependencies) {
        self.pluginDependencies = pluginDependencies
        self.runtime = GitOKPluginRuntime()
        GeneratedPluginRegistry.registerAll(into: runtime)

        PluginSettingsStore.shared.$settings
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var hasPlugins: Bool { registeredPluginCount > 0 }
    var registeredPluginCount: Int { runtime.registeredCount }
    var tabNames: [String] { runtime.tabNames }
    var configurablePlugins: [PluginInfo] { runtime.configurablePlugins }

    func makeContext(
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

    func getEnabledToolbarLeadingViews(
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

    func getEnabledToolbarTrailingViews(
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

    func getEnabledPluginListViews(
        tab: String,
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

    func getEnabledTabDetailView(tab: String, projectURL: URL? = nil) -> AnyView? {
        guard hasPlugins else { return nil }
        let context = makeContext(projectURL: projectURL)
        return runtime.enabledDetailView(for: tab, context: context)
    }

    func getEnabledStatusBarLeadingViews(selectedFilePath: String? = nil, projectPath: String? = nil) -> [AnyView] {
        guard hasPlugins else { return [] }
        let context = makeContext(projectPath: projectPath, selectedFilePath: selectedFilePath)
        return runtime.enabledStatusBarLeadingViews(context: context)
    }

    func getEnabledStatusBarCenterViews(activityStatus: String? = nil) -> [AnyView] {
        guard hasPlugins else { return [] }
        let context = makeContext(activityStatus: activityStatus)
        return runtime.enabledStatusBarCenterViews(context: context)
    }

    func getEnabledStatusBarTrailingViews(
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

    func getThemeContributions() -> [GitOKUIThemeContribution] {
        guard hasPlugins else { return [] }
        return runtime.themeContributions()
    }

    func getRootViewWrapper<Content: View>(
        context: GitOKPluginContext,
        @ViewBuilder content: () -> Content
    ) -> AnyView {
        guard hasPlugins else { return AnyView(content()) }
        return runtime.rootViewWrapper(context: context, content: content)
    }

    func toolbarLeadingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledToolbarLeadingViews(context: context)
    }

    func toolbarTrailingViews(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledToolbarTrailingViews(context: context)
    }

    func listViews(tab: String, context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledListViews(tab: tab, projectURL: context.projectURL, context: context)
    }

    func detailView(tab: String, context: GitOKPluginContext) -> AnyView? {
        guard hasPlugins else { return nil }
        return runtime.enabledDetailView(for: tab, context: context)
    }

    func statusBarLeadingViews(context: GitOKPluginContext) -> [AnyView] {
        guard hasPlugins else { return [] }
        return runtime.enabledStatusBarLeadingViews(context: context)
    }

    func statusBarCenterViews(context: GitOKPluginContext) -> [AnyView] {
        guard hasPlugins else { return [] }
        return runtime.enabledStatusBarCenterViews(context: context)
    }

    func statusBarTrailingViews(context: GitOKPluginContext) -> [AnyView] {
        guard hasPlugins else { return [] }
        return runtime.enabledStatusBarTrailingViews(context: context)
    }

    func themeContributions() -> [GitOKUIThemeContribution] {
        getThemeContributions()
    }

    func rootViewWrapper(context: GitOKPluginContext, @ViewBuilder content: () -> some View) -> AnyView {
        getRootViewWrapper(context: context, content: content)
    }

    func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        guard hasPlugins else { return [] }
        return runtime.enabledSettingsPaneItems(context: context)
    }

    func sidebarPaneItems(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        guard hasPlugins else { return [] }
        return runtime.enabledSidebarPaneItems(context: context)
    }

    func onboardingView(kind: GitOKOnboardingKind, context: GitOKPluginContext) -> AnyView? {
        guard hasPlugins else { return nil }
        return runtime.enabledOnboardingView(kind: kind, context: context)
    }
}

extension PluginService: GitOKThemeContributionsProviding {}
