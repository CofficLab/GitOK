import AppKit
import GitCoreKit
import MagicAlert
import MagicKit
import SwiftUI

struct CloneRepositorySheet: View, SuperLog {
    nonisolated static let emoji = "📦"
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @Environment(\.dismiss) private var dismiss

    @State private var remoteURL = ""
    @State private var destinationFolder = FileManager.default.homeDirectoryForCurrentUser
    @State private var repositoryName = ""
    @State private var isCloning = false
    @State private var errorMessage: String?
    @State private var didManuallyEditRepositoryName = false
    @State private var isAutoFillingRepositoryName = false

    private var trimmedRemoteURL: String {
        remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedRepositoryName: String {
        repositoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var destinationURL: URL? {
        guard trimmedRepositoryName.isEmpty == false else { return nil }
        return destinationFolder.appendingPathComponent(trimmedRepositoryName, isDirectory: true)
    }

    private var normalizedRemoteURL: String {
        CloneRepositoryValidation.normalizedRemoteURL(from: remoteURL)
    }

    private var destinationState: CloneRepositoryValidation.DestinationState? {
        guard let destinationURL else { return nil }
        let projectExists = data.repoManager.projectRepo.exists(path: destinationURL.path)
        return CloneRepositoryValidation.destinationState(for: destinationURL, projectExists: projectExists)
    }

    private var validationMessage: String? {
        if trimmedRemoteURL.isEmpty {
            return "请输入远程仓库地址"
        }

        if let repositoryNameMessage = CloneRepositoryValidation.validateRepositoryName(trimmedRepositoryName) {
            return repositoryNameMessage
        }

        guard destinationURL != nil else {
            return "目标路径无效"
        }

        if let destinationState {
            return CloneRepositoryValidation.destinationValidationMessage(for: destinationState)
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            remoteSection
            destinationSection
            statusSection
            footer
        }
        .padding(24)
        .frame(width: 560)
        .onChange(of: remoteURL) { _, newValue in
            autoFillRepositoryName(from: newValue)
        }
    }
}

private extension CloneRepositorySheet {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("克隆仓库")
                .font(.title2)
                .fontWeight(.semibold)

            Text("从远程地址克隆一个 Git 仓库，并自动导入到项目列表。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    var remoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("远程仓库")
                .font(.headline)

            TextField("https://github.com/owner/repo.git", text: $remoteURL)
                .textFieldStyle(.roundedBorder)

            TextField("仓库名称", text: $repositoryName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: repositoryName) { oldValue, newValue in
                    defer { isAutoFillingRepositoryName = false }
                    if oldValue != newValue {
                        guard isAutoFillingRepositoryName == false else { return }
                        didManuallyEditRepositoryName = true
                    }
                }

            if normalizedRemoteURL != trimmedRemoteURL, trimmedRemoteURL.isEmpty == false {
                Text("将使用：\(normalizedRemoteURL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    var destinationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("本地路径")
                .font(.headline)

            HStack {
                Text(destinationFolder.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("选择目录") {
                    chooseDestinationFolder()
                }
            }

            if let destinationURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最终路径")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(destinationURL.path)
                        .font(.caption.monospaced())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            if destinationState == .existingEmptyDirectory {
                Text("目标目录已存在但为空，允许直接克隆到该目录。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("准备克隆")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage, errorMessage.isEmpty == false {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    var footer: some View {
        HStack {
            Spacer()

            Button("取消") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .disabled(isCloning)

            Button {
                cloneRepository()
            } label: {
                if isCloning {
                    ProgressView()
                        .controlSize(.small)
                        .frame(minWidth: 80)
                } else {
                    Text("克隆")
                        .frame(minWidth: 80)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCloning || validationMessage != nil)
            .keyboardShortcut(.defaultAction)
        }
    }

    func chooseDestinationFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            destinationFolder = url
        }
    }

    func autoFillRepositoryName(from remote: String) {
        let trimmed = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        guard didManuallyEditRepositoryName == false || repositoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if let sanitized = CloneRepositoryValidation.inferredRepositoryName(from: trimmed), sanitized.isEmpty == false {
            isAutoFillingRepositoryName = true
            repositoryName = sanitized
        }
    }

    func cloneRepository() {
        guard let destinationURL, let projectRepo = Optional(data.repoManager.projectRepo) else { return }

        errorMessage = nil
        isCloning = true

        Task { @MainActor in
            data.activityStatus = "克隆中…"
        }

        let remote = normalizedRemoteURL
        let repositoryName = trimmedRepositoryName

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI.clone(remoteURL: remote, destinationURL: destinationURL)

                await MainActor.run {
                    let project = data.addProject(url: destinationURL, using: projectRepo)
                    if let project {
                        vm.setProject(project, reason: "GitClone")
                        data.activityStatus = nil
                        isCloning = false
                        alert_info("已克隆 \(repositoryName)")
                        dismiss()
                    } else {
                        data.activityStatus = nil
                        isCloning = false
                        errorMessage = "仓库已克隆到本地，但导入项目列表失败：\(destinationURL.path)"
                    }
                }
            } catch {
                await MainActor.run {
                    data.activityStatus = nil
                    isCloning = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}
