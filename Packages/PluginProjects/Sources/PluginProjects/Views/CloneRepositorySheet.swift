import AppKit
import KitGit
import LumiUI
import ProviderActivity
import ProviderGit
import ProviderProjects
import ProviderToast
import SwiftUI

/// 克隆仓库 sheet。
///
/// 输入远程仓库 URL → 自动填充仓库名 → 选择目标目录 → 校验 → 克隆；
/// 成功后打开项目并提示。克隆入口由项目侧边栏统一提供。
struct CloneRepositorySheet: View {
    let projects: any ProjectProviding
    let activity: (any ActivityProviding)?
    let toast: (any ToastProviding)?
    let git: any GitProviding
    @LumiTheme private var theme

    @Environment(\.dismiss) private var dismiss

    @State private var remoteURL = ""
    @State private var destinationFolder = FileManager.default.homeDirectoryForCurrentUser
    @State private var repositoryName = ""
    @State private var isCloning = false
    @State private var isCancelling = false
    @State private var cloneProgress: GitCloneProgress?
    @State private var cloneCancellation: GitProcessCancellation?
    @State private var errorMessage: String?
    @State private var didManuallyEditName = false

    init(
        projects: any ProjectProviding,
        activity: (any ActivityProviding)?,
        toast: (any ToastProviding)?,
        git: any GitProviding
    ) {
        self.projects = projects
        self.activity = activity
        self.toast = toast
        self.git = git
    }

    private var trimmedRemoteURL: String {
        remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedName: String {
        repositoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var destinationURL: URL? {
        guard !trimmedName.isEmpty else { return nil }
        return destinationFolder.appendingPathComponent(trimmedName, isDirectory: true)
    }

    private var validationMessage: String? {
        if trimmedRemoteURL.isEmpty {
            return LumiPluginLocalization.string("Enter a remote repository URL.", bundle: .module)
        }
        if trimmedName.isEmpty {
            return LumiPluginLocalization.string("Enter a repository name.", bundle: .module)
        }
        guard let destination = destinationURL else {
            return LumiPluginLocalization.string("Invalid destination path.", bundle: .module)
        }
        do {
            try git.validateCloneDestination(destination)
        } catch {
            return error.localizedDescription
        }
        // 项目列表中可能保留着一个已从磁盘删除的路径，也可能对应一个
        // 完全空的目录。这两种情况都可以安全地重新克隆；克隆成功后
        // `openProject(at:)` 会复用已有项目记录，不会产生重复项。
        return nil
    }

    private var canClone: Bool {
        !isCloning && validationMessage == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            remoteSection
                .disabled(isCloning)
            destinationSection
                .disabled(isCloning)
            if isCloning {
                cloneProgressSection
            }
            if let errorMessage {
                AppErrorBanner(message: LocalizedStringKey(errorMessage))
            }
            footer
        }
        .padding(24)
        .frame(width: 540)
        .onChange(of: remoteURL) { _, newValue in
            guard !didManuallyEditName else { return }
            repositoryName = git.defaultRepositoryName(from: newValue) ?? ""
        }
        .onChange(of: repositoryName) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let autoName = git.defaultRepositoryName(from: remoteURL)
            didManuallyEditName = (autoName != trimmed)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 18))
                .foregroundStyle(theme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(LumiPluginLocalization.string("Clone Repository", bundle: .module))
                    .font(.headline)
                Text(LumiPluginLocalization.string("Clone a remote repository and add it to your projects.", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
    }

    private var remoteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LumiPluginLocalization.string("Remote URL", bundle: .module))
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            AppInputField("https://github.com/owner/repo.git", text: $remoteURL)
        }
    }

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LumiPluginLocalization.string("Destination", bundle: .module))
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            HStack(spacing: 8) {
                Text(destinationFolder.path)
                    .font(.appCaption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.textSecondary.opacity(0.08))
                    )
                AppButton(LumiPluginLocalization.string("Choose...", bundle: .module), systemImage: "folder", style: .secondary, size: .small) {
                    chooseDestinationFolder()
                }
            }
            HStack(spacing: 6) {
                Text(LumiPluginLocalization.string("Name", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 34, alignment: .leading)
                AppInputField("repository-name", text: $repositoryName)
            }
            if let destination = destinationURL {
                Text(destination.path)
                    .font(.caption2)
                    .foregroundStyle(theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var footer: some View {
        HStack {
            if let validationMessage, !isCloning {
                Text(validationMessage)
                    .font(.caption2)
                    .foregroundStyle(theme.warning)
                    .lineLimit(2)
            }
            Spacer()
            if isCloning {
                AppButton(LumiPluginLocalization.string("Cancel", bundle: .module), style: .secondary, action: cancelClone)
                    .disabled(isCancelling)
                    .keyboardShortcut(.cancelAction)
                ProgressView()
                    .controlSize(.small)
            } else {
                AppButton(LumiPluginLocalization.string("Cancel", bundle: .module), style: .secondary, action: { dismiss() })
                    .keyboardShortcut(.cancelAction)
                AppButton(LumiPluginLocalization.string("Clone", bundle: .module), systemImage: "arrow.down.circle", style: .primary, action: {
                    Task { await clone() }
                })
                .disabled(!canClone)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var cloneProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(theme.primary)
                Text(progressDetail)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                if let fraction = cloneProgress?.fractionCompleted {
                    Text("\(Int(fraction * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(theme.textSecondary)
                }
            }

            if let fraction = cloneProgress?.fractionCompleted {
                ProgressView(value: fraction)
            } else {
                ProgressView()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.textSecondary.opacity(0.08))
        )
    }

    private var progressDetail: String {
        if isCancelling {
            return LumiPluginLocalization.string("Cancelling clone...", bundle: .module)
        }
        if let detail = cloneProgress?.detail, !detail.isEmpty {
            return detail
        }
        return String(format: LumiPluginLocalization.string("Cloning %@...", bundle: .module), trimmedName)
    }

    private func chooseDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = destinationFolder
        panel.prompt = LumiPluginLocalization.string("Choose", bundle: .module)
        if panel.runModal() == .OK, let url = panel.url {
            destinationFolder = url
        }
    }

    private func cancelClone() {
        guard isCloning, !isCancelling else { return }
        isCancelling = true
        activity?.setActivity(LumiPluginLocalization.string("Cancelling clone...", bundle: .module))
        cloneCancellation?.cancel()
    }

    private func clone() async {
        guard let destination = destinationURL else { return }
        let remote = trimmedRemoteURL
        let name = trimmedName
        let initialActivity = String(format: LumiPluginLocalization.string("Cloning %@...", bundle: .module), name)
        let destinationExistedBeforeClone = FileManager.default.fileExists(atPath: destination.path)
        let cancellation = GitProcessCancellation()

        await MainActor.run {
            errorMessage = nil
            isCancelling = false
            cloneProgress = nil
            cloneCancellation = cancellation
            isCloning = true
            activity?.setActivity(initialActivity)
        }

        let (progressStream, continuation) = AsyncStream<GitCloneProgress>.makeStream()
        let cloneGit = git
        let cloneTask = Task.detached(priority: .userInitiated) {
            defer { continuation.finish() }
            return try cloneGit.clone(
                remoteURL: remote,
                destination: destination,
                progress: { progress in
                    continuation.yield(progress)
                },
                cancellation: cancellation
            )
        }

        do {
            for await progress in progressStream {
                await MainActor.run {
                    cloneProgress = progress
                    activity?.setActivity(progress.detail ?? initialActivity)
                }
            }
            _ = try await cloneTask.value
            await MainActor.run {
                isCloning = false
                isCancelling = false
                cloneCancellation = nil
                activity?.clearActivity()
                projects.openProject(at: destination)
                toast?.show("Cloned", detail: name, style: .success)
                dismiss()
            }
        } catch is CancellationError {
            await MainActor.run {
                cleanupCancelledClone(at: destination, existedBefore: destinationExistedBeforeClone)
                isCloning = false
                isCancelling = false
                cloneCancellation = nil
                activity?.clearActivity()
                toast?.show(
                    LumiPluginLocalization.string("Clone canceled", bundle: .module),
                    detail: name,
                    style: .info
                )
                dismiss()
            }
        } catch {
            await MainActor.run {
                isCloning = false
                isCancelling = false
                cloneCancellation = nil
                activity?.clearActivity()
                errorMessage = String(format: LumiPluginLocalization.string("Clone failed: %@", bundle: .module), error.localizedDescription)
            }
        }
    }

    private func cleanupCancelledClone(at destination: URL, existedBefore: Bool) {
        guard FileManager.default.fileExists(atPath: destination.path) else { return }

        if existedBefore {
            try? FileManager.default.removeItem(at: destination)
            try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        } else {
            try? FileManager.default.removeItem(at: destination)
        }
    }
}
