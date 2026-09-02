import LumiUI
import ProviderSettingView
import SwiftUI

/// 工具栏右上角的设置入口按钮。
///
/// 点击后发布 `SettingViewNavigation.openSettingsNotification`，
/// 由宿主监听该通知打开设置窗口（与 ⌘, 菜单项同一机制）。
/// 复刻旧版 `PluginSettingsButton`（原状态栏入口）到工具栏场景。
struct SettingsButtonView: View {
    var body: some View {
        AppIconButton(systemImage: "gearshape", size: .regular) {
            NotificationCenter.default.post(
                name: SettingViewNavigation.openSettingsNotification,
                object: nil
            )
        }
        .help("Open Settings")
    }
}
