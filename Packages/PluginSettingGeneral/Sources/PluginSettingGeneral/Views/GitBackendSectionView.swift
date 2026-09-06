import LumiUI
import ProviderGit
import SwiftUI

private func gitBackendLoc(_ key: String) -> String {
    LumiPluginLocalization.string(key, bundle: .module)
}

/// 通用设置中的 Git 后端实现列表。
///
/// 列表只消费 Provider 返回的描述信息，不直接依赖 CLI 或 LibGit2Swift 插件。
struct GitBackendSectionView: View {
    let backends: [GitBackendDescriptor]

    var body: some View {
        AppSettingSection(
            title: gitBackendLoc("Git Backends"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                ForEach(Array(backends.enumerated()), id: \.element.id) { index, backend in
                    AppSettingRow(
                        title: backend.name,
                        description: description(for: backend),
                        icon: "gearshape.2"
                    ) { EmptyView() }

                    if index < backends.count - 1 {
                        Divider().padding(.vertical, 8)
                    }
                }
            }
        }
    }

    private func description(for backend: GitBackendDescriptor) -> String {
        "\(gitBackendLoc("Version")) \(backend.version) · \(gitBackendLoc("Plugin ID")) \(backend.pluginID)"
    }
}
