import GitOKAppCore
import GitOKCoreKit
import GitOKSupportKit
import OSLog
import SwiftUI

/// 插件设置视图：控制各个插件的启用/禁用状态
struct PluginSettingsView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🔌"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 插件提供者
    @EnvironmentObject var pluginProvider: PluginService

    /// 插件启用状态
    @State private var pluginStates: [String: Bool] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题
                Text(String(localized: "Plugin Management"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 16)

                Text(String(localized: "GitOK plugins are always enabled"))
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
                                    PluginSettingsStore.shared.setPluginEnabled(plugin.id, enabled: newValue)

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
        .navigationTitle(Text(String(localized: "Plugin Management")))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(String(localized: "Done"), style: .secondary, size: .small) {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
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
        AppEmptyState(
            icon: "puzzlepiece",
            title: String(localized: "No Configurable Plugins"),
            description: String(localized: "No plugins available to manage in settings")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// 加载插件状态
    private func loadPluginStates() {
        guard configurablePlugins.isEmpty == false else {
            pluginStates = [:]
            return
        }

        let settingsStore = PluginSettingsStore.shared
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
        AppToggleRow(
            title: plugin.name,
            systemImage: plugin.icon,
            description: plugin.description,
            isOn: $isEnabled
        )
    }
}

// MARK: - Preview

#Preview("Plugin Settings") {
    PluginSettingsView()
        .frame(width: 600, height: 500)
}

#Preview("Plugin Settings in Settings View") {
    SettingView(defaultTabID: "plugins")
        .inRootView()
        .frame(width: 800, height: 600)
}
