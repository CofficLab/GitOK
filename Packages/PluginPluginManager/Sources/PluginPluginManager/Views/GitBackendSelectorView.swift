import LumiUI
import ProviderGit
import ProviderPluginManaging
import SwiftUI

/// 插件管理中的 Git 后端选择器。
///
/// 后端插件属于 `git-backend` 互斥组。这里通过真实的 PluginManaging
/// 启停插件，后端插件生命周期会负责注册/撤销实现，Provider 则负责路由。
struct GitBackendSelectorView: View {
    @LumiTheme private var theme

    let manager: any PluginManaging
    let git: any GitProviding

    @State private var updatingBackendID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Git Backend")
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)

            ForEach(GitBackendCatalog.all) { backend in
                Button {
                    select(backend)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: git.selectedBackendID == backend.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(git.selectedBackendID == backend.id ? theme.primary : theme.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(backend.name)
                                .font(.appBody)
                                .foregroundStyle(theme.textPrimary)
                            Text(manager.isEnabled(id: backend.pluginID) ? "Enabled" : "Disabled")
                                .font(.appCaption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(updatingBackendID != nil)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func select(_ backend: GitBackendDescriptor) {
        guard updatingBackendID == nil else { return }
        updatingBackendID = backend.id
        Task { @MainActor in
            defer { updatingBackendID = nil }
            guard await manager.enablePlugin(id: backend.pluginID) else { return }
            try? git.selectBackend(id: backend.id)
        }
    }
}
