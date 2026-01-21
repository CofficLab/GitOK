import MagicKit
import MagicUI
import SwiftUI

/// 状态栏视图
struct StatusBar: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "📊"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 插件提供者环境对象
    @EnvironmentObject var p: PluginProvider

    /// 视图主体
    var body: some View {
        HStack(spacing: 0) {
            // 状态栏左侧区域
            ForEach(p.plugins.filter { isPluginEnabled($0) }, id: \.instanceLabel) { plugin in
                plugin.addStatusBarLeadingView()
            }

            Spacer()

            // 状态栏中间区域
            ForEach(p.plugins.filter { isPluginEnabled($0) }, id: \.instanceLabel) { plugin in
                plugin.addStatusBarCenterView()
            }

            Spacer()

            // 状态栏右侧区域
            ForEach(p.plugins.filter { isPluginEnabled($0) }, id: \.instanceLabel) { plugin in
                plugin.addStatusBarTrailingView()
            }
        }
        .labelStyle(.iconOnly)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        #if DEBUG
        .background(Color.primary.opacity(0.4))
        #else
        .background(Color.accentColor.opacity(0.4))
        #endif
    }

    /// 检查插件是否被用户启用
    /// - Parameter plugin: 要检查的插件
    /// - Returns: 如果插件被启用则返回true
    private func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        let pluginType = type(of: plugin)

        // 如果不允许用户切换，则始终启用
        if !pluginType.allowUserToggle {
            return true
        }

        // 检查用户配置
        let pluginId = plugin.instanceLabel
        if PluginSettingsStore.shared.hasUserConfigured(pluginId) {
            return PluginSettingsStore.shared.isPluginEnabled(pluginId, defaultEnabled: true)
        }

        // 用户未配置过，默认启用
        return true
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
