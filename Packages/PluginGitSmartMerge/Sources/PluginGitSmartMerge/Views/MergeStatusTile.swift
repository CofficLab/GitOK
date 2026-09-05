import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 合并状态图标：点击弹出分支合并表单（对齐旧版 MergeStatusTile）。
public struct MergeStatusTile: View {
    let projects: any ProjectProviding
    @StateObject private var observation: ProjectObservationModel
    @State private var isPresented = false

    public init(projects: any ProjectProviding) {
        self.projects = projects
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                Image(systemName: "arrow.trianglehead.merge")
                    .font(.system(size: 10))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPresented.toggle()
                    }
                    .help(GitSmartMergeLocalization.string("Merge branches", bundle: .module))
                    .popover(isPresented: $isPresented) {
                        MergeForm(projects: projects)
                            .padding()
                            .frame(width: 280)
                    }
            }
        }
        .onReceive(observation.$revision) { _ in }
    }
}

/// 分支合并表单：选择源/目标分支并执行合并。
public struct MergeForm: View {
    let projects: any ProjectProviding
    @State private var branches: [GitBranchSummary] = []
    @State private var sourceBranch: GitBranchSummary?
    @State private var targetBranch: GitBranchSummary?
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    public init(projects: any ProjectProviding) {
        self.projects = projects
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(GitSmartMergeLocalization.string("Merge branches", bundle: .module))
                .font(.headline)

            Picker(GitSmartMergeLocalization.string("Source", bundle: .module), selection: $sourceBranch) {
                Text(GitSmartMergeLocalization.string("Select source", bundle: .module)).tag(nil as GitBranchSummary?)
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }
            .disabled(isWorking)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Text(GitSmartMergeLocalization.string("into", bundle: .module))
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .frame(maxWidth: .infinity)

            Picker(GitSmartMergeLocalization.string("Target", bundle: .module), selection: $targetBranch) {
                Text(GitSmartMergeLocalization.string("Select target", bundle: .module)).tag(nil as GitBranchSummary?)
                ForEach(branches) { branch in
                    Text(branch.name).tag(branch as GitBranchSummary?)
                }
            }
            .disabled(isWorking)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            AppButton(
                GitSmartMergeLocalization.string("Merge", bundle: .module),
                systemImage: "arrow.trianglehead.merge",
                style: .primary,
                size: .small,
                fillsWidth: true
            ) {
                merge()
            }
            .disabled(sourceBranch == nil || targetBranch == nil || sourceBranch == targetBranch || isWorking)

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(theme.success)
                    .lineLimit(3)
            }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(theme.warning)
                    .lineLimit(4)
            }
        }
        .onAppear(perform: loadBranches)
    }

    @MainActor
    private func loadBranches() {
        guard let projectURL = projects.currentProject?.url else { return }
        Task.detached(priority: .userInitiated) {
            let loaded = ((try? GitBranchOperation.listBranches(in: projectURL)) ?? [])
                .filter { !$0.isRemote }
            await MainActor.run {
                branches = loaded
                sourceBranch = loaded.first(where: { !$0.isCurrent }) ?? loaded.first
                targetBranch = loaded.first(where: \.isCurrent) ?? loaded.first
            }
        }
    }

    @MainActor
    private func merge() {
        guard let sourceBranch, let targetBranch,
              let projectURL = projects.currentProject?.url else { return }
        isWorking = true
        statusMessage = nil
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitMergeOperation.mergeBranches(
                    repository: projectURL,
                    sourceBranch: sourceBranch.name,
                    targetBranch: targetBranch.name
                )
                await MainActor.run {
                    isWorking = false
                    statusMessage = String(format: GitSmartMergeLocalization.string("Merged %@ into %@", bundle: .module), sourceBranch.name, targetBranch.name)
                }
            } catch let error as GitMergeError {
                await MainActor.run {
                    isWorking = false
                    if case let .conflict(_, files) = error {
                        errorMessage = String(format: GitSmartMergeLocalization.string("Merge paused with %ld conflict file(s)", bundle: .module), files.count)
                    } else {
                        errorMessage = error.localizedDescription
                    }
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
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
