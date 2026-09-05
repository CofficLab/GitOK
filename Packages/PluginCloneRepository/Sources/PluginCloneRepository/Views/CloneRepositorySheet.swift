import AppKit
import KitGit
import LumiUI
import ProviderActivity
import ProviderProjects
import ProviderToast
import SwiftUI

/// 克隆仓库 sheet（对齐旧版 CloneRepositorySheet 的核心流程）。
///
/// 输入远程仓库 URL → 自动填充仓库名 → 选择目标目录 → 校验 → 克隆；
/// 成功后打开项目并提示。省略旧版的 GitHub 账号 / SSH / 搜索等重量级能力。
public struct CloneRepositorySheet: View {
    let projects: any ProjectProviding
    let activity: (any ActivityProviding)?
    let toast: (any ToastProviding)?
    @LumiTheme private var theme

    @Environment(\.dismiss) private var dismiss

    @State private var remoteURL = ""
    @State private var destinationFolder = FileManager.default.homeDirectoryForCurrentUser
    @State private var repositoryName = ""
    @State private var isCloning = false
    @State private var errorMessage: String?
    @State private var didManuallyEditName = false

    public init(
        projects: any ProjectProviding,
        activity: (any ActivityProviding)?,
        toast: (any ToastProviding)?
    ) {
        self.projects = projects
        self.activity = activity
        self.toast = toast
    }

    // MARK: - Derived State

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
            try GitCloneOperation.validateDestination(destination)
        } catch {
            return error.localizedDescription
        }
        if projects.projects.contains(where: { $0.url == destination }) {
            return LumiPluginLocalization.string("This repository is already in your projects.", bundle: .module)
        }
        return nil
    }

    private var canClone: Bool {
        !isCloning && validationMessage == nil
    }

    // MARK: - Body

    public var body: some View {
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
            repositoryName = GitCloneOperation.defaultRepositoryName(from: newValue) ?? ""
        }
        .onChange(of: repositoryName) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let autoName = GitCloneOperation.defaultRepositoryName(from: remoteURL)
            didManuallyEditName = (autoName != trimmed)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 18))
                .foregroundStyle(theme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(LumiPluginLocalization.string("Clone Repository", bundle: .module))
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
            Text(LumiPluginLocalization.string("Remote URL", bundle: .module))
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
            AppButton("Cancel", style: .secondary, action: { dismiss() })
                .keyboardShortcut(.cancelAction)
            if isCloning {
                ProgressView()
                    .controlSize(.small)
            } else {
                AppButton("Clone", systemImage: "arrow.down.circle", style: .primary, action: {
                    Task { await clone() }
                })
                .disabled(!canClone)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Actions

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

    private func clone() async {
        guard let destination = destinationURL else { return }
        errorMessage = nil
        isCloning = true
        activity?.setActivity(String(format: LumiPluginLocalization.string("Cloning %@...", bundle: .module), trimmedName))

        // 捕获脱离主 actor 使用的值。
        let remote = trimmedRemoteURL

        do {
            try await Task.detached(priority: .userInitiated) {
                _ = try GitCloneOperation.clone(remoteURL: remote, destination: destination)
            }.value
            await MainActor.run {
                isCloning = false
                activity?.clearActivity()
                projects.openProject(at: destination)
                toast?.show("Cloned", detail: trimmedName, style: .success)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isCloning = false
                activity?.clearActivity()
                errorMessage = String(format: LumiPluginLocalization.string("Clone failed: %@", bundle: .module), error.localizedDescription)
            }
        }
    }
}
