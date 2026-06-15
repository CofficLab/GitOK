import AppKit
import GitOKAppCore
import GitOKSupportKit
import SwiftUI

/// 在应用菜单中添加入口
struct AppCommand: Commands, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false
    var body: some Commands {
        #if os(macOS)
        CommandGroup(after: .appInfo) {
            Button(String(localized: "Check for Updates...")) {
                UpdateManager.shared.checkForUpdates()
            }
        }
        #endif
    }
}
