import Foundation
import KernelCore
import KitGit
import ProviderDocsView
import ProviderProjects
import ProviderStatusBar
import ProviderTheme
import SwiftUI
import Testing
@testable import PluginStatusBar

/// 覆盖 `StatusBarPlugin` 的完整生命周期：
/// - 关于页条目的注册与撤回；
/// - `onBoot` 按依赖可用性注入 leading / trailing 状态栏项；
/// - `onShutdown` 只撤回自身贡献。
@MainActor
@Suite("PluginStatusBar 生命周期")
struct StatusBarPluginLifecycleTests {

    // MARK: - 关于页贡献

    @Test("onRegister 注册关于页条目")
    func onRegisterAddsAboutEntry() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)

        let plugin = StatusBarPlugin()
        try plugin.onRegister(kernel: kernel)

        #expect(docs.aboutEntries.map(\.id) == [plugin.id])
        #expect(docs.aboutEntries.first?.name == plugin.metadata.name)
    }

    @Test("onUnregister 撤回关于页条目")
    func onUnregisterRemovesAboutEntry() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)

        let plugin = StatusBarPlugin()
        try plugin.onRegister(kernel: kernel)
        #expect(docs.aboutEntries.count == 1)

        try plugin.onUnregister(kernel: kernel)

        #expect(docs.aboutEntries.isEmpty)
    }

    @Test("缺少 DocsViewProviding 时生命周期不抛异常")
    func lifecycleDegradesWithoutDocsProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = StatusBarPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - 状态栏项注入

    @Test("项目与主题 Provider 都可用时注入 leading 与 trailing 两项")
    func onBootInjectsBothItemsWhenAllDependenciesExist() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StatusBarPluginTestsProjects())
        try kernel.registerProvider((any ThemeProviding).self, StatusBarPluginTestsTheme())

        let plugin = StatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 2)

        let project = statusBar.statusBarItems.first { $0.id == "\(StatusBarPlugin.itemPrefix).project" }
        let theme = statusBar.statusBarItems.first { $0.id == "\(StatusBarPlugin.itemPrefix).theme" }
        #expect(project?.placement == .leading)
        #expect(project?.order == 10)
        #expect(theme?.placement == .trailing)
        #expect(theme?.order == 10)
    }

    @Test("只有项目 Provider 时仅注入 leading 项")
    func onBootInjectsOnlyLeadingItemWithoutTheme() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StatusBarPluginTestsProjects())

        let plugin = StatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.map(\.id) == ["\(StatusBarPlugin.itemPrefix).project"])
        #expect(statusBar.statusBarItems[0].placement == .leading)
    }

    @Test("只有主题 Provider 时仅注入 trailing 项")
    func onBootInjectsOnlyTrailingItemWithoutProjects() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ThemeProviding).self, StatusBarPluginTestsTheme())

        let plugin = StatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.map(\.id) == ["\(StatusBarPlugin.itemPrefix).theme"])
        #expect(statusBar.statusBarItems[0].placement == .trailing)
    }

    @Test("缺少状态栏 Provider 时 onBoot 优雅降级")
    func onBootDegradesWithoutStatusBarProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = StatusBarPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(kernel.resolveProvider((any StatusBarProviding).self) == nil)
    }

    @Test("缺少全部可选依赖时状态栏保持为空")
    func onBootWithoutOptionalDependenciesInjectsNothing() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)

        let plugin = StatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    // MARK: - 撤回

    @Test("onShutdown 撤回自身注入的状态栏项")
    func onShutdownRemovesOwnItems() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StatusBarPluginTestsProjects())
        try kernel.registerProvider((any ThemeProviding).self, StatusBarPluginTestsTheme())

        let plugin = StatusBarPlugin()
        try plugin.onBoot(kernel: kernel)
        #expect(statusBar.statusBarItems.count == 2)

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("onShutdown 保留其它插件注入的状态栏项")
    func onShutdownKeepsForeignItems() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ProjectProviding).self, StatusBarPluginTestsProjects())
        try kernel.registerProvider((any ThemeProviding).self, StatusBarPluginTestsTheme())
        statusBar.addStatusBarItems([
            StatusBarItem(id: "com.example.other", title: "Other", placement: .center) { EmptyView() },
        ])

        let plugin = StatusBarPlugin()
        try plugin.onBoot(kernel: kernel)
        #expect(statusBar.statusBarItems.count == 3)

        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.map(\.id) == ["com.example.other"])
    }

    @Test("缺少状态栏 Provider 时 onShutdown 不抛异常")
    func onShutdownDegradesWithoutStatusBarProvider() throws {
        let kernel = KernelCoreContainer()
        let plugin = StatusBarPlugin()

        try plugin.onShutdown(kernel: kernel)
    }
}

// MARK: - Test Doubles

/// `ProjectProviding` 的最小替身：生命周期测试只关心依赖是否可解析。
@MainActor
final class StatusBarPluginTestsProjects: ProjectProviding {
    var projects: [Project] = []
    var currentProject: Project?
    var currentCommit: GitCommit?
    var currentFile: String?
    var currentCommitFiles: [GitFileChange]?
    var isLoadingCommitFiles = false
    var currentCommitFilesLoadError: String?

    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        StatusBarPluginTestsProjectHandle()
    }

    func openProject(at url: URL) {}
    func closeCurrentProject() {}
    func addProject(at url: URL) {}
    func removeProject(id: UUID) {}
    func renameProject(id: UUID, newName: String) throws {}
    func pinProject(id: UUID, isPinned: Bool) {}
    func moveProject(id: UUID, beforeID: UUID?) {}
    func selectCommit(_ commit: GitCommit) {}
    func selectFile(_ file: String?) {}
    func clearCommitSelection() {}
    func setCurrentProject(id: UUID?) {}
    func refresh() {}
    func notifyDataChanged() {}
    func persist() {}
}

@MainActor
final class StatusBarPluginTestsProjectHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}

/// `ThemeProviding` 的最小替身。
@MainActor
final class StatusBarPluginTestsTheme: ThemeProviding {
    var themes: [LumiTheme] = []
    var selectedThemeId: String?
    var selectedTheme: LumiTheme?

    func addObserver(
        _ callback: @escaping (ThemeProvidingEvent) -> Void
    ) -> any ThemeProvidingObserverHandle {
        StatusBarPluginTestsThemeHandle()
    }

    func selectTheme(id: String) throws {}
    func registerTheme(_ theme: LumiTheme) {}
    func unregisterTheme(id: String) {}
    func replaceAllThemes(_ themes: [LumiTheme]) throws {}
}

@MainActor
final class StatusBarPluginTestsThemeHandle: ThemeProvidingObserverHandle {
    func cancel() {}
}
