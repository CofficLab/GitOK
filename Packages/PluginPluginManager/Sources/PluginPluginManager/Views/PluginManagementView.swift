import KernelCore
import LumiUI
import SwiftUI

/// 设置 - 插件 详情视图。
///
/// 复刻 Lumi 的插件管理界面：列出内核中已装配的全部插件
/// （按 `order` 排序），每行显示名称 / 描述 / 分类图标，
/// 可配置插件提供启用开关；必需 / 固定插件显示「固定」标签且不可切换。
///
/// - 启用 / 禁用调用 `KernelCoreContainer.enablePlugin / disablePlugin`，
///   失败时回滚本地状态并显示错误横幅（如插件存在依赖或内核未运行）。
/// - 本视图直接持有弱引用内核，由 `PluginManagerPlugin` 注入。
struct PluginManagementView: View {
    let kernel: KernelCoreContainer

    /// 插件行本地状态（禁用 / 启用切换即时反映，异步落库）。
    @State private var rows: [PluginRowModel] = []
    @State private var errorMessage: String?

    var body: some View {
        AppSettingsContentScaffold {
            VStack(alignment: .leading, spacing: 24) {
                header

                if rows.isEmpty {
                    AppEmptyState(
                        icon: "puzzlepiece.extension",
                        title: "没有已装配的插件",
                        description: "内核尚未注册任何插件。"
                    )
                } else {
                    pluginList
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear(perform: reload)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("插件")
                .font(.appTitle)
                .foregroundColor(theme.textPrimary)
            Text("管理已装配插件的启用状态（共 \(rows.count) 个）")
                .font(.appCaption)
                .foregroundColor(theme.textSecondary)
        }
    }

    @LumiTheme private var theme

    // MARK: - Plugin List

    private var pluginList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { _, row in
                pluginRow(row)
            }
        }
        .overlay(alignment: .top) {
            if let errorMessage {
                AppErrorBanner(message: LocalizedStringKey(errorMessage))
                    .padding(.horizontal, 16)
            }
        }
    }

    private func pluginRow(_ row: PluginRowModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: row.systemImage)
                .font(.system(size: 16))
                .foregroundColor(theme.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(row.name)
                        .font(.appBody)
                        .foregroundColor(theme.textPrimary)
                    if row.isLocked {
                        lockedBadge
                    }
                }
                Text(row.description.isEmpty ? row.id : row.description)
                    .font(.appCaption)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if row.isLocked {
                Text("固定")
                    .font(.appMicro)
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(theme.overlay, in: Capsule())
            } else {
                Toggle("", isOn: binding(for: row.id))
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(theme.surface.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }

    private var lockedBadge: some View {
        Text("必")
            .font(.appMicro)
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(theme.primary, in: Capsule())
    }

    // MARK: - State

    private func reload() {
        rows = kernel.allPlugins
            .map { PluginRowModel(plugin: $0, kernel: kernel) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func binding(for pluginID: String) -> Binding<Bool> {
        Binding(
            get: {
                rows.first(where: { $0.id == pluginID })?.isEnabled ?? false
            },
            set: { newValue in
                guard let index = rows.firstIndex(where: { $0.id == pluginID }) else { return }
                rows[index].isEnabled = newValue
                togglePlugin(id: pluginID, enabled: newValue)
            }
        )
    }

    private func togglePlugin(id: String, enabled: Bool) {
        errorMessage = nil
        Task { @MainActor in
            do {
                if enabled {
                    try await kernel.enablePlugin(id: id)
                } else {
                    try await kernel.disablePlugin(id: id)
                }
            } catch {
                // 回滚本地状态，保持 UI 与内核一致。
                if let index = rows.firstIndex(where: { $0.id == id }) {
                    rows[index].isEnabled = !enabled
                }
                errorMessage = "\(enabled ? "启用" : "禁用")「\(id)」失败：\(error.localizedDescription)"
            }
        }
    }
}

/// 插件行模型：由 `SuperPlugin.metadata` 派生展示信息。
@MainActor
struct PluginRowModel: Identifiable {
    let id: String
    let name: String
    let description: String
    let systemImage: String
    let isLocked: Bool
    let sortOrder: Int
    var isEnabled: Bool

    init(plugin: any SuperPlugin, kernel: KernelCoreContainer) {
        let metadata = plugin.metadata
        id = metadata.id
        name = metadata.name
        description = metadata.description
        systemImage = Self.systemImage(for: metadata.category)
        isLocked = !metadata.policy.isConfigurable
        sortOrder = plugin.order
        isEnabled = kernel.isPluginEnabled(id: plugin.id)
    }

    /// 分类 → SF Symbol 图标。
    static func systemImage(for category: PluginCategory) -> String {
        switch category {
        case .core: "cube"
        case .chat: "bubble.left.and.bubble.right"
        case .llm: "brain.head.profile"
        case .editor: "pencil.and.outline"
        case .project: "folder"
        case .system: "gearshape"
        case .design: "paintpalette"
        case .integration: "link"
        case .general: "square.grid.2x2"
        }
    }
}
