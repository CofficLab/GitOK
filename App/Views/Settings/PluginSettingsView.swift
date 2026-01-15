import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 插件设置视图：控制各个插件的启用/禁用状态
struct PluginSettingsView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🔌"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 插件设置存储
    private let settingsStore = PluginSettingsStore.shared

    /// 插件启用状态
    @State private var pluginStates: [String: Bool] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            Text("插件管理")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 16)

            Text("启用或禁用 GitOK 的插件功能")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)

            // 插件列表
            ForEach(ConfigurablePlugins.allPlugins) { plugin in
                PluginToggleRow(
                    plugin: plugin,
                    isEnabled: Binding(
                        get: { pluginStates[plugin.id, default: true] },
                        set: { newValue in
                            pluginStates[plugin.id] = newValue
                            settingsStore.setPluginEnabled(plugin.id, enabled: newValue)

                            if Self.verbose {
                                os_log("\(Self.t)🔌 Plugin '\(plugin.id)' is now \(newValue ? "enabled" : "disabled")")
                            }
                        }
                    )
                )

                if plugin.id != ConfigurablePlugins.allPlugins.last?.id {
                    Divider()
                        .padding(.leading, 16)
                }
            }

            Spacer()

            // 提示信息
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("提示")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                Text("禁用的插件将不会在界面中显示，也不会加载相关功能。部分插件可能需要重启应用才能完全生效。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
        }
        .padding(24)
        .onAppear {
            loadPluginStates()
        }
    }

    /// 加载插件状态
    private func loadPluginStates() {
        var states: [String: Bool] = [:]
        for plugin in ConfigurablePlugins.allPlugins {
            states[plugin.id] = settingsStore.isPluginEnabled(plugin.id)
        }
        pluginStates = states
    }
}

/// 插件开关行视图
struct PluginToggleRow: View {
    let plugin: PluginInfo
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: plugin.icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text(plugin.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 开关
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Plugin Settings") {
    PluginSettingsView()
        .frame(width: 600, height: 500)
}

#Preview("Plugin Settings in Settings View") {
    SettingView(defaultTab: .plugins)
        .inRootView()
        .frame(width: 800, height: 600)
}
