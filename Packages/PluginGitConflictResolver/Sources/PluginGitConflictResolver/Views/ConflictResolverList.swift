import AppKit
import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// 冲突文件列表：展示合并中的冲突文件，可复制路径或定位到 Finder。
public struct ConflictResolverList: View {
    let projects: any ProjectProviding
    @ObservedObject private var viewModel: GitConflictResolverViewModel
    private let onDismiss: (() -> Void)?
    @State private var conflictDiff: String?
    @State private var isActionRunning = false
    @State private var actionError: String?
    @State private var showAbortConfirmation = false

    public init(
        projects: any ProjectProviding,
        viewModel: GitConflictResolverViewModel,
        onDismiss: (() -> Void)? = nil
    ) {
        self.projects = projects
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            actionBar
            if let actionError {
                Text(actionError)
                    .font(.caption)
                    .foregroundStyle(theme.warning)
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.isLoading {
                        ProgressView(LumiPluginLocalization.string("Checking conflicts…", bundle: .module))
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else if viewModel.conflictedFiles.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(theme.success)
                            Text(LumiPluginLocalization.string("No merge conflicts", bundle: .module))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(viewModel.conflictedFiles, id: \.self) { file in
                            conflictRow(file)
                        }
                    }
                }
            }
        }
        .padding(16)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(LumiPluginLocalization.string("Conflict Resolution", bundle: .module))
                    .font(.headline)
                Text(viewModel.conflictedFiles.isEmpty ? LumiPluginLocalization.string("No conflicted files", bundle: .module) : String(format: LumiPluginLocalization.string("%lld conflicted file(s)", bundle: .module), viewModel.conflictedFiles.count))
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer(minLength: 0)
            if let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(theme.textSecondary)
                .help(LumiPluginLocalization.string("Close", bundle: .module))
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            Button {
                continueMerge()
            } label: {
                Label(
                    LumiPluginLocalization.string(
                        viewModel.isCherryPicking ? "Continue Cherry-pick" : "Continue Merge",
                        bundle: .module
                    ),
                    systemImage: "arrow.right.circle"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isOperationInProgress || !viewModel.conflictedFiles.isEmpty || isActionRunning)

            Button(role: .destructive) {
                showAbortConfirmation = true
            } label: {
                Label(
                    LumiPluginLocalization.string(
                        viewModel.isCherryPicking ? "Abort Cherry-pick" : "Abort Merge",
                        bundle: .module
                    ),
                    systemImage: "xmark.circle"
                )
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.isOperationInProgress || isActionRunning)

            if isActionRunning {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func conflictRow(_ file: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(theme.warning)
            Text(file)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            AppIconButton(systemImage: "doc.on.doc", label: LumiPluginLocalization.string("Copy Path", bundle: .module), tint: theme.textSecondary) {
                copyText(file)
            }
            AppIconButton(systemImage: "folder", label: LumiPluginLocalization.string("Reveal in Finder", bundle: .module), tint: theme.textSecondary) {
                reveal(file)
            }
            Menu {
                Button {
                    checkout(file, version: .ours)
                } label: {
                    Label(
                        LumiPluginLocalization.string("Use Ours", bundle: .module),
                        systemImage: "arrow.left"
                    )
                }
                Button {
                    checkout(file, version: .theirs)
                } label: {
                    Label(
                        LumiPluginLocalization.string("Use Theirs", bundle: .module),
                        systemImage: "arrow.right"
                    )
                }
                Button {
                    checkout(file, version: .base)
                } label: {
                    Label(
                        LumiPluginLocalization.string("Use Base", bundle: .module),
                        systemImage: "arrow.uturn.backward"
                    )
                }
                Divider()
                Button {
                    showDiff(file)
                } label: {
                    Label(
                        LumiPluginLocalization.string("View Conflict Diff", bundle: .module),
                        systemImage: "doc.text.magnifyingglass"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .disabled(isActionRunning)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func checkout(_ file: String, version: GitMergeFileVersion) {
        guard let url = projects.currentProject?.url else { return }
        isActionRunning = true
        actionError = nil
        Task.detached(priority: .userInitiated) {
            do {
                try GitMergeOperation.checkoutMergeFileVersion(path: file, version: version, in: url)
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
                    _ = try GitCherryPickOperation.continueCherryPick(in: url)
                } else {
                    _ = try GitMergeOperation.continueMerge(in: url)
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
                    _ = try GitCherryPickOperation.abortCherryPick(in: url)
                } else {
                    _ = try GitMergeOperation.abortMerge(in: url)
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
                let diff = try GitMergeOperation.mergeFileDiff(path: file, in: url)
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

    @LumiTheme private var theme: LumiUITheme
}
