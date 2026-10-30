import Foundation

/// UI 测试专用的运行时钩子。
///
/// 这些钩子只在 DEBUG 构建、且显式设置了对应环境变量时生效；发布构建永远
/// 返回「不干预」，不会给真实用户带来任何开销。
///
/// 用途：在 UI 测试里稳定复现真实环境难以触发的中间态（例如工作区扫描
/// 尚未完成时的加载占位），而不是靠 sleep 碰运气。
enum UITestSupport {
    /// 工作区扫描的额外延迟（毫秒）。
    ///
    /// 通过 `GITOK_UI_TEST_WORKTREE_DELAY_MS` 注入。每个仓库只在第一次扫描
    /// 时延迟，避免预热插件轮询所有项目时把测试拖成长时间。
    static var worktreeScanDelayMilliseconds: Int {
        #if DEBUG
        guard let raw = ProcessInfo.processInfo.environment["GITOK_UI_TEST_WORKTREE_DELAY_MS"],
              let value = Int(raw),
              value > 0 else { return 0 }
        return value
        #else
        return 0
        #endif
    }
}
