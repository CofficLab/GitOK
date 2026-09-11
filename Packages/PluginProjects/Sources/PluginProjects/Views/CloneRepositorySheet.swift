import AppKit
import LumiUI
import ProviderCloneRepository
import ProviderGit
import ProviderProjects
import ProviderToast
import SwiftUI

/// 克隆任务创建 sheet。
///
/// 这里仅收集并校验任务参数。点击 Clone 后任务立即交给
/// `CloneRepositoryProviding`，sheet 随即关闭；后台执行和进度展示由
/// `PluginCloneRepository` 负责。
struct CloneRepositorySheet: View {
    let projects: any ProjectProviding
    let toast: (any ToastProviding)?
    let git: any GitProviding
    let cloneRepository: any CloneRepositoryProviding
    @LumiTheme private var theme

    @Environment(\.dismiss) private var dismiss
    @State private var remoteURL = ""
    @State private var destinationFolder = FileManager.default.homeDirectoryForCurrentUser
    @State private var repositoryName = ""
    @State private var errorMessage: String?
    @State private var didManuallyEditName = false

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
        if trimmedRemoteURL.isEmpty { return "Enter a remote repository URL." }
        if trimmedName.isEmpty { return "Enter a repository name." }
        guard let destination = destinationURL else { return "Invalid destination path." }
        do {
            try git.validateCloneDestination(destination)
        } catch {
            return error.localizedDescription
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            remoteSection
            destinationSection
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
                Text("Clone Repository")
                    .font(.headline)
                Text("Clone a remote repository and add it to your projects.")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
    }

    private var remoteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Remote URL")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            AppInputField("https://github.com/owner/repo.git", text: $remoteURL)
        }
    }

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Destination")
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
                AppButton("Choose...", systemImage: "folder", style: .secondary, size: .small) {
                    chooseDestinationFolder()
                }
            }
            HStack(spacing: 6) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 44, alignment: .leading)
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
            if let validationMessage {
                Text(validationMessage)
                    .font(.caption2)
                    .foregroundStyle(theme.warning)
                    .lineLimit(2)
            }
            Spacer()
            AppButton("Cancel", style: .secondary, action: { dismiss() })
                .keyboardShortcut(.cancelAction)
            AppButton("Clone", systemImage: "arrow.down.circle", style: .primary, action: enqueueClone)
                .disabled(validationMessage != nil)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func chooseDestinationFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = destinationFolder
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            destinationFolder = url
        }
    }

    private func enqueueClone() {
        guard let destination = destinationURL, validationMessage == nil else { return }
        do {
            _ = try cloneRepository.enqueue(
                remoteURL: trimmedRemoteURL,
                destination: destination,
                repositoryName: trimmedName
            )
            // 先把目标路径登记到项目列表；目录由后台任务创建，用户随后
            // 点击这个项目即可进入克隆详情页。
            projects.addProject(at: destination)
            toast?.show("Clone started", detail: trimmedName, style: .info)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
