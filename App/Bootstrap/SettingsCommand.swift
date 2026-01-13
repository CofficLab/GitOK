import SwiftUI
import AppKit

/// 设置命令：在应用菜单中添加设置入口
struct SettingsCommand: Commands {
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
