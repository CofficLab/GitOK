import Foundation
import ProviderProjects

/// 项目缺失视图的自有状态模型。
///
/// 由插件入口在装配阶段创建并注入视图；`ProjectMissingObserver` 把外部
/// （Provider）事件翻译成本模型的领域方法。视图只绑定本模型，不再直接
/// 读取 Provider 或监听系统通知。
@MainActor
final class ProjectMissingViewModel: ObservableObject {
    /// 当前项目；未打开项目时为 nil。
    @Published private(set) var project: Project?

    /// 当前项目是否在磁盘上缺失（目录不存在）。
    @Published private(set) var isMissing = false

    /// 外部项目变化（打开 / 切换 / 关闭项目）。
    ///
    /// 缺失视图只在「有项目 + 项目目录不存在」时展示。
    func handleProjectChanged(project: Project?) {
        self.project = project
        updateMissingState()
    }

    /// 重新检查当前项目是否在磁盘上缺失。
    private func updateMissingState() {
        guard let project else {
            isMissing = false
            return
        }
        isMissing = !FileManager.default.fileExists(atPath: project.url.path)
    }
}
