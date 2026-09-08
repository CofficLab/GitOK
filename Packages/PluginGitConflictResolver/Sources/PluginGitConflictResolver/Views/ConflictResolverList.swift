import AppKit
import KitGit
import KitOpenIn
import LumiUI
import ProviderProjects
import ProviderGit
import SwiftUI

/// 冲突文件列表：展示合并中的冲突文件，可复制路径或定位到 Finder。
public struct ConflictResolverList: View {
    let projects: any ProjectProviding
    let git: any GitProviding
    @ObservedObject private var viewModel: GitConflictResolverViewModel
    private let onDismiss: (() -> Void)?
    @State private var conflictDiff: String?
    @State private var isActionRunning = false
    @State private var actionError: String?
    @State private var showAbortConfirmation = false
    @State private var moreActionsFile: String?

    public init(
        projects: any ProjectProviding,
        git: any GitProviding,
        viewModel: GitConflictResolverViewModel,
        onDismiss: (() -> Void)? = nil
    ) {
        self.projects = projects
        self.git = git
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            actionBar
            if let actionError {
                AppErrorBanner(message: LocalizedStringKey(actionError))
            }
            AppDivider()
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.isLoading && !viewModel.hasLoadedSnapshot {
                        AppStatusBanner(
                            kind: .loading,
                            title: LumiPluginLocalization.string("Checking conflicts…", bundle: .module),
                            message: LumiPluginLocalization.string("Reading the current Git operation.", bundle: .module)
                        )
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else if !viewModel.displayedConflictFiles.isEmpty {
                        ForEach(viewModel.displayedConflictFiles, id: \.self) { file in
                            conflictRow(
                                file,
                                isResolved: viewModel.isConflictFileResolved(file)
                            )
                        }
                    } else if viewModel.isOperationInProgress {
                        AppStatusBanner(
                            kind: .success,
                            title: LumiPluginLocalization.string(
                                viewModel.isCherryPicking ? "Cherry-pick is ready to continue" : "Merge ready to complete",
                                bundle: .module
                            ),
                            message: LumiPluginLocalization.string(
                                viewModel.isCherryPicking
                                    ? "All conflicts are resolved. Continue the cherry-pick to finish it."
                                    : "All conflicts are resolved. Continue the merge to create the merge commit.",
                                bundle: .module
                            )
                        )
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else if viewModel.conflictedFiles.isEmpty {
                        AppEmptyState(
                            icon: "checkmark.circle",
                            title: LumiPluginLocalization.string("No merge conflicts", bundle: .module)
                        )
                        .frame(maxWidth: .infinity, minHeight: 120)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .alert(
            LumiPluginLocalization.string(
                viewModel.isCherryPicking ? "Confirm Abort Cherry-pick?" : "Confirm Abort Merge?",
                bundle: .module
            ),
            isPresented: $showAbortConfirmation
        ) {
            Button(LumiPluginLocalization.string("Cancel", bundle: .module), role: .cancel) {}
            Button(
                LumiPluginLocalization.string(
                    viewModel.isCherryPicking ? "Abort Cherry-pick" : "Abort Merge",
                    bundle: .module
                ),
                role: .destructive
            ) {
                abortMerge()
            }
        } message: {
            Text(LumiPluginLocalization.string(
                viewModel.isCherryPicking
                    ? "This discards the in-progress cherry-pick and restores the pre-cherry-pick state."
                    : "This discards the in-progress merge and restores the pre-merge state.",
                bundle: .module
            ))
        }
        .sheet(
            isPresented: Binding(
                get: { conflictDiff != nil },
                set: { isPresented in
                    if !isPresented { conflictDiff = nil }
                }
            )
        ) {
            ScrollView {
                Text(conflictDiff ?? "")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .frame(minWidth: 640, minHeight: 420)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            GlassSectionHeader(
                icon: "exclamationmark.triangle.fill",
                title: LumiPluginLocalization.string("Conflict Resolution", bundle: .module),
                subtitle: headerSubtitle,
                iconColor: theme.warning,
                spacing: DesignTokens.Spacing.xs
            )
            Spacer(minLength: 0)
            if let onDismiss {
                AppCircularIconButton(
                    systemImage: "xmark",
                    accessibilityLabel: LumiPluginLocalization.string("Close", bundle: .module),
                    size: 28,
                    action: onDismiss
                )
                .help(LumiPluginLocalization.string("Close", bundle: .module))
            }
        }
    }

    private var headerSubtitle: String {
        if !viewModel.conflictedFiles.isEmpty {
            if !pendingStageFiles.isEmpty {
                if pendingStageFiles.count == viewModel.conflictedFiles.count {
                    return String(format: LumiPluginLocalization.string("%lld resolved; stage to continue", bundle: .module), pendingStageFiles.count)
                }
                let unresolved = String(format: LumiPluginLocalization.string("%lld conflicted file(s) remaining", bundle: .module), viewModel.conflictedFiles.count - pendingStageFiles.count)
                return unresolved + " · " + String(format: LumiPluginLocalization.string("%lld resolved; stage to continue", bundle: .module), pendingStageFiles.count)
            }
            if !stagedResolvedFiles.isEmpty {
                let unresolved = String(format: LumiPluginLocalization.string("%lld conflicted file(s) remaining", bundle: .module), viewModel.conflictedFiles.count)
                return unresolved + " · " + String(format: LumiPluginLocalization.string("%lld staged", bundle: .module), stagedResolvedFiles.count)
            }
            return String(format: LumiPluginLocalization.string("%lld conflicted file(s)", bundle: .module), viewModel.conflictedFiles.count)
        }
        if !pendingStageFiles.isEmpty {
            return String(format: LumiPluginLocalization.string("%lld resolved; stage to continue", bundle: .module), viewModel.resolvedConflictFiles.count)
        }
        if !stagedResolvedFiles.isEmpty {
            return String(format: LumiPluginLocalization.string("%lld resolved; ready to continue", bundle: .module), stagedResolvedFiles.count)
        }
        if viewModel.isOperationInProgress {
            return LumiPluginLocalization.string(
                viewModel.isCherryPicking ? "Cherry-pick is ready to continue" : "Merge is ready to continue",
                bundle: .module
            )
        }
        return LumiPluginLocalization.string("No conflicted files", bundle: .module)
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            if !pendingStageFiles.isEmpty {
                AppButton(
                    LumiPluginLocalization.string("Stage Resolved Files", bundle: .module),
                    systemImage: "checkmark.circle",
                    style: .primary,
                    size: .small,
                    action: stageResolvedFiles
                )
                .disabled(isActionRunning)
            }

            AppButton(
                LumiPluginLocalization.string(
                    viewModel.isCherryPicking ? "Continue Cherry-pick" : "Continue Merge",
                    bundle: .module
                ),
                systemImage: "arrow.right.circle",
                style: pendingStageFiles.isEmpty ? .primary : .secondary,
                size: .small,
                action: continueMerge
            )
            .disabled(!viewModel.isOperationInProgress || !viewModel.conflictedFiles.isEmpty || isActionRunning)

            if isActionRunning {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer(minLength: DesignTokens.Spacing.xl)

            AppButton(
                LumiPluginLocalization.string(
                    viewModel.isCherryPicking ? "Abort Cherry-pick" : "Abort Merge",
                    bundle: .module
                ),
                systemImage: "xmark.circle",
                style: .destructive,
                size: .small,
                action: { showAbortConfirmation = true }
            )
            .disabled(!viewModel.isOperationInProgress || isActionRunning)
        }
    }

    private var pendingStageFiles: [String] {
        viewModel.resolvedConflictFiles.filter { viewModel.conflictedFiles.contains($0) }
    }

    private var stagedResolvedFiles: [String] {
        viewModel.resolvedConflictFiles.filter { !viewModel.conflictedFiles.contains($0) }
    }

    private func conflictRow(_ file: String, isResolved: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isResolved ? "checkmark.circle.fill" : "exclamationmark.triangle")
                .foregroundStyle(isResolved ? theme.success : theme.warning)
            Text(file)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if isResolved {
                AppTag(
                    viewModel.conflictedFiles.contains(file)
                        ? LumiPluginLocalization.string("Resolved; stage to continue", bundle: .module)
                        : LumiPluginLocalization.string("Staged", bundle: .module),
                    systemImage: viewModel.conflictedFiles.contains(file) ? "checkmark" : "checkmark.circle.fill",
                    style: .accent
                )
            }
            AppIconButton(systemImage: "doc.on.doc", label: LumiPluginLocalization.string("Copy Path", bundle: .module), tint: theme.textSecondary) {
                copyText(file)
            }
            AppIconButton(systemImage: "folder", label: LumiPluginLocalization.string("Reveal in Finder", bundle: .module), tint: theme.textSecondary) {
                reveal(file)
            }
            AppIconButton(systemImage: "ellipsis.circle", tint: theme.textSecondary) {
                moreActionsFile = moreActionsFile == file ? nil : file
            }
            .accessibilityLabel(LumiPluginLocalization.string("More Actions", bundle: .module))
            .help(LumiPluginLocalization.string("More Actions", bundle: .module))
            .disabled(isActionRunning)
            .popover(
                isPresented: moreActionsBinding(for: file),
                arrowEdge: .bottom
            ) {
                ConflictFileActionsPopover(
                    onUseOurs: {
                        moreActionsFile = nil
                        checkout(file, version: .ours)
                    },
                    onUseTheirs: {
                        moreActionsFile = nil
                        checkout(file, version: .theirs)
                    },
                    onUseBase: {
                        moreActionsFile = nil
                        checkout(file, version: .base)
                    },
                    onOpenInVSCode: {
                        moreActionsFile = nil
                        openInVSCode(file)
                    },
                    onViewDiff: {
                        moreActionsFile = nil
                        showDiff(file)
                    }
                )
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .appSurface(
            style: .listRow,
            cornerRadius: DesignTokens.Radius.sm,
            borderColor: theme.appSubtleBorder
        )
    }

    private func moreActionsBinding(for file: String) -> Binding<Bool> {
        Binding(
            get: { moreActionsFile == file },
            set: { isPresented in
                if !isPresented, moreActionsFile == file {
                    moreActionsFile = nil
                }
            }
        )
    }

    private func checkout(_ file: String, version: GitMergeFileVersion) {
        guard let url = projects.currentProject?.url else { return }
        isActionRunning = true
        actionError = nil
        Task.detached(priority: .userInitiated) {
            do {
                try git.checkoutMergeFileVersion(path: file, version: version, in: url)
                await MainActor.run {
                    isActionRunning = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    isActionRunning = false
                    actionError = error.localizedDescription
                }
            }
        }
    }

    private func stageResolvedFiles() {
        guard let url = projects.currentProject?.url,
              !pendingStageFiles.isEmpty else { return }
        isActionRunning = true
        actionError = nil
        let files = pendingStageFiles
        Task.detached(priority: .userInitiated) {
            do {
                try git.stageFiles(files, in: url)
                await MainActor.run {
                    isActionRunning = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    isActionRunning = false
                    actionError = error.localizedDescription
                }
            }
        }
    }

    private func continueMerge() {
        guard let url = projects.currentProject?.url else { return }
        guard viewModel.conflictedFiles.isEmpty else {
            actionError = LumiPluginLocalization.string(
                viewModel.isCherryPicking
                    ? "Resolve all conflicts before continuing the cherry-pick."
                    : "Resolve all conflicts before continuing the merge.",
                bundle: .module
            )
            return
        }
        isActionRunning = true
        actionError = nil
        let cherryPicking = viewModel.isCherryPicking
        Task.detached(priority: .userInitiated) {
            do {
                if cherryPicking {
                    _ = try git.continueCherryPick(in: url)
                } else {
                    _ = try git.continueMerge(in: url)
                }
                await MainActor.run {
                    isActionRunning = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    isActionRunning = false
                    actionError = error.localizedDescription
                }
            }
        }
    }

    private func abortMerge() {
        guard let url = projects.currentProject?.url else { return }
        isActionRunning = true
        actionError = nil
        let cherryPicking = viewModel.isCherryPicking
        Task.detached(priority: .userInitiated) {
            do {
                if cherryPicking {
                    _ = try git.abortCherryPick(in: url)
                } else {
                    _ = try git.abortMerge(in: url)
                }
                await MainActor.run {
                    isActionRunning = false
                    projects.notifyDataChanged()
                }
            } catch {
                await MainActor.run {
                    isActionRunning = false
                    actionError = error.localizedDescription
                }
            }
        }
    }

    private func showDiff(_ file: String) {
        guard let url = projects.currentProject?.url else { return }
        isActionRunning = true
        actionError = nil
        Task.detached(priority: .userInitiated) {
            do {
                let diff = try git.mergeFileDiff(path: file, in: url)
                await MainActor.run {
                    isActionRunning = false
                    conflictDiff = diff
                }
            } catch {
                await MainActor.run {
                    isActionRunning = false
                    actionError = error.localizedDescription
                }
            }
        }
    }

    private func copyText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func reveal(_ file: String) {
        guard let url = projects.currentProject?.url else { return }
        let target = url.appendingPathComponent(file)
        NSWorkspace.shared.activateFileViewerSelecting([target])
    }

    private func openInVSCode(_ file: String) {
        guard let url = projects.currentProject?.url else { return }
        AppLauncher.openFile(url.appendingPathComponent(file), in: .vscode)
    }

    @LumiTheme private var theme: LumiUITheme
}

private struct ConflictFileActionsPopover: View {
    let onUseOurs: () -> Void
    let onUseTheirs: () -> Void
    let onUseBase: () -> Void
    let onOpenInVSCode: () -> Void
    let onViewDiff: () -> Void

    var body: some View {
        AppCard(
            style: .elevated,
            cornerRadius: DesignTokens.Radius.sm,
            padding: EdgeInsets(
                top: DesignTokens.Spacing.sm,
                leading: DesignTokens.Spacing.sm,
                bottom: DesignTokens.Spacing.sm,
                trailing: DesignTokens.Spacing.sm
            ),
            showShadow: false
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                ConflictFileActionButton(
                    title: LumiPluginLocalization.string("Use Ours", bundle: .module),
                    systemImage: "arrow.left",
                    style: .ghost,
                    action: onUseOurs
                )
                ConflictFileActionButton(
                    title: LumiPluginLocalization.string("Use Theirs", bundle: .module),
                    systemImage: "arrow.right",
                    style: .ghost,
                    action: onUseTheirs
                )
                ConflictFileActionButton(
                    title: LumiPluginLocalization.string("Use Base", bundle: .module),
                    systemImage: "arrow.uturn.backward",
                    style: .ghost,
                    action: onUseBase
                )
                ConflictFileActionButton(
                    title: LumiPluginLocalization.string("Open in VS Code", bundle: .module),
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    style: .ghost,
                    action: onOpenInVSCode
                )
                AppDivider()
                ConflictFileActionButton(
                    title: LumiPluginLocalization.string("View Conflict Diff", bundle: .module),
                    systemImage: "doc.text.magnifyingglass",
                    style: .secondary,
                    action: onViewDiff
                )
            }
        }
        .frame(width: 220)
    }
}

private struct ConflictFileActionButton: View {
    enum Style {
        case ghost
        case secondary
    }

    let title: String
    let systemImage: String
    let style: Style
    let action: () -> Void

    @LumiTheme private var theme: LumiUITheme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: systemImage)
                    .frame(width: 16)
                Text(title)
                Spacer(minLength: 0)
            }
            .font(DesignTokens.Typography.caption1)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .stroke(theme.appSubtleBorder.opacity(isHovered ? 1 : 0), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
            .scaleEffect(
                isHovered && motionPreference.allowsMotion
                    ? LumiMotion.hoverScale
                    : 1
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            LumiMotion.animate(
                LumiMotion.enabled(LumiMotion.hover, preference: motionPreference)
            ) {
                isHovered = hovering
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .ghost:
            theme.primary
        case .secondary:
            theme.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .ghost:
            isHovered ? theme.appAccentSoftFill : .clear
        case .secondary:
            isHovered ? theme.appListRowHoverBackground : theme.appStatusMutedFill
        }
    }
}
