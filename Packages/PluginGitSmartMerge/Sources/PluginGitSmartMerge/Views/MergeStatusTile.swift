import Foundation
import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import SwiftUI

/// 合并状态图标：点击弹出分支合并表单（对齐旧版 MergeStatusTile）。
public struct MergeStatusTile: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    let storageDirectory: URL?
    @StateObject private var observation: ProjectObservationModel
    @State private var isPresented = false
    @State private var isHovered = false

    @LumiTheme private var theme: LumiUITheme
    @LumiMotionPreferenceReader private var motionPreference

    public init(
        projects: any ProjectProviding,
        git: any GitProviding,
        storageDirectory: URL? = nil
    ) {
        self.projects = projects
        self.git = git
        self.storageDirectory = storageDirectory
        _observation = StateObject(wrappedValue: ProjectObservationModel(projects: projects))
    }

    public var body: some View {
        Group {
            if projects.currentProject != nil {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "arrow.trianglehead.merge")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isHovered ? theme.info : theme.statusBarItemForeground)
                        .frame(width: 28, height: 24)
                        .background {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(isHovered ? theme.statusBarItemBackground : Color.clear)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(
                                    isHovered ? theme.info.opacity(0.24) : Color.clear,
                                    lineWidth: 0.75
                                )
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .scaleEffect(
                    isHovered && motionPreference.allowsMotion
                        ? LumiMotion.hoverScale
                        : 1
                )
                .onHover { hovering in
                    LumiMotion.animate(
                        LumiMotion.enabled(LumiMotion.hover, preference: motionPreference)
                    ) {
                        isHovered = hovering
                    }
                }
                .accessibilityLabel(
                    GitSmartMergeLocalization.string("Merge branches", bundle: .module)
                )
                .help(GitSmartMergeLocalization.string("Merge branches", bundle: .module))
                .popover(isPresented: $isPresented) {
                    MergeForm(
                        projects: projects,
                        git: git,
                        storageDirectory: storageDirectory
                    )
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
    let git: any GitProviding
    private let selectionStore: MergeSelectionStore
    @State private var branches: [GitBranchSummary] = []
    @State private var sourceBranch: GitBranchSummary?
    @State private var targetBranch: GitBranchSummary?
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var didRestoreSelection = false
    @State private var loadToken = 0

    public init(
        projects: any ProjectProviding,
        git: any GitProviding,
        storageDirectory: URL? = nil
    ) {
        self.projects = projects
        self.git = git
        self.selectionStore = MergeSelectionStore(storageDirectory: storageDirectory)
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
        .onChange(of: projects.currentProject?.url) { _, _ in
            loadBranches()
        }
        .onChange(of: sourceBranch?.name) { _, _ in
            persistSelectionIfReady()
        }
        .onChange(of: targetBranch?.name) { _, _ in
            persistSelectionIfReady()
        }
    }

    @MainActor
    private func loadBranches() {
        guard let projectURL = projects.currentProject?.url else { return }
        loadToken &+= 1
        let token = loadToken
        didRestoreSelection = false
        sourceBranch = nil
        targetBranch = nil
        let savedSelection = selectionStore.selection(for: projectURL)
        Task.detached(priority: .userInitiated) {
            let loaded = ((try? git.listBranches(in: projectURL)) ?? [])
                .filter { !$0.isRemote }
            await MainActor.run {
                guard token == loadToken,
                      projects.currentProject?.url == projectURL else { return }
                branches = loaded
                sourceBranch = savedSelection?.sourceBranchName
                    .flatMap { name in loaded.first(where: { $0.name == name }) }
                    ?? loaded.first(where: { !$0.isCurrent })
                    ?? loaded.first
                targetBranch = savedSelection?.targetBranchName
                    .flatMap { name in loaded.first(where: { $0.name == name }) }
                    ?? loaded.first(where: \.isCurrent)
                    ?? loaded.first
                didRestoreSelection = true
            }
        }
    }

    @MainActor
    private func persistSelectionIfReady() {
        guard didRestoreSelection,
              let projectURL = projects.currentProject?.url,
              let sourceBranch,
              let targetBranch else { return }
        selectionStore.save(
            MergeSelection(
                sourceBranchName: sourceBranch.name,
                targetBranchName: targetBranch.name
            ),
            for: projectURL
        )
    }

    @MainActor
    private func merge() {
        guard let sourceBranch, let targetBranch,
              let projectURL = projects.currentProject?.url else { return }
        persistSelectionIfReady()
        isWorking = true
        statusMessage = nil
        errorMessage = nil
        Task.detached(priority: .userInitiated) {
            do {
                _ = try git.mergeBranches(
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
