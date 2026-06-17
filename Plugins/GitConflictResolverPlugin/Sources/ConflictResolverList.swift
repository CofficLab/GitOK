import AppKit
import GitCoreKit
import GitOKCoreKit
import SwiftUI

public struct ConflictResolverList: View {
    let projectURL: URL
    private let onStatusChange: (@MainActor (_ isMerging: Bool, _ conflictCount: Int) -> Void)?
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

    public init(
        projectURL: URL,
        onStatusChange: (@MainActor (_ isMerging: Bool, _ conflictCount: Int) -> Void)? = nil
    ) {
        self.projectURL = projectURL
        self.onStatusChange = onStatusChange
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                headerBar
                conflictListView
            }
            .padding(DesignTokens.Spacing.md)
        }
        .onAppear(perform: loadConflictStatus)
    }

    private var repository: GitRepositoryCLI? {
        GitRepositoryCLI(repositoryURL: projectURL)
    }

    private var resolutionState: ConflictResolutionState {
        ConflictResolutionState(isMerging: isMerging, mergeFiles: mergeFiles)
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(GitConflictResolverPluginLocalization.string("Conflict Resolution"))
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)

                        Text(resolutionState.statusSubtitle)
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                    }

                    Spacer()

                    if isMerging {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            AppButton(
                                GitConflictResolverPluginLocalization.string("Continue Merge"),
                                systemImage: "checkmark.circle",
                                style: .secondary,
                                size: .small,
                                isLoading: isPerformingAction
                            ) {
                                continueMerge()
                            }
                            .disabled(!resolutionState.canContinueMerge || isPerformingAction)

                            AppButton(
                                GitConflictResolverPluginLocalization.string("Abort Merge"),
                                systemImage: "xmark.octagon",
                                style: .destructive,
                                size: .small,
                                isLoading: isPerformingAction
                            ) {
                                abortMerge()
                            }
                            .disabled(isPerformingAction)
                        }
                    }
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Label(
                        isMerging ? "\(mergeFiles.count) \(GitConflictResolverPluginLocalization.string("Merge Files"))" : GitConflictResolverPluginLocalization.string("Working Tree Ready"),
                        systemImage: isMerging ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
                    )
                    .font(DesignTokens.Typography.bodyEmphasized)
                    .foregroundColor(isMerging ? DesignTokens.Color.semantic.warning : DesignTokens.Color.semantic.success)

                    if isMerging, mergeBranchName != "unknown" {
                        Label(mergeBranchName, systemImage: "arrow.triangle.branch")
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                    }
                }
        }
        .padding(DesignTokens.Spacing.md)
        .gitOKUISurface(cornerRadius: DesignTokens.Radius.md)
    }

    private var conflictListView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Label(GitConflictResolverPluginLocalization.string("Merge Files"), systemImage: "exclamationmark.triangle")
                        .font(DesignTokens.Typography.bodyEmphasized)
                    Spacer()
                }

                if isLoading {
                    AppLoadingOverlay(message: GitConflictResolverPluginLocalization.string("Checking conflict status..."))
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if !isMerging {
                    AppEmptyState(
                        icon: "checkmark.circle",
                        title: GitConflictResolverPluginLocalization.string("No merge in progress"),
                        description: GitConflictResolverPluginLocalization.string("When you encounter conflicts during a merge, files needing resolution will appear here")
                    )
                    .frame(minHeight: 180)
                } else if mergeFiles.isEmpty {
                    AppEmptyState(
                        icon: "checkmark.circle.fill",
                        title: GitConflictResolverPluginLocalization.string("No files to handle"),
                        description: GitConflictResolverPluginLocalization.string("The current merge left no pending files.")
                    )
                    .frame(minHeight: 180)
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
        .padding(DesignTokens.Spacing.md)
        .gitOKUISurface(cornerRadius: DesignTokens.Radius.md)
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
                        smallToolButton(icon: "square.and.pencil", title: GitConflictResolverPluginLocalization.string("Edit"), help: GitConflictResolverPluginLocalization.string("Open the conflicted file in the default editor")) {
                            openFile(selectedFile)
                        }
                        smallToolButton(icon: "doc.text", title: "Base", help: GitConflictResolverPluginLocalization.string("Open base version")) {
                            openConflictVersion(.base, path: selectedFile)
                        }
                        smallToolButton(icon: "arrow.left.square", title: "Ours", help: GitConflictResolverPluginLocalization.string("Open ours version")) {
                            openConflictVersion(.ours, path: selectedFile)
                        }
                        smallToolButton(icon: "arrow.right.square", title: "Theirs", help: GitConflictResolverPluginLocalization.string("Open theirs version")) {
                            openConflictVersion(.theirs, path: selectedFile)
                        }
                    }
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    AppButton(
                        GitConflictResolverPluginLocalization.string("Use Ours"),
                        systemImage: "arrow.left.square",
                        style: .secondary,
                        size: .small,
                        isLoading: isPerformingAction && activeActionFile == selectedFile
                    ) {
                        checkoutMergeVersion(.ours, path: selectedFile)
                    }
                    .disabled(isPerformingAction)

                    AppButton(
                        GitConflictResolverPluginLocalization.string("Use Theirs"),
                        systemImage: "arrow.right.square",
                        style: .secondary,
                        size: .small,
                        isLoading: isPerformingAction && activeActionFile == selectedFile
                    ) {
                        checkoutMergeVersion(.theirs, path: selectedFile)
                    }
                    .disabled(isPerformingAction)

                    if selectedMergeFile?.state != .staged {
                        AppButton(
                            GitConflictResolverPluginLocalization.string("Mark Resolved"),
                            systemImage: "checkmark.circle",
                            style: .secondary,
                            size: .small,
                            isLoading: isPerformingAction && activeActionFile == selectedFile
                        ) {
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
                    AppLoadingOverlay(message: GitConflictResolverPluginLocalization.string("Loading conflict preview..."), size: .small)
                        .frame(maxWidth: .infinity, minHeight: 96)
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
            return GitConflictResolverPluginLocalization.string("Edit the file or accept one side, then mark as resolved.")
        case .pendingStage:
            return GitConflictResolverPluginLocalization.string("Conflict markers cleared, stage to continue merge.")
        case .staged:
            return GitConflictResolverPluginLocalization.string("File staged, waiting for all files to complete before continuing merge.")
        case nil:
            return ""
        }
    }

    private func diffPreview(text: String) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? GitConflictResolverPluginLocalization.string("No conflict diff to display.") : text)
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
        AppIconButton(
            systemImage: icon,
            label: title,
            tint: DesignTokens.Color.semantic.textSecondary
        ) {
            action()
        }
        .help(help)
    }
}

private extension ConflictResolverList {
    func continueMerge() {
        guard resolutionState.canContinueMerge, !isPerformingAction else { return }
        isPerformingAction = true

        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                try repository.continueMerge()
                await MainActor.run {
                    isPerformingAction = false
                    loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    showError(error)
                }
            }
        }
    }

    func abortMerge() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                try repository.abortMerge()
                await MainActor.run {
                    isPerformingAction = false
                    loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    showError(error)
                }
            }
        }
    }

    func stageFile(_ filePath: String) {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        activeActionFile = filePath

        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                try repository.addFiles([filePath])
                await MainActor.run {
                    isPerformingAction = false
                    activeActionFile = nil
                    loadConflictStatus()
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    activeActionFile = nil
                    showError(error)
                }
            }
        }
    }

    func selectFile(_ filePath: String) {
        selectedFile = filePath
        loadConflictPreview(filePath)
    }

    func loadConflictPreview(_ filePath: String) {
        isLoadingPreview = true
        previewErrorMessage = nil

        Task.detached(priority: .userInitiated) {
            let repository = GitRepositoryCLI(repositoryURL: projectURL)
            let preview = ConflictFilePreview(
                path: filePath,
                diff: (try? repository.mergeFileDiff(path: filePath)) ?? "",
                base: try? repository.mergeFileContent(path: filePath, version: .base),
                ours: try? repository.mergeFileContent(path: filePath, version: .ours),
                theirs: try? repository.mergeFileContent(path: filePath, version: .theirs)
            )

            await MainActor.run {
                guard selectedFile == filePath else { return }
                selectedPreview = preview
                isLoadingPreview = false
            }
        }
    }

    func openFile(_ filePath: String) {
        guard let fileURL = resolveFileURL(filePath) else { return }
        NSWorkspace.shared.open(fileURL)
    }

    func openConflictVersion(_ version: GitMergeFileVersion, path: String) {
        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                let content = try repository.mergeFileContent(path: path, version: version)
                let url = try Self.writeTemporaryConflictVersion(content: content, path: path, version: version)

                await MainActor.run {
                    _ = NSWorkspace.shared.open(url)
                }
            } catch {
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }

    func checkoutMergeVersion(_ version: GitMergeFileVersion, path: String) {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        activeActionFile = path

        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                try repository.checkoutMergeFileVersion(path: path, version: version)

                await MainActor.run {
                    isPerformingAction = false
                    activeActionFile = nil
                    loadConflictStatus()
                    loadConflictPreview(path)
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    activeActionFile = nil
                    showError(error)
                }
            }
        }
    }

    func revealFileInFinder(_ filePath: String) {
        guard let fileURL = resolveFileURL(filePath) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    func resolveFileURL(_ filePath: String) -> URL? {
        let repoURL = projectURL.standardizedFileURL
        let fileURL = URL(fileURLWithPath: filePath, relativeTo: repoURL).standardizedFileURL
        guard fileURL.path.hasPrefix(repoURL.path + "/") || fileURL.path == repoURL.path else {
            return nil
        }
        return fileURL
    }

    nonisolated static func writeTemporaryConflictVersion(content: String, path: String, version: GitMergeFileVersion) throws -> URL {
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

    func loadConflictStatus() {
        isLoading = true
        Task.detached(priority: .userInitiated) {
            do {
                let repository = GitRepositoryCLI(repositoryURL: projectURL)
                let merging = try repository.isMerging()
                guard merging else {
                    await MainActor.run {
                        mergeFiles = []
                        isMerging = false
                        mergeBranchName = "unknown"
                        isLoading = false
                        onStatusChange?(false, 0)
                    }
                    return
                }

                let unresolvedPaths = Set(try repository.getMergeConflictFiles())
                let statusEntries = try repository.lightweightStatusEntries()
                let mergeBranch = try repository.getCurrentMergeBranchName() ?? "unknown"
                let files = ConflictResolverStateBuilder.mergeFiles(
                    unresolvedPaths: unresolvedPaths,
                    statusEntries: statusEntries
                )
                let resolutionState = ConflictResolutionState(isMerging: true, mergeFiles: files)

                if resolutionState.canContinueMerge && files.isEmpty {
                    try repository.finalizeMergeIfNeeded()
                    await MainActor.run {
                        mergeFiles = []
                        isMerging = false
                        mergeBranchName = "unknown"
                        isLoading = false
                        onStatusChange?(false, 0)
                    }
                    return
                }

                await MainActor.run {
                    mergeFiles = files
                    isMerging = true
                    mergeBranchName = mergeBranch
                    isLoading = false
                    onStatusChange?(true, unresolvedPaths.count)

                    if let selectedFile, files.contains(where: { $0.path == selectedFile }) == false {
                        self.selectedFile = nil
                        selectedPreview = nil
                    }
                }
            } catch {
                await MainActor.run {
                    mergeFiles = []
                    isMerging = false
                    mergeBranchName = "unknown"
                    isLoading = false
                    onStatusChange?(false, 0)
                }
            }
        }
    }

    @MainActor
    func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = GitConflictResolverPluginLocalization.string("Conflict operation failed")
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

private struct ConflictFilePreview: Equatable {
    let path: String
    let diff: String
    let base: String?
    let ours: String?
    let theirs: String?
}
