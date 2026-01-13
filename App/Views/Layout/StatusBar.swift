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
            ForEach(p.plugins, id: \.instanceLabel) { plugin in
                plugin.addStatusBarLeadingView()
            }

            Spacer()

            // 状态栏中间区域
            ForEach(p.plugins, id: \.instanceLabel) { plugin in
                plugin.addStatusBarCenterView()
            }

            Spacer()

            // 状态栏右侧区域
            ForEach(p.plugins, id: \.instanceLabel) { plugin in
                plugin.addStatusBarTrailingView()
            }
        }
        .labelStyle(.iconOnly)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        #if DEBUG
        .background(MagicBackground.desert.opacity(0.3))
        #else
        .background(MagicBackground.colorGreen.opacity(0.3))
        #endif
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
