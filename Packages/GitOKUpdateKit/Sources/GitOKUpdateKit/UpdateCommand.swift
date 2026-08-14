import AppKit
import SwiftUI

/// 在应用菜单中添加「检查更新」入口（Sparkle 渠道专属命令）。
public struct UpdateCommand: Commands {
    public init() {}

    public var body: some Commands {
        #if os(macOS)
        CommandGroup(after: .appInfo) {
            Button(String(localized: "Check for Updates...")) {
                UpdateManager.shared.checkForUpdates()
            }
        }
        #endif
    }
}
