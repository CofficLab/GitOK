import Foundation
import ProviderProjects

/// 根视图插件的项目观察者。
///
/// 遵循 Lumi 插件规范：插件入口在装配阶段创建并持有，`onShutdown` 取消。
/// Observer 只负责把 `ProjectProviding` 事件翻译成回调；View 本身不注册监听。
///
/// 监听项目列表和当前项目变化，用于在根布局挂载业务工作区之前判断
/// 当前项目是否可用。
@MainActor
final class RootViewProjectObserver {
    private var projectsHandle: (any ProjectProvidingObserverHandle)?

    init(
        projects: any ProjectProviding,
        onWorkspaceChanged: @escaping () -> Void
    ) {
        projectsHandle = projects.addObserver { event in
            switch event {
            case .projectsChanged, .selectionChanged:
                onWorkspaceChanged()
            default:
                break
            }
        }
    }

    /// 取消全部订阅；插件卸载后不再有任何回调。
    func cancel() {
        projectsHandle?.cancel()
        projectsHandle = nil
    }
}
