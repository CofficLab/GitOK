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
                            title: pluginLocalization.string("Checking conflicts…"),
                            message: pluginLocalization.string("Reading the current Git operation.")
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
                        // 正文区没有文件行可展示时才使用这里的圆形「继续」按钮；
                        // 正文区有文件行（含已解决/已暂存的文件）时，该入口位于顶部操作栏。
                        VStack(spacing: DesignTokens.Spacing.md) {
                            AppStatusBanner(
                                kind: .success,
                                title: pluginLocalization.string(viewModel.isCherryPicking ? "Cherry-pick is ready to continue" : "Merge ready to complete"),
                                message: pluginLocalization.string(viewModel.isCherryPicking
                                        ? "All conflicts are resolved. Continue the cherry-pick to finish it."
                                        : "All conflicts are resolved. Continue the merge to create the merge commit.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 120)

                            ContinueMergeCardButton(
                                title: pluginLocalization.string(viewModel.isCherryPicking ? "Continue Cherry-pick" : "Continue Merge"),
                                systemImage: "arrow.right.circle.fill",
                                isDisabled: !viewModel.isOperationInProgress || !viewModel.conflictedFiles.isEmpty || isActionRunning,
                                action: continueMerge
                            )
                        }
                        .frame(maxWidth: .infinity)
                    } else if viewModel.conflictedFiles.isEmpty {
                        AppEmptyState(
                            icon: "checkmark.circle",
                            title: pluginLocalization.string("No merge conflicts")
                        )
                        .frame(maxWidth: .infinity, minHeight: 120)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .alert(
            pluginLocalization.string(viewModel.isCherryPicking ? "Confirm Abort Cherry-pick?" : "Confirm Abort Merge?"),
            isPresented: $showAbortConfirmation
        ) {
            Button(pluginLocalization.string("Cancel"), role: .cancel) {}
            Button(
                pluginLocalization.string(viewModel.isCherryPicking ? "Abort Cherry-pick" : "Abort Merge"),
                role: .destructive
            ) {
                abortMerge()
            }
        } message: {
            Text(pluginLocalization.string(viewModel.isCherryPicking
                    ? "This discards the in-progress cherry-pick and restores the pre-cherry-pick state."
                    : "This discards the in-progress merge and restores the pre-merge state."))
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
                title: pluginLocalization.string("Conflict Resolution"),
                subtitle: headerSubtitle,
                iconColor: theme.warning,
                spacing: DesignTokens.Spacing.xs
            )
            Spacer(minLength: 0)
            if let onDismiss {
                AppCircularIconButton(
                    systemImage: "xmark",
                    accessibilityLabel: pluginLocalization.string("Close"),
                    size: 28,
                    action: onDismiss
                )
                .help(pluginLocalization.string("Close"))
            }
        }
    }

    private var headerSubtitle: String {
        if !viewModel.conflictedFiles.isEmpty {
            if !pendingStageFiles.isEmpty {
                if pendingStageFiles.count == viewModel.conflictedFiles.count {
                    return String(format: pluginLocalization.string("%lld resolved; stage to continue"), pendingStageFiles.count)
                }
                let unresolved = String(format: pluginLocalization.string("%lld conflicted file(s) remaining"), viewModel.conflictedFiles.count - pendingStageFiles.count)
                return unresolved + " · " + String(format: pluginLocalization.string("%lld resolved; stage to continue"), pendingStageFiles.count)
            }
            if !stagedResolvedFiles.isEmpty {
                let unresolved = String(format: pluginLocalization.string("%lld conflicted file(s) remaining"), viewModel.conflictedFiles.count)
                return unresolved + " · " + String(format: pluginLocalization.string("%lld staged"), stagedResolvedFiles.count)
            }
            return String(format: pluginLocalization.string("%lld conflicted file(s)"), viewModel.conflictedFiles.count)
        }
        if !pendingStageFiles.isEmpty {
            return String(format: pluginLocalization.string("%lld resolved; stage to continue"), viewModel.resolvedConflictFiles.count)
        }
        if !stagedResolvedFiles.isEmpty {
            return String(format: pluginLocalization.string("%lld resolved; ready to continue"), stagedResolvedFiles.count)
        }
        if viewModel.isOperationInProgress {
            return pluginLocalization.string(viewModel.isCherryPicking ? "Cherry-pick is ready to continue" : "Merge is ready to continue")
        }
        return pluginLocalization.string("No conflicted files")
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            if !pendingStageFiles.isEmpty {
                AppButton(
                    pluginLocalization.string("Stage Resolved Files"),
                    systemImage: "checkmark.circle",
                    style: .primary,
                    size: .small,
                    action: stageResolvedFiles
                )
                .disabled(isActionRunning)
            }

            if isActionRunning {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer(minLength: DesignTokens.Spacing.xl)

            if viewModel.showsToolbarContinueAction {
                AppButton(
                    pluginLocalization.string(viewModel.isCherryPicking ? "Continue Cherry-pick" : "Continue Merge"),
                    systemImage: "arrow.right.circle.fill",
                    // 还有文件待暂存时，「暂存已解决文件」是当前主操作，
                    // 继续入口退为次要样式，避免两个主按钮争夺注意力。
                    style: pendingStageFiles.isEmpty ? .primary : .secondary,
                    size: .small,
                    action: continueMerge
                )
                .disabled(!viewModel.conflictedFiles.isEmpty || isActionRunning)
            }

            AppButton(
                pluginLocalization.string(viewModel.isCherryPicking ? "Abort Cherry-pick" : "Abort Merge"),
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
                        ? pluginLocalization.string("Resolved; stage to continue")
                        : pluginLocalization.string("Staged"),
                    systemImage: viewModel.conflictedFiles.contains(file) ? "checkmark" : "checkmark.circle.fill",
                    style: .accent
                )
            }
            AppIconButton(systemImage: "doc.on.doc", label: pluginLocalization.string("Copy Path"), tint: theme.textSecondary) {
                copyText(file)
            }
            AppIconButton(systemImage: "folder", label: pluginLocalization.string("Reveal in Finder"), tint: theme.textSecondary) {
                reveal(file)
            }
            AppIconButton(systemImage: "ellipsis.circle", tint: theme.textSecondary) {
                moreActionsFile = moreActionsFile == file ? nil : file
            }
            .accessibilityLabel(pluginLocalization.string("More Actions"))
            .help(pluginLocalization.string("More Actions"))
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
            actionError = pluginLocalization.string(viewModel.isCherryPicking
                    ? "Resolve all conflicts before continuing the cherry-pick."
                    : "Resolve all conflicts before continuing the merge.")
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
                    title: pluginLocalization.string("Use Ours"),
                    systemImage: "arrow.left",
                    style: .ghost,
                    action: onUseOurs
                )
                ConflictFileActionButton(
                    title: pluginLocalization.string("Use Theirs"),
                    systemImage: "arrow.right",
                    style: .ghost,
                    action: onUseTheirs
                )
                ConflictFileActionButton(
                    title: pluginLocalization.string("Use Base"),
                    systemImage: "arrow.uturn.backward",
                    style: .ghost,
                    action: onUseBase
                )
                ConflictFileActionButton(
                    title: pluginLocalization.string("Open in VS Code"),
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    style: .ghost,
                    action: onOpenInVSCode
                )
                AppDivider()
                ConflictFileActionButton(
                    title: pluginLocalization.string("View Conflict Diff"),
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

/// 圆形「继续合并」按钮：绿色圆形按钮（内含箭头图标）+ 下方文字标签。
/// 只在弹层正文区没有文件行可展示时使用；正文区有文件行时改由顶部
/// 操作栏的「继续」按钮提供入口，避免同一屏出现两个相同入口。
private struct ContinueMergeCardButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    @LumiTheme private var theme: LumiUITheme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: isDisabled ? .clear : Color.black.opacity(0.16),
                            radius: 10,
                            x: 0,
                            y: 4
                        )

                    Image(systemName: systemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(foregroundColor)
                }

                Text(title)
                    .font(DesignTokens.Typography.callout.weight(.medium))
                    .foregroundStyle(titleColor)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .scaleEffect(
            isEffectivelyHovered && motionPreference.allowsMotion
                ? LumiMotion.hoverScale
                : 1
        )
        .onHover { hovering in
            LumiMotion.animate(
                LumiMotion.enabled(LumiMotion.hover, preference: motionPreference)
            ) {
                isHovered = hovering && !isDisabled
            }
        }
    }

    private var isEffectivelyHovered: Bool {
        isHovered && !isDisabled
    }

    private var foregroundColor: Color {
        isDisabled ? theme.primary.opacity(0.72) : .white
    }

    private var backgroundColor: Color {
        if isDisabled {
            return theme.primary.opacity(0.14)
        }
        return isEffectivelyHovered ? theme.primary.opacity(0.9) : theme.primary
    }

    private var titleColor: Color {
        isDisabled ? theme.primary.opacity(0.5) : theme.primary
    }
}
