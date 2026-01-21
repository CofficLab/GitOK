import MagicKit
import OSLog
import SwiftUI

class ProjectPickerPlugin: NSObject, SuperPlugin, SuperLog {
    /// 插件显示名称
    static var displayName: String = "ProjectPicker"

    /// 插件描述
    static var description: String = "项目选择器"

    /// 插件图标名称
    static var iconName: String = "folder"

    /// 插件是否可配置（是否在设置中由用户控制启用/停用）
    static var isConfigurable: Bool = false

    ///  插件默认启用状态
    static var defaultEnabled: Bool = false

    /// 日志标识符
    nonisolated static let emoji = "📁"

    /// 是否启用该插件
    @objc static let enable = true

    /// 是否启用详细日志输出
    nonisolated static let verbose = true

    @objc static let shared = ProjectPickerPlugin()

    override private init() {
    }

    func addToolBarLeadingView() -> AnyView? {
        return AnyView(ProjectPickerView.shared)
    }
}

// MARK: - Previews

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
