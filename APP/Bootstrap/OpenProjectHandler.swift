import Foundation
import MagicKit
import OSLog

/// 打开项目请求处理器（单例）
/// 作为 MacAgent 和 RootView 之间的桥梁
///
/// MacAgent 通过 `requestOpen(path:)` 发起请求，
/// RootView 通过 `onOpenProject` 回调接收并处理。
final class OpenProjectHandler: SuperLog {
    nonisolated static let emoji = "📂"
    static let shared = OpenProjectHandler()

    /// 处理打开项目的回调
    var onOpenProject: ((String) -> Void)?

    private init() {}

    /// 请求打开指定路径的项目
    /// - Parameter path: 项目路径
    func requestOpen(path: String) {
        os_log("\(Self.t)📋 Request open project: \(path)")
        onOpenProject?(path)
    }
}
