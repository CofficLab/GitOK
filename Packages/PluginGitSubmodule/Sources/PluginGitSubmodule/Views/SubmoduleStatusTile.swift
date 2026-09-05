import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 子模块状态图标：显示子模块数量，点击列出并可更新
/// （对齐旧版 SubmoduleStatusTile 的核心能力）。
public struct SubmoduleStatusTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isPresented = false
    @State private var submodules: [GitSubmoduleSummary] = []
    @State private var isLoading = true

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                Image(systemName: "shippingbox")
                    .font(.system(size: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPresented = true
                    }
                    .help(submodules.isEmpty
                        ? GitSubmoduleLocalization.string("No submodules", bundle: .module)
                        : String(format: GitSubmoduleLocalization.string("%ld submodule(s)", bundle: .module), submodules.count))
                    .popover(isPresented: $isPresented) {
                        SubmoduleContentView(
                            submodules: submodules,
                            isLoading: isLoading,
                            onUpdate: updateAll
                        )
                        .frame(width: 420)
                        .padding(16)
                    }
            }
        }
        .onReceive(observation.$revision) { _ in refresh() }
        .onAppear(perform: refresh)
    }

    @MainActor
    private func refresh() {
        guard let projectURL = projects.currentProject?.url else {
            submodules = []
            isLoading = false
            return
        }
        isLoading = true
        Task.detached(priority: .utility) {
            let loaded = GitSubmoduleOperation.list(in: projectURL)
            await MainActor.run {
                submodules = loaded
                isLoading = false
            }
        }
    }

    @MainActor
    private func updateAll() {
        guard let projectURL = projects.currentProject?.url else { return }
        Task.detached(priority: .userInitiated) {
            GitSubmoduleOperation.updateAll(in: projectURL)
            let loaded = GitSubmoduleOperation.list(in: projectURL)
            await MainActor.run {
                submodules = loaded
                isLoading = false
            }
        }
    }
}

private struct SubmoduleContentView: View {
    let submodules: [GitSubmoduleSummary]
    let isLoading: Bool
    let onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox")
                VStack(alignment: .leading, spacing: 2) {
                    Text(GitSubmoduleLocalization.string("Submodules", bundle: .module))
                        .font(.headline)
                    Text(String(format: GitSubmoduleLocalization.string("%ld configured", bundle: .module), submodules.count))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                if !submodules.isEmpty {
                    AppButton(GitSubmoduleLocalization.string("Update", bundle: .module), systemImage: "arrow.down", style: .secondary, size: .small) {
                        onUpdate()
                    }
                }
            }
            Divider()
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if submodules.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.success)
                    Text(GitSubmoduleLocalization.string("No submodules configured", bundle: .module))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(submodules) { sub in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.path)
                                    .font(.caption.weight(.medium))
                                Text(sub.url)
                                    .font(.caption2)
                                    .foregroundStyle(theme.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @LumiTheme private var theme: LumiUITheme
}

/// 项目观察模型：订阅 `ProjectProviding` 事件。
@MainActor
final class ProjectObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        handle = projects.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
