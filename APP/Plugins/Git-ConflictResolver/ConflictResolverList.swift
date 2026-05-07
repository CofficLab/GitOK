import AppKit
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// 显示冲突文件列表的视图组件
struct ConflictResolverList: View, SuperLog, SuperThread {
    nonisolated static let emoji = "⚔️"
    nonisolated static let verbose = false

    static let shared = ConflictResolverList()

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var mergeFiles: [GitMergeFile] = []
    @State private var isLoading = true
    @State private var isMerging = false
    @State private var selectedFile: String?
    @State private var mergeBranchName = "unknown"
    @State private var isPerformingAction = false
    @State private var activeActionFile: String?

    private init() {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                headerBar
                conflictListView
            }
            .padding(DesignTokens.Spacing.md)
        }
        .onAppear(perform: onAppear)
        .onChange(of: vm.project) { _, _ in
            loadConflictStatus()
        }
        .onApplicationDidBecomeActive {
            loadConflictStatus()
        }
        .onProjectDidMerge(perform: onProjectDidMerge)
        .onProjectDidAddFiles(perform: onProjectDidAddFiles)
    }
}

// MARK: - View

extension ConflictResolverList {
    private var resolutionState: ConflictResolutionState {
        ConflictResolutionState(isMerging: isMerging, mergeFiles: mergeFiles)
    }

    private var statusSubtitle: String {
        resolutionState.statusSubtitle
    }

    private var headerBar: some View {
        GlassCard(glowColor: isMerging ? DesignTokens.Color.semantic.warning : nil) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(String(localized: "冲突解决", table: "GitConflictResolver"))
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                        Text(statusSubtitle)
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                    }

                    Spacer()

                    if isMerging {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            compactActionButton(
                                title: String(localized: "继续合并", table: "GitConflictResolver"),
                                style: .primary,
                                isDisabled: !resolutionState.canContinueMerge || isPerformingAction,
                                action: continueMerge
                            )
                            compactActionButton(
                                title: String(localized: "中止合并", table: "GitConflictResolver"),
                                style: .danger,
                                isDisabled: isPerformingAction,
                                action: abortMerge
                            )
                        }
                    }
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    conflictStatusPill

                    if isMerging, mergeBranchName != "unknown" {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "arrow.triangle.branch")
                            Text(mergeBranchName)
                        }
                        .font(DesignTokens.Typography.caption1)
                        .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(DesignTokens.Material.glass.opacity(0.08))
                        )
                    }
                }
            }
        }
    }

    private var conflictStatusPill: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: isMerging ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isMerging ? DesignTokens.Color.semantic.warning : DesignTokens.Color.semantic.success)

            VStack(alignment: .leading, spacing: 2) {
                Text(isMerging ? "\(mergeFiles.count) Merge Files" : "Working Tree Ready")
                    .font(DesignTokens.Typography.bodyEmphasized)
                    .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                Text(resolutionState.continueHint)
                    .font(DesignTokens.Typography.caption1)
                    .foregroundColor(DesignTokens.Color.semantic.textTertiary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill((isMerging ? DesignTokens.Color.semantic.warning : DesignTokens.Color.semantic.success).opacity(0.12))
        )
    }

    private func compactActionButton(title: String, style: GlassButton.Style, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        GlassButton(title: LocalizedStringKey(title), style: style, action: action)
            .frame(width: 120)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.55 : 1.0)
    }

    private var conflictListView: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                GlassSectionHeader(
                    icon: "exclamationmark.triangle",
                    title: "Merge Files",
                    subtitle: isMerging ? "Open files, resolve them in your editor, then stage them here" : "Merge conflict status",
                    iconColor: DesignTokens.Color.semantic.warning
                )

                if isLoading {
                    ProgressView(String(localized: "检查冲突状态...", table: "GitConflictResolver"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.xl)
                } else if !isMerging {
                    emptyState(
                        icon: "checkmark.circle",
                        title: String(localized: "没有正在进行的合并", table: "GitConflictResolver"),
                        subtitle: String(localized: "当您执行合并操作遇到冲突时，此处会显示需要解决的文件", table: "GitConflictResolver")
                    )
                } else if mergeFiles.isEmpty {
                    emptyState(
                        icon: "checkmark.circle.fill",
                        title: String(localized: "没有需要处理的文件", table: "GitConflictResolver"),
                        subtitle: "当前合并没有留下待处理的文件。"
                    )
                } else {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(mergeFiles) { file in
                            ConflictResolverRow(
                                file: file,
                                isSelected: selectedFile == file.path,
                                onSelect: { selectedFile = file.path },
                                onOpen: { openFile(file.path) },
                                onReveal: { revealFileInFinder(file.path) },
                                onStage: file.state == .staged ? nil : { stageFile(file.path) },
                                isBusy: isPerformingAction && activeActionFile == file.path
                            )
                            .id(file.path)
                        }
                    }
                }
            }
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundColor(DesignTokens.Color.semantic.success)

            Text(title)
                .font(DesignTokens.Typography.bodyEmphasized)
                .foregroundColor(DesignTokens.Color.semantic.textPrimary)

            Text(subtitle)
                .font(DesignTokens.Typography.caption1)
                .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxl)
    }
}

// MARK: - Action

extension ConflictResolverList {
    private func continueMerge() {
        guard let project = vm.project, resolutionState.canContinueMerge, !isPerformingAction else { return }

        isPerformingAction = true

        Task(priority: .userInitiated) {
            do {
                let branchName = try project.getCurrentMergeBranchName() ?? "unknown"
                try await project.continueMerge(branchName: branchName)

                await MainActor.run {
                    alert_info(branchName == "unknown" ? "已继续合并" : "已继续合并 \(branchName)")
                    isPerformingAction = false
                    loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    alert_error(error)
                }
            }
        }
    }

    private func abortMerge() {
        guard let project = vm.project, !isPerformingAction else { return }

        isPerformingAction = true

        Task(priority: .userInitiated) {
            do {
                try await project.abortMerge()

                await MainActor.run {
                    alert_info("已中止合并")
                    isPerformingAction = false
                    loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    alert_error(error)
                }
            }
        }
    }

    private func stageFile(_ filePath: String) {
        guard let project = vm.project, !isPerformingAction else { return }

        isPerformingAction = true
        activeActionFile = filePath

        Task(priority: .userInitiated) {
            do {
                try project.addFiles([filePath])

                await MainActor.run {
                    alert_info("已暂存 \(filePath)")
                    isPerformingAction = false
                    activeActionFile = nil
                    loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    activeActionFile = nil
                    alert_error(error)
                }
            }
        }
    }

    private func openFile(_ filePath: String) {
        guard let fileURL = resolveFileURL(filePath) else { return }
        NSWorkspace.shared.open(fileURL)
    }

    private func revealFileInFinder(_ filePath: String) {
        guard let fileURL = resolveFileURL(filePath) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    private func resolveFileURL(_ filePath: String) -> URL? {
        guard let project = vm.project else { return nil }
        let repoURL = URL(fileURLWithPath: project.path, isDirectory: true).standardizedFileURL
        let fileURL = URL(fileURLWithPath: filePath, relativeTo: repoURL).standardizedFileURL
        guard fileURL.path.hasPrefix(repoURL.path + "/") || fileURL.path == repoURL.path else {
            return nil
        }
        return fileURL
    }

    private func loadConflictStatus() {
        guard let project = vm.project else {
            mergeFiles = []
            isMerging = false
            mergeBranchName = "unknown"
            isLoading = false
            return
        }

        isLoading = true

        Task(priority: .userInitiated) {
            do {
                let merging = try await project.isMerging()
                guard merging else {
                    await MainActor.run {
                        mergeFiles = []
                        isMerging = false
                        mergeBranchName = "unknown"
                        isLoading = false
                    }
                    return
                }

                let unresolvedPaths = Set(try await project.getMergeConflictFiles())
                let unstagedFiles = try await project.unstagedDiffFileList()
                let stagedFiles = try await project.stagedDiffFileList()
                let mergeBranch = try project.getCurrentMergeBranchName() ?? "unknown"

                let unstagedPaths = Set(unstagedFiles.map(\.file))
                let stagedPaths = Set(stagedFiles.map(\.file))
                let allPaths = unresolvedPaths.union(unstagedPaths).union(stagedPaths).sorted()

                let files = allPaths.map { path -> GitMergeFile in
                    if unresolvedPaths.contains(path) {
                        return GitMergeFile(path: path, state: .unresolved)
                    }
                    if unstagedPaths.contains(path) {
                        return GitMergeFile(path: path, state: .pendingStage)
                    }
                    return GitMergeFile(path: path, state: .staged)
                }

                await MainActor.run {
                    mergeFiles = files
                    isMerging = true
                    mergeBranchName = mergeBranch
                    isLoading = false

                    if let selectedFile, files.contains(where: { $0.path == selectedFile }) == false {
                        self.selectedFile = nil
                    }
                }
            } catch {
                if Self.verbose {
                    os_log("\(self.t)❌ Failed to load conflict status: \(error)")
                }
                await MainActor.run {
                    mergeFiles = []
                    isMerging = false
                    mergeBranchName = "unknown"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Event Handler

extension ConflictResolverList {
    func onAppear() {
        loadConflictStatus()
    }

    func onProjectDidMerge(_ eventInfo: ProjectEventInfo) {
        handleRefreshTrigger(notificationName: .projectDidMerge)
    }

    func onProjectDidAddFiles(_ eventInfo: ProjectEventInfo) {
        handleRefreshTrigger(notificationName: .projectDidAddFiles)
    }

    private func handleRefreshTrigger(notificationName: Notification.Name) {
        guard ProjectEventRefreshRules.shouldRefreshConflictStatus(for: notificationName) else { return }
        loadConflictStatus()
    }
}
