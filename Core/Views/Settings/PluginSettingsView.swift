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

    /// 插件提供者
    @EnvironmentObject var pluginProvider: PluginProvider

    /// 插件启用状态
    @State private var pluginStates: [String: Bool] = [:]

    var body: some View {
        ScrollView {
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
                if configurablePlugins.isEmpty {
                    // 空状态提示
                    VStack(spacing: 16) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("暂无可配置插件")
                            .font(.title3)
                            .fontWeight(.medium)

                        Text("当前没有可以在设置中管理的插件")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(configurablePlugins) { plugin in
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

                        if plugin.id != configurablePlugins.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("插件管理")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Text("重启应用才能完全生效。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
        .onAppear {
            loadPluginStates()
        }
    }

    /// 获取可配置的插件列表（从自动发现的插件中提取）
    private var configurablePlugins: [PluginInfo] {
        pluginProvider.plugins
            .filter { type(of: $0).allowUserToggle }
            .map { plugin in
                let pluginType = type(of: plugin)
                // 使用反射获取插件类型名称作为 ID
                let typeName = String(describing: pluginType)
                let pluginId = typeName.contains(".") ? typeName.components(separatedBy: ".").last ?? typeName : typeName
                return PluginInfo(
                    id: pluginId,
                    name: pluginType.displayName,
                    description: pluginType.description,
                    icon: pluginType.iconName,
                    isDeveloperEnabled: { true }
                )
            }
    }

    /// 加载插件状态
    private func loadPluginStates() {
        var states: [String: Bool] = [:]
        for plugin in configurablePlugins {
            // 检查用户配置，如果没有配置则默认为启用
            if settingsStore.hasUserConfigured(plugin.id) {
                states[plugin.id] = settingsStore.isPluginEnabled(plugin.id, defaultEnabled: true)
            } else {
                states[plugin.id] = true
            }
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
