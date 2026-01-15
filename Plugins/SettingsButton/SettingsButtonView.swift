import AppKit
import MagicKit
import OSLog
import SwiftUI

/// 设置按钮视图：在状态栏右侧显示设置图标，点击打开设置界面
struct SettingsButtonView: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    /// emoji 标识符
    nonisolated static let emoji = "⚙️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    static let shared = SettingsButtonView()

    init() {}

    var body: some View {
        StatusBarTile(icon: "gearshape", onTap: {
            openSettings()
        })
        .help("打开设置 (⌘,)")
    }

    /// 打开设置界面
    private func openSettings() {
        if Self.verbose {
            os_log("\(Self.t)⚙️ Opening settings from status bar button")
        }
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
}

#Preview("SettingsButton") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}
