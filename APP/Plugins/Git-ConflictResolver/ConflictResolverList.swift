import AppKit
import GitCoreKit
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
    @State private var selectedPreview: ConflictFilePreview?
    @State private var isLoadingPreview = false
    @State private var previewErrorMessage: String?

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
        .onProjectGitIndexDidChange(perform: onGitDirectoryDidChange)
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
                                onSelect: { selectFile(file.path) },
                                onOpen: { openFile(file.path) },
                                onReveal: { revealFileInFinder(file.path) },
                                onStage: file.state == .staged ? nil : { stageFile(file.path) },
                                isBusy: isPerformingAction && activeActionFile == file.path
                            )
                            .id(file.path)
                        }
                    }

                    selectedFileWorkbench
                }
            }
        }
    }

    @ViewBuilder
    private var selectedFileWorkbench: some View {
        if let selectedFile {
            Divider()
                .padding(.vertical, DesignTokens.Spacing.xs)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text((selectedFile as NSString).lastPathComponent)
                            .font(DesignTokens.Typography.bodyEmphasized)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)
                            .lineLimit(1)

                        Text(selectedFile)
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        smallToolButton(icon: "square.and.pencil", title: "编辑", help: "用默认编辑器打开当前冲突文件") {
                            openFileInDefaultEditor(selectedFile)
                        }
                        smallToolButton(icon: "doc.text", title: "Base", help: "打开共同祖先版本") {
                            openConflictVersion(.base, path: selectedFile)
                        }
                        smallToolButton(icon: "arrow.left.square", title: "Ours", help: "打开 ours 版本") {
                            openConflictVersion(.ours, path: selectedFile)
                        }
                        smallToolButton(icon: "arrow.right.square", title: "Theirs", help: "打开 theirs 版本") {
                            openConflictVersion(.theirs, path: selectedFile)
                        }
                    }
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    GlassButton(title: "采用 Ours", style: .secondary) {
                        checkoutMergeVersion(.ours, path: selectedFile)
                    }
                    .disabled(isPerformingAction)

                    GlassButton(title: "采用 Theirs", style: .secondary) {
                        checkoutMergeVersion(.theirs, path: selectedFile)
                    }
                    .disabled(isPerformingAction)

                    if selectedMergeFile?.state != .staged {
                        GlassButton(title: "标记已解决", style: .primary) {
                            stageFile(selectedFile)
                        }
                        .disabled(isPerformingAction)
                    }

                    Spacer()

                    Text(workflowHint)
                        .font(DesignTokens.Typography.caption1)
                        .foregroundColor(DesignTokens.Color.semantic.textTertiary)
                }

                if isLoadingPreview {
                    ProgressView("加载冲突预览...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.lg)
                } else if let previewErrorMessage {
                    Text(previewErrorMessage)
                        .font(DesignTokens.Typography.caption1)
                        .foregroundColor(DesignTokens.Color.semantic.error)
                } else if let selectedPreview, selectedPreview.path == selectedFile {
                    diffPreview(text: selectedPreview.diff)
                }
            }
        }
    }

    private var selectedMergeFile: GitMergeFile? {
        guard let selectedFile else { return nil }
        return mergeFiles.first { $0.path == selectedFile }
    }

    private var workflowHint: String {
        switch selectedMergeFile?.state {
        case .unresolved:
            return "先编辑文件或采用一侧，再标记已解决。"
        case .pendingStage:
            return "冲突标记已清理，暂存后即可继续合并。"
        case .staged:
            return "文件已暂存，等待所有文件完成后继续合并。"
        case nil:
            return ""
        }
    }

    private func diffPreview(text: String) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "没有可显示的冲突 diff。" : text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                .textSelection(.enabled)
                .padding(DesignTokens.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 160, maxHeight: 240)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(DesignTokens.Material.glass.opacity(0.08))
        )
    }

    private func smallToolButton(icon: String, title: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(DesignTokens.Typography.caption1)
                .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .fill(DesignTokens.Material.glass.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .help(help)
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

    private func selectFile(_ filePath: String) {
        selectedFile = filePath
        loadConflictPreview(filePath)
    }

    private func loadConflictPreview(_ filePath: String) {
        guard let project = vm.project else { return }

        isLoadingPreview = true
        previewErrorMessage = nil

        Task(priority: .userInitiated) {
            do {
                let preview = ConflictFilePreview(
                    path: filePath,
                    diff: try project.mergeFileDiff(path: filePath),
                    base: try? project.mergeFileContent(path: filePath, version: .base),
                    ours: try? project.mergeFileContent(path: filePath, version: .ours),
                    theirs: try? project.mergeFileContent(path: filePath, version: .theirs)
                )

                await MainActor.run {
                    guard selectedFile == filePath else { return }
                    selectedPreview = preview
                    isLoadingPreview = false
                }
            } catch {
                await MainActor.run {
                    guard selectedFile == filePath else { return }
                    selectedPreview = nil
                    previewErrorMessage = error.localizedDescription
                    isLoadingPreview = false
                }
            }
        }
    }

    private func openFile(_ filePath: String) {
        guard let fileURL = resolveFileURL(filePath) else { return }
        NSWorkspace.shared.open(fileURL)
    }

    private func openFileInDefaultEditor(_ filePath: String) {
        guard let fileURL = resolveFileURL(filePath) else { return }
        ExternalToolSettingsStore.shared.openDefaultEditor(for: fileURL)
    }

    private func openConflictVersion(_ version: GitMergeFileVersion, path: String) {
        guard let project = vm.project else { return }

        Task(priority: .userInitiated) {
            do {
                let content: String
                switch version {
                case .base:
                    content = try project.mergeFileContent(path: path, version: .base)
                case .ours:
                    content = try project.mergeFileContent(path: path, version: .ours)
                case .theirs:
                    content = try project.mergeFileContent(path: path, version: .theirs)
                }
                let url = try writeTemporaryConflictVersion(content: content, path: path, version: version)

                await MainActor.run {
                    _ = NSWorkspace.shared.open(url)
                }
            } catch {
                await MainActor.run {
                    alert_error(error)
                }
            }
        }
    }

    private func checkoutMergeVersion(_ version: GitMergeFileVersion, path: String) {
        guard let project = vm.project, !isPerformingAction else { return }

        isPerformingAction = true
        activeActionFile = path

        Task(priority: .userInitiated) {
            do {
                try project.checkoutMergeFileVersion(path: path, version: version)

                await MainActor.run {
                    alert_info(version == .ours ? "已采用 ours 版本" : "已采用 theirs 版本")
                    isPerformingAction = false
                    activeActionFile = nil
                    loadConflictStatus()
                    loadConflictPreview(path)
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

    private func writeTemporaryConflictVersion(content: String, path: String, version: GitMergeFileVersion) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKConflictResolver", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let originalName = (path as NSString).lastPathComponent
        let fileName = "\(version.rawValue)-\(originalName)"
        let url = directory.appendingPathComponent(fileName)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
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
                        self.selectedPreview = nil
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

    func onGitDirectoryDidChange(_ eventInfo: ProjectEventInfo) {
        guard eventInfo.project.path == vm.project?.path else { return }
        loadConflictStatus()
    }

    private func handleRefreshTrigger(notificationName: Notification.Name) {
        guard ProjectEventRefreshRules.shouldRefreshConflictStatus(for: notificationName) else { return }
        loadConflictStatus()
    }
}

private struct ConflictFilePreview: Equatable {
    let path: String
    let diff: String
    let base: String?
    let ours: String?
    let theirs: String?
}
