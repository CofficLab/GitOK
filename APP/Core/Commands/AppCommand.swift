import SwiftUI
import MagicKit
import AppKit

/// 在应用菜单中添加入口
struct AppCommand: Commands, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false
    var body: some Commands {
        #if os(macOS)
        CommandGroup(after: .appInfo) {
            Button("设置...") {
                // 发送打开设置的通知
                NotificationCenter.default.post(name: .openSettings, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        #endif
    }
}
