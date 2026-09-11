import Foundation
import ProviderGitUser
import ProviderGitRepositoryWatch
import ProviderProjects

/// 工作区干净视图插件的插件级外部观察者。
///
/// 遵循 Lumi 插件规范：插件入口在装配阶段创建本 Observer 并持有，
/// 直到 `onShutdown` 取消。Observer 只负责把外部事件翻译成 ViewModel 的
/// 领域回调；View 与 ViewModel 本身不注册任何插件级外部监听。
///
/// 外部输入均为类型化通道，全部来自 `ProjectProviding` 与 `GitRepositoryWatching`：
/// - `.selectionChanged` / `.commitSelectionChanged`：项目或 commit 选择变化
///   （干净视图只在「有项目 + 未选中 commit」时展示）；
/// - `.dataChanged`：提交 / 推送 / 分支切换后仓库数据变化（工作区可能由脏变干净）；
/// - `.workingTreeChanged`：工作区文件变化（外部编辑 / 新增 / 删除文件）。
@MainActor
final class WorktreeCleanObserver {
    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var gitWatchHandle: (any GitRepositoryWatchingObserverHandle)?
    private var userPresetsHandle: (any GitUserPresetProvidingObserverHandle)?
    private var collaboratorsHandle: (any CollaboratorProvidingObserverHandle)?

    init(
        capability: any WorktreeCleanProjectCapability,
        gitWatch: (any GitRepositoryWatching)?,
        userPresets: (any GitUserPresetProviding)?,
        collaborators: (any CollaboratorProviding)?,
        onProjectChanged: @escaping () -> Void,
        onDataChanged: @escaping () -> Void,
        onUserPresetsChanged: @escaping ([GitUserPreset]) -> Void,
        onCollaboratorsChanged: @escaping ([Collaborator]) -> Void
    ) {
        projectsHandle = capability.addObserver { event in
            switch event {
            case .selectionChanged, .commitSelectionChanged:
                onProjectChanged()
            case .dataChanged:
                onDataChanged()
            default:
                break
            }
        }

        gitWatchHandle = gitWatch?.addObserver { event in
            switch event {
            case .headChanged, .indexChanged, .refsChanged, .workingTreeChanged:
                // 外部提交可能只产生 .git/HEAD/index 事件，仍需重新判断
                // 工作区是否已经从 dirty 变为 clean。
                onDataChanged()
            default:
                break
            }
        }

        if let userPresets {
            onUserPresetsChanged(userPresets.loadPresets())
            userPresetsHandle = userPresets.addObserver { event in
                switch event {
                case .presetsChanged:
                    onUserPresetsChanged(userPresets.loadPresets())
                }
            }
        } else {
            onUserPresetsChanged([])
        }

        if let collaborators {
            onCollaboratorsChanged(collaborators.loadCollaborators())
            collaboratorsHandle = collaborators.addObserver { event in
                switch event {
                case .collaboratorsChanged:
                    onCollaboratorsChanged(collaborators.loadCollaborators())
                }
            }
        } else {
            onCollaboratorsChanged([])
        }
    }

    @available(*, deprecated, message: "Inject WorktreeCleanProjectCapability from WorktreeCleanPlugin")
    convenience init(
        projects: any ProjectProviding,
        gitWatch: (any GitRepositoryWatching)?,
        onProjectChanged: @escaping () -> Void,
        onDataChanged: @escaping () -> Void
    ) {
        self.init(
            capability: WorktreeCleanProjectCapabilityAdapter(projects: projects),
            gitWatch: gitWatch,
            userPresets: nil,
            collaborators: nil,
            onProjectChanged: onProjectChanged,
            onDataChanged: onDataChanged,
            onUserPresetsChanged: { _ in },
            onCollaboratorsChanged: { _ in }
        )
    }

    /// 取消全部订阅；插件卸载后不再有任何回调。
    func cancel() {
        projectsHandle?.cancel()
        projectsHandle = nil
        gitWatchHandle?.cancel()
        gitWatchHandle = nil
        userPresetsHandle?.cancel()
        userPresetsHandle = nil
        collaboratorsHandle?.cancel()
        collaboratorsHandle = nil
    }
}
