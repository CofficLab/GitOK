import Foundation
import GitOKCoreKit
import GitOKUI
import SwiftUI

public enum UpdatePlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "UpdatePlugin",
        displayName: "应用更新",
        description: "检查和安装应用更新",
        iconName: "arrow.triangle.2.circlepath",
        order: 10,
        policy: .alwaysOn,  // 强制启用（核心功能）
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

    // 状态栏：更新状态指示器
    @MainActor
    public static func statusBarTrailingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        [
            GitOKStatusBarItem(
                id: "updateStatus",
                view: AnyView(UpdateStatusView())
            )
        ]
    }
}

public enum UpdatePluginLocalization {
    public static let table = "Localizable"

    public static func string(_ key: String) -> String {
        // 直接使用 String(localized:) 而不指定 bundle
        String(localized: String.LocalizationValue(key))
    }
}