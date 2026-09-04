import Foundation
import ProviderProjects

/// Git Diff 插件的插件级外部观察者。
///
/// 遵循 Lumi 插件规范（`docs/plans/2026-09-03-plugin-observer-only.md`）：
/// 插件入口在装配阶段创建本 Observer 并持有，直到 `onShutdown` 取消。
/// Observer 只负责把外部事件翻译成插件 ViewModel 的领域回调；View 与
/// ViewModel 本身不注册任何插件级外部监听。
///
/// 外部输入均为类型化通道，全部来自 `ProjectProviding`：
/// - `.commitSelectionChanged` / `.currentFileChanged`：当前 commit / 文件变化
///   （切换项目时会联动清空选择并广播 commit 事件）；
/// - `.dataChanged`：提交 / 推送 / 分支切换后仓库数据变化（视图据此重载）。
@MainActor
final class GitDiffObserver {
    private var projectsHandle: (any ProjectProvidingObserverHandle)?

    init(
        projects: any ProjectProviding,
        onSelectionChanged: @escaping () -> Void,
        onProjectDataChanged: @escaping () -> Void
    ) {
        projectsHandle = projects.addObserver { event in
            switch event {
            case .commitSelectionChanged, .currentFileChanged:
                onSelectionChanged()
            case .dataChanged:
                onProjectDataChanged()
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
