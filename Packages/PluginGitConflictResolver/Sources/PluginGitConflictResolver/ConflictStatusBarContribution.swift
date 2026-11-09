import Combine
import ProviderProjects
import ProviderStatusBar
import ProviderWorkspaceScene
import SwiftUI

/// 冲突解决状态栏项的动态贡献。
///
/// `StatusBarProviding` 只在插件真的没有贡献项时隐藏整条状态栏；有贡献但
/// 内容为空时由插件自行撤回。冲突项只有在「Git 场景 + 已选项目 + 有进行中
/// 的合并 / cherry-pick」时才有可渲染内容，因此这里按同一条件增删该项，
/// 避免贡献仍存在、渲染却为空时留下一条空状态栏。
@MainActor
final class ConflictStatusBarContribution {
    private let statusBar: any StatusBarProviding
    private let projects: any ProjectProviding
    private let conflictViewModel: GitConflictResolverViewModel
    private let sceneViewModel: WorkspaceSceneVisibilityViewModel
    private var cancellables = Set<AnyCancellable>()
    private var isRegistered = false
    private var isCancelled = false

    init(
        statusBar: any StatusBarProviding,
        projects: any ProjectProviding,
        conflictViewModel: GitConflictResolverViewModel,
        sceneViewModel: WorkspaceSceneVisibilityViewModel
    ) {
        self.statusBar = statusBar
        self.projects = projects
        self.conflictViewModel = conflictViewModel
        self.sceneViewModel = sceneViewModel

        // objectWillChange 在属性更新前发出，下一个主线程任务里再读取
        // 已经落定的最新状态。
        Publishers.Merge(
            conflictViewModel.objectWillChange,
            sceneViewModel.objectWillChange
        )
        .sink { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sync()
            }
        }
        .store(in: &cancellables)

        sync()
    }

    func cancel() {
        isCancelled = true
        cancellables.removeAll()
        removeItem()
    }

    private func sync() {
        guard !isCancelled else { return }
        let shouldShow = sceneViewModel.isActive
            && conflictViewModel.currentProjectURL != nil
            && conflictViewModel.isOperationInProgress
        guard shouldShow != isRegistered else { return }

        guard shouldShow else {
            removeItem()
            return
        }
        isRegistered = true

        // 只捕获视图需要的模型，避免状态栏条目反向持有本协调器。
        let projects = self.projects
        let conflictViewModel = self.conflictViewModel
        let sceneViewModel = self.sceneViewModel
        statusBar.addStatusBarItems([
            StatusBarItem(
                id: GitConflictResolverPlugin.itemID,
                title: pluginLocalization.string("Conflict Resolver"),
                placement: .leading,
                order: 18
            ) {
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    ConflictStatusTile(projects: projects, viewModel: conflictViewModel)
                }
            },
        ])
    }

    private func removeItem() {
        guard isRegistered else { return }
        isRegistered = false
        statusBar.removeStatusBarItems(ids: [GitConflictResolverPlugin.itemID])
    }
}
