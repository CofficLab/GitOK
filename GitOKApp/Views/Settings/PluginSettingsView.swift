import GitOKAppCore
import GitOKCoreKit
import GitOKSupportKit
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
    @State private var selectedPluginID: String?
    @State private var searchText: String = ""

    var body: some View {
        HSplitView {
            leftPane
                .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
            rightPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(Text(String(localized: "Plugin Management")))
        .onAppear {
            loadPluginStates()
            if selectedPlugin == nil {
                selectedPluginID = filteredPlugins.first?.id ?? allManagedPlugins.first?.id
            }
        }
        .onChange(of: filteredPlugins.map(\.id)) { _, ids in
            guard let selectedPluginID else {
                self.selectedPluginID = ids.first
                return
            }
            if ids.contains(selectedPluginID) == false {
                self.selectedPluginID = ids.first
            }
        }
    }

    private var leftPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(String(localized: "Search Plugins"), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()

            if filteredPlugins.isEmpty {
                emptyView
            } else {
                List(filteredPlugins, id: \.id, selection: $selectedPluginID) { plugin in
                    pluginListRow(plugin)
                        .tag(plugin.id)
                }
                .listStyle(.inset)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var rightPane: some View {
        Group {
            if let plugin = selectedPlugin {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        pluginHeader(plugin)
                        if let introduction = pluginProvider.pluginIntroductionView(
                            pluginID: plugin.id,
                            context: pluginProvider.makeContext()
                        ) {
                            introduction
                        } else {
                            defaultIntroduction(plugin)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                emptyView
            }
        }
    }

    @ViewBuilder
    private func pluginListRow(_ plugin: PluginInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(plugin.name, systemImage: plugin.icon)
                .font(.headline)
            Text(plugin.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func pluginHeader(_ plugin: PluginInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Label(plugin.name, systemImage: plugin.icon)
                    .font(.title3.weight(.semibold))
                Spacer()
                if plugin.allowUserToggle {
                    Toggle(
                        String(localized: "Enabled"),
                        isOn: Binding(
                            get: { pluginStates[plugin.id, default: plugin.defaultEnabled] },
                            set: { newValue in
                                pluginStates[plugin.id] = newValue
                                PluginSettingsStore.shared.setPluginEnabled(plugin.id, enabled: newValue)
                            }
                        )
                    )
                    .toggleStyle(.switch)
                    .frame(width: 160)
                } else {
                    Text(String(localized: "Always On"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                }
            }
            Text(plugin.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider()
        }
    }

    private func defaultIntroduction(_ plugin: PluginInfo) -> some View {
        Text(plugin.description.isEmpty ? String(localized: "No plugin introduction available.") : plugin.description)
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var allManagedPlugins: [PluginInfo] {
        pluginProvider.configurablePlugins.filter(\.allowUserToggle)
    }

    private var filteredPlugins: [PluginInfo] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return allManagedPlugins }
        return allManagedPlugins.filter {
            $0.name.localizedCaseInsensitiveContains(keyword)
                || $0.description.localizedCaseInsensitiveContains(keyword)
                || $0.id.localizedCaseInsensitiveContains(keyword)
        }
    }

    private var selectedPlugin: PluginInfo? {
        guard let selectedPluginID else { return filteredPlugins.first ?? allManagedPlugins.first }
        return allManagedPlugins.first(where: { $0.id == selectedPluginID })
    }

    private var emptyView: some View {
        AppEmptyState(
            icon: "puzzlepiece",
            title: String(localized: "No Plugins"),
            description: String(localized: "No plugins available in settings")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// 加载插件状态
    private func loadPluginStates() {
        guard allManagedPlugins.isEmpty == false else {
            pluginStates = [:]
            return
        }

        let settingsStore = PluginSettingsStore.shared
        var states: [String: Bool] = [:]
        for plugin in allManagedPlugins {
            if settingsStore.hasUserConfigured(plugin.id) {
                states[plugin.id] = settingsStore.isPluginEnabled(plugin.id, defaultEnabled: plugin.defaultEnabled)
            } else {
                states[plugin.id] = plugin.defaultEnabled
            }
        }
        pluginStates = states
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
