import Foundation
import ProviderCloneRepository
import ProviderProjects

/// 根视图插件的项目观察者。
///
/// 遵循 Lumi 插件规范：插件入口在装配阶段创建并持有，`onShutdown` 取消。
/// Observer 只依赖插件自己的窄能力，把项目与克隆事件翻译成回调；
/// View 本身不注册监听，也不直接接触任何 Provider。
///
/// 监听项目列表和当前项目变化，用于在根布局挂载业务工作区之前判断
/// 当前项目是否可用。
@MainActor
final class RootViewProjectObserver {
    private var projectsHandle: (any ProjectProvidingObserverHandle)?
    private var cloneRepositoryHandle: (any CloneRepositoryObserverHandle)?

    init(
        projects: any RootViewProjectCapability,
        cloneRepository: RootViewCloneCapability,
        onWorkspaceChanged: @escaping () -> Void
    ) {
        projectsHandle = projects.addObserver { event in
            switch event {
            case .projectsChanged, .selectionChanged, .dataChanged:
                onWorkspaceChanged()
            default:
                break
            }
        }
        cloneRepositoryHandle = cloneRepository.addObserver { event in
            switch event {
            case .tasksChanged, .taskUpdated:
                onWorkspaceChanged()
            }
        }
    }

    /// 取消全部订阅；插件卸载后不再有任何回调。
    func cancel() {
        projectsHandle?.cancel()
        projectsHandle = nil
        cloneRepositoryHandle?.cancel()
        cloneRepositoryHandle = nil
    }
}