import MagicKit
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
    @EnvironmentObject var pluginProvider: PluginVM

    /// 插件启用状态
    @State private var pluginStates: [String: Bool] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题
                Text(String(localized: "插件管理", table: "Core"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 16)

                Text(String(localized: "启用或禁用 GitOK 的插件功能", table: "Core"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)

                // 插件列表
                if configurablePlugins.isEmpty {
                    emptyView
                } else {
                    ForEach(configurablePlugins) { plugin in
                        PluginToggleRow(
                            plugin: plugin,
                            isEnabled: Binding(
                                get: { pluginStates[plugin.id, default: plugin.defaultEnabled] },
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
        .navigationTitle(Text(String(localized: "插件管理", table: "Core")))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }) {
                    Text(String(localized: "完成", table: "Core"))
                }
            }
        }
        .onAppear {
            loadPluginStates()
        }
    }

    /// 获取可配置的插件列表
    private var configurablePlugins: [PluginInfo] {
        pluginProvider.configurablePlugins
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "puzzlepiece")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(String(localized: "暂无可配置插件", table: "Core"))
                .font(.headline)

            Text(String(localized: "当前没有可以在设置中管理的插件", table: "Core"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// 加载插件状态
    private func loadPluginStates() {
        var states: [String: Bool] = [:]
        for plugin in configurablePlugins {
            // 检查用户配置，如果没有配置则使用插件的默认启用状态
            if settingsStore.hasUserConfigured(plugin.id) {
                states[plugin.id] = settingsStore.isPluginEnabled(plugin.id, defaultEnabled: plugin.defaultEnabled)
            } else {
                states[plugin.id] = plugin.defaultEnabled
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
