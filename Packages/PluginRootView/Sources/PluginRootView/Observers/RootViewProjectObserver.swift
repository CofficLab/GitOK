import Foundation
import ProviderProjects

/// 根视图插件的项目观察者。
///
/// 遵循 Lumi 插件规范：插件入口在装配阶段创建并持有，`onShutdown` 取消。
/// Observer 只负责把 `ProjectProviding` 事件翻译成回调；View 本身不注册监听。
///
/// 监听的事件：
/// - `.projectsChanged`：项目列表增删（添加 / 移除）时触发，
///   用于判断是否需要显示 / 隐藏无项目引导视图。
@MainActor
final class RootViewProjectObserver {
    private var projectsHandle: (any ProjectProvidingObserverHandle)?

    init(
        projects: any ProjectProviding,
        onProjectsChanged: @escaping () -> Void
    ) {
        projectsHandle = projects.addObserver { event in
            switch event {
            case .projectsChanged:
                onProjectsChanged()
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
