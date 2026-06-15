import GitOKCoreKit
import GitOKUI
import SwiftUI

public enum UpdatePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "UpdatePlugin",
        displayName: "应用更新",
        description: "检查和安装应用更新（由 Sparkle 驱动）",
        iconName: "arrow.triangle.2.circlepath",
        order: 10,
        policy: .alwaysOn,
        tableName: "Localizable"
    )

    // 设置面板：更新选项
    @MainActor
    public static func settingsPaneItems(context: GitOKPluginContext) -> [GitOKSettingsPaneItem] {
        [
            GitOKSettingsPaneItem(
                id: "update",
                title: "更新",
                systemImage: "arrow.triangle.2.circlepath",
                order: 10,
                view: AnyView(UpdateSettingsView())
            )
        ]
    }
}
