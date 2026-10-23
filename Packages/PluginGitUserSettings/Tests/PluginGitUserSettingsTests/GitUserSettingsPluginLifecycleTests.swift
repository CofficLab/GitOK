import Foundation
import KernelCore
import KitGit
import ProviderGitUser
import ProviderProjects
import ProviderSettingView
import ProviderStorage
import ProviderToast
import SwiftUI
import Testing
@testable import PluginGitUserSettings

/// 覆盖 `GitUserSettingsPlugin` 的依赖守卫链、默认 Provider 兜底注册与撤回，
/// 以及设置入口的注入 / 移除。
@MainActor
@Suite("PluginGitUserSettings 生命周期")
struct GitUserSettingsPluginLifecycleTests {

    // MARK: - Helpers

    private struct Harness {
        let kernel: KernelCoreContainer
        let settings: DefaultSettingViewProviding
        let storage: GitUserSettingsTestsStorage
        let root: URL
    }

    /// 只实现 `pluginDataDirectory` 的最小存储 Provider。
    final class GitUserSettingsTestsStorage: StorageProviding {
        let dataRootDirectory: URL

        init(dataRootDirectory: URL) {
            self.dataRootDirectory = dataRootDirectory
        }

        func pluginDataDirectory(for pluginID: String) -> URL {
            dataRootDirectory.appendingPathComponent(pluginID, isDirectory: true)
        }

        func coreDataDirectory() -> URL {
            dataRootDirectory.appendingPathComponent("CoreData", isDirectory: true)
        }
    }

    private func makeKernel(
        withSettings: Bool = true,
        withProjects: Bool = true,
        withStorage: Bool = true,
        withPresetProvider: Bool = false,
        withCollaboratorProvider: Bool = false
    ) throws -> Harness {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKUserSettingsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        let storage = GitUserSettingsTestsStorage(dataRootDirectory: root)

        if withSettings {
            try kernel.registerProvider((any SettingViewProviding).self, settings)
        }
        if withProjects {
            try kernel.registerProvider((any ProjectProviding).self, GitUserSettingsTestsProjects())
        }
        if withStorage {
            try kernel.registerProvider((any StorageProviding).self, storage)
        }
        if withPresetProvider {
            try kernel.registerProvider(
                (any GitUserPresetProviding).self,
                DefaultGitUserPresetProvider(directory: root.appendingPathComponent("host-presets"))
            )
        }
        if withCollaboratorProvider {
            try kernel.registerProvider(
                (any CollaboratorProviding).self,
                DefaultCollaboratorProvider(directory: root.appendingPathComponent("host-collaborators"))
            )
        }

        return Harness(kernel: kernel, settings: settings, storage: storage, root: root)
    }

    private func cleanUp(_ harness: Harness) {
        try? FileManager.default.removeItem(at: harness.root)
    }

    // MARK: - 守卫链

    @Test("缺少 SettingViewProviding 时不注入设置入口")
    func onBootWithoutSettingsInjectsNothing() throws {
        let harness = try makeKernel(withSettings: false)
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any SettingViewProviding).self) == nil)
    }

    @Test("缺少 ProjectProviding 时不注入设置入口")
    func onBootWithoutProjectsInjectsNothing() throws {
        let harness = try makeKernel(withProjects: false)
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.settings.entries.isEmpty)
    }

    // MARK: - 设置入口

    @Test("依赖齐备时注入 User Info 设置入口")
    func onBootInjectsUserInfoEntry() throws {
        let harness = try makeKernel()
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.settings.entries.map(\.id) == ["userInfo"])
        #expect(harness.settings.entries.first?.systemImage == "person.circle")
        #expect(harness.settings.entries.first?.order == 20)
    }

    @Test("onShutdown 移除设置入口")
    func onShutdownRemovesSettingEntry() throws {
        let harness = try makeKernel()
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        #expect(harness.settings.entries.count == 1)

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.settings.entries.isEmpty)
    }

    @Test("onShutdown 保留其它插件注入的设置入口")
    func onShutdownKeepsForeignEntries() throws {
        let harness = try makeKernel()
        defer { cleanUp(harness) }
        harness.settings.registerEntries([
            SettingEntryItem(id: "other", title: "Other", systemImage: "gear") { EmptyView() },
        ])

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.settings.entries.map(\.id) == ["other"])
    }

    // MARK: - 默认 Provider 兜底

    @Test("宿主未注册时插件兜底注册预设与协作者 Provider")
    func onBootRegistersFallbackProviders() throws {
        let harness = try makeKernel()
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.isProviderRegistered((any GitUserPresetProviding).self))
        #expect(harness.kernel.isProviderRegistered((any CollaboratorProviding).self))
    }

    @Test("宿主已注册时插件复用宿主 Provider")
    func onBootReusesHostProviders() throws {
        let harness = try makeKernel(withPresetProvider: true, withCollaboratorProvider: true)
        defer { cleanUp(harness) }

        let hostPreset = harness.kernel.resolveProvider((any GitUserPresetProviding).self)
        let hostCollaborator = harness.kernel.resolveProvider((any CollaboratorProviding).self)

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any GitUserPresetProviding).self) === hostPreset)
        #expect(harness.kernel.resolveProvider((any CollaboratorProviding).self) === hostCollaborator)
    }

    @Test("onShutdown 撤回插件自己注册的默认 Provider")
    func onShutdownUnregistersFallbackProviders() throws {
        let harness = try makeKernel()
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        #expect(harness.kernel.isProviderRegistered((any GitUserPresetProviding).self))

        try plugin.onShutdown(kernel: harness.kernel)

        #expect(!harness.kernel.isProviderRegistered((any GitUserPresetProviding).self))
        #expect(!harness.kernel.isProviderRegistered((any CollaboratorProviding).self))
    }

    @Test("onShutdown 不撤回宿主自己注册的 Provider")
    func onShutdownKeepsHostProviders() throws {
        let harness = try makeKernel(withPresetProvider: true, withCollaboratorProvider: true)
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.kernel.isProviderRegistered((any GitUserPresetProviding).self))
        #expect(harness.kernel.isProviderRegistered((any CollaboratorProviding).self))
    }

    @Test("缺少 StorageProviding 时使用兜底目录仍能注册默认 Provider")
    func onBootWithoutStorageStillRegistersFallbackProviders() throws {
        let harness = try makeKernel(withStorage: false)
        defer { cleanUp(harness) }

        let plugin = GitUserSettingsPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.isProviderRegistered((any GitUserPresetProviding).self))
        #expect(harness.kernel.isProviderRegistered((any CollaboratorProviding).self))

        try plugin.onShutdown(kernel: harness.kernel)
    }
}

// MARK: - Test Doubles

/// `ProjectProviding` 的最小替身：生命周期测试只关心依赖是否可解析。
@MainActor
final class GitUserSettingsTestsProjects: ProjectProviding {
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
        GitUserSettingsTestsProjectHandle()
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
final class GitUserSettingsTestsProjectHandle: ProjectProvidingObserverHandle {
    func cancel() {}
}
