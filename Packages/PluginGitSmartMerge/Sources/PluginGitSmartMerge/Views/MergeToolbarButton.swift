import Foundation
import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import SwiftUI

/// 工具栏右侧的合并入口按钮：点击弹出分支合并表单（对齐旧版 MergeStatusTile）。
///
/// 视觉与工具栏其它按钮一致（`AppIconButton(.regular)` 外壳），图标使用
/// `arrow.trianglehead.merge`，hover 时由 `AppIconButton` 统一处理。
public struct MergeToolbarButton: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    let storageDirectory: URL?
    @StateObject private var observation: ProjectObservationModel
    @State private var isPresented = false

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
                AppIconButton(
                    systemImage: "arrow.trianglehead.merge",
                    tint: theme.info,
                    size: .regular,
                    action: { isPresented.toggle() }
                )
                .accessibilityLabel(
                    GitSmartMergeLocalization.string("Merge branches", bundle: .module)
                )
                .popover(isPresented: $isPresented, arrowEdge: .bottom) {
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

    @LumiTheme private var theme: LumiUITheme
}

/// 分支合并表单：选择源/目标分支并执行合并。
public struct MergeForm: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    private let reader: MergeBranchReader
    private let selectionStore: MergeSelectionStore
    private let branchCacheStore: MergeBranchCacheStore
    @State private var branches: [GitBranchSummary] = []
    @State private var sourceBranch: GitBranchSummary?
    @State private var targetBranch: GitBranchSummary?
    @State private var isLoadingBranches = false
    @State private var isRefreshingBranches = false
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
        self.reader = MergeBranchReader.live(git: git)
        self.selectionStore = MergeSelectionStore(storageDirectory: storageDirectory)
        self.branchCacheStore = MergeBranchCacheStore(storageDirectory: storageDirectory)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(GitSmartMergeLocalization.string("Merge branches", bundle: .module))
                    .font(.headline)

                Spacer(minLength: 0)

                if isRefreshingBranches {
                    ProgressView()
                        .controlSize(.mini)
                        .accessibilityHidden(true)
                }
            }

            if isLoadingBranches {
                MergeFormSkeleton()
            } else {
                Picker(GitSmartMergeLocalization.string("Source", bundle: .module), selection: $sourceBranch) {
                    Text(GitSmartMergeLocalization.string("Select source", bundle: .module)).tag(nil as GitBranchSummary?)
                    ForEach(branches) { branch in
                        Text(branch.name).tag(branch as GitBranchSummary?)
                    }
                }
                .disabled(isWorking)
                .labelsHidden()
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    Text(GitSmartMergeLocalization.string("into", bundle: .module))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)

                    Spacer(minLength: 0)

                    AppButton(
                        systemImage: "arrow.up.arrow.down",
                        style: .tonal,
                        size: .small
                    ) {
                        swapBranches()
                    }
                    .accessibilityLabel(
                        GitSmartMergeLocalization.string("Swap branches", bundle: .module)
                    )
                    .help(
                        GitSmartMergeLocalization.string("Swap branches", bundle: .module)
                    )
                    .disabled(sourceBranch == nil || targetBranch == nil || isWorking)
                }

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
            }

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
        statusMessage = nil
        errorMessage = nil

        let savedSelection = selectionStore.selection(for: projectURL)
        let cachedBranches = branchCacheStore.branches(for: projectURL)
        if cachedBranches.isEmpty {
            branches = []
            sourceBranch = nil
            targetBranch = nil
            didRestoreSelection = false
            isLoadingBranches = true
        } else {
            branches = cachedBranches
            applyResolvedSelection(
                MergeBranchSelectionResolver.resolve(branches: cachedBranches, saved: savedSelection)
            )
            didRestoreSelection = true
            isLoadingBranches = false
        }
        isRefreshingBranches = true

        Task.detached(priority: .userInitiated) {
            let loaded: [GitBranchSummary]?
            do {
                loaded = try reader.loadLocalBranches(in: projectURL)
            } catch {
                loaded = nil
            }
            await MainActor.run {
                guard token == loadToken,
                      projects.currentProject?.url == projectURL else { return }
                isRefreshingBranches = false
                isLoadingBranches = false
                // 读取失败时保留缓存列表，用户仍可基于上一次结果发起合并。
                guard let loaded else { return }

                branches = loaded
                branchCacheStore.save(loaded, for: projectURL)
                applyResolvedSelection(
                    MergeBranchSelectionResolver.resolve(
                        branches: loaded,
                        saved: savedSelection,
                        keeping: sourceBranch,
                        currentTarget: targetBranch
                    )
                )
                didRestoreSelection = true
            }
        }
    }

    @MainActor
    private func applyResolvedSelection(
        _ selection: (source: GitBranchSummary?, target: GitBranchSummary?)
    ) {
        sourceBranch = selection.source
        targetBranch = selection.target
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
    private func swapBranches() {
        guard !isWorking else { return }
        let currentSource = sourceBranch
        sourceBranch = targetBranch
        targetBranch = currentSource
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

/// 首次读取分支（无缓存可用）时的表单骨架，保持弹层高度与结构稳定。
private struct MergeFormSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSkeletonBlock(height: 22, shape: .roundedRectangle(cornerRadius: 6))

            HStack(spacing: 8) {
                AppSkeletonBlock(width: 26, height: 10)

                Spacer(minLength: 0)

                AppSkeletonBlock(width: 24, height: 24, shape: .roundedRectangle(cornerRadius: 6))
            }

            AppSkeletonBlock(height: 22, shape: .roundedRectangle(cornerRadius: 6))
            AppSkeletonBlock(height: 24, shape: .roundedRectangle(cornerRadius: 6))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(GitSmartMergeLocalization.string("Loading branches…", bundle: .module))
        )
    }
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
