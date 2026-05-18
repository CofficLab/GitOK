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
    @State private var cloneProgressMessage: String?
    @State private var didManuallyEditRepositoryName = false
    @State private var isAutoFillingRepositoryName = false
    @State private var credentialHost: String?
    @State private var credentialUsername = ""
    @State private var credentialToken = ""
    @State private var credentialErrorMessage: String?
    @State private var isSavingCredential = false
    @State private var showCredentialSheet = false
    @State private var showSSHHelpSheet = false
    @State private var sshHelpRemoteURL: String?
    @State private var sshHelpErrorMessage: String?
    @State private var githubHost = "github.com"
    @State private var githubUsername = ""
    @State private var githubToken = ""
    @State private var githubSearchText = ""
    @State private var githubRepositories: [GitHubCloneRepository] = []
    @State private var isLoadingGitHubRepositories = false
    @State private var githubErrorMessage: String?

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

    private var filteredGitHubRepositories: [GitHubCloneRepository] {
        let query = githubSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return githubRepositories }
        return githubRepositories.filter {
            $0.fullName.localizedCaseInsensitiveContains(query) ||
                $0.description?.localizedCaseInsensitiveContains(query) == true
        }
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
            githubAccountSection
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
        .sheet(isPresented: $showCredentialSheet) {
            credentialRetrySheet
        }
        .sheet(isPresented: $showSSHHelpSheet) {
            SSHAuthenticationHelpView(
                remoteURL: sshHelpRemoteURL,
                errorMessage: sshHelpErrorMessage
            ) {
                cloneRepository()
            }
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

    var githubAccountSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("github.com 或 ghe.example.com", text: $githubHost)
                        .textFieldStyle(.roundedBorder)

                    TextField("用户名", text: $githubUsername)
                        .textFieldStyle(.roundedBorder)
                }

                SecureField("Personal access token", text: $githubToken)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button {
                        loadGitHubRepositories()
                    } label: {
                        if isLoadingGitHubRepositories {
                            ProgressView()
                                .controlSize(.small)
                                .frame(minWidth: 110)
                        } else {
                            Text("连接并列出仓库")
                                .frame(minWidth: 110)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        isLoadingGitHubRepositories ||
                            githubHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            githubUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            githubToken.isEmpty
                    )

                    Button("创建 Token") {
                        openGitHubTokenSettings()
                    }
                    .buttonStyle(.borderless)

                    Spacer()
                }

                if let githubErrorMessage {
                    Text(githubErrorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .textSelection(.enabled)
                } else {
                    Text("Token 会通过当前 Git credential helper 保存，仓库列表来自 GitHub/GitHub Enterprise API。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if githubRepositories.isEmpty == false {
                    TextField("搜索仓库", text: $githubSearchText)
                        .textFieldStyle(.roundedBorder)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(filteredGitHubRepositories) { repository in
                                Button {
                                    selectGitHubRepository(repository)
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: repository.isPrivate ? "lock.fill" : "globe")
                                            .foregroundColor(repository.isPrivate ? .orange : .secondary)
                                            .frame(width: 16)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(repository.fullName)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(1)

                                            if let description = repository.description, description.isEmpty == false {
                                                Text(description)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.top, 8)
        } label: {
            Label("GitHub / Enterprise 账号 Clone", systemImage: "person.crop.circle.badge.plus")
                .font(.headline)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .textSelection(.enabled)

                    if credentialHost != nil {
                        Button("输入凭据并重试") {
                            showCredentialSheet = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if sshHelpRemoteURL != nil {
                        Button("查看 SSH 处理方式") {
                            showSSHHelpSheet = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else if isCloning, let cloneProgressMessage, cloneProgressMessage.isEmpty == false {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(cloneProgressMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
        }
    }

    var credentialRetrySheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label("需要 Git 凭据", systemImage: "key.fill")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("为 \(credentialHost ?? "远程服务器") 保存 HTTPS 凭据后，GitOK 会自动重试 clone。凭据会通过当前 Git credential helper 保存。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                TextField("用户名", text: $credentialUsername)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isSavingCredential)

                SecureField("Personal access token 或密码", text: $credentialToken)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isSavingCredential)

                if let credentialErrorMessage {
                    Text(credentialErrorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .textSelection(.enabled)
                }
            }

            HStack {
                Spacer()

                Button("取消") {
                    showCredentialSheet = false
                }
                .disabled(isSavingCredential)

                Button {
                    saveCredentialAndRetryClone()
                } label: {
                    if isSavingCredential {
                        ProgressView()
                            .controlSize(.small)
                            .frame(minWidth: 96)
                    } else {
                        Text("保存并重试")
                            .frame(minWidth: 96)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    isSavingCredential ||
                        credentialUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        credentialToken.isEmpty
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
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
        cloneProgressMessage = "准备克隆..."
        isCloning = true
        credentialHost = nil
        credentialErrorMessage = nil
        sshHelpRemoteURL = nil
        sshHelpErrorMessage = nil

        Task { @MainActor in
            data.activityStatus = "克隆中…"
        }

        let remote = normalizedRemoteURL
        let repositoryName = trimmedRepositoryName

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI.clone(remoteURL: remote, destinationURL: destinationURL) { progressLine in
                    Task { @MainActor in
                        cloneProgressMessage = progressLine
                        data.activityStatus = progressLine
                    }
                }

                await MainActor.run {
                    let project = data.addProject(url: destinationURL, using: projectRepo)
                    if let project {
                        vm.setProject(project, reason: "GitClone")
                        data.activityStatus = nil
                        isCloning = false
                        cloneProgressMessage = nil
                        alert_info("已克隆 \(repositoryName)")
                        dismiss()
                    } else {
                        data.activityStatus = nil
                        isCloning = false
                        cloneProgressMessage = nil
                        errorMessage = "仓库已克隆到本地，但导入项目列表失败：\(destinationURL.path)"
                    }
                }
            } catch {
                await MainActor.run {
                    data.activityStatus = nil
                    isCloning = false
                    cloneProgressMessage = nil
                    errorMessage = error.localizedDescription
                    prepareCredentialRetryIfNeeded(for: remote, error: error)
                }
            }
        }
    }

    func prepareCredentialRetryIfNeeded(for remote: String, error: Error) {
        let failureDescription = CloneRepositoryValidation.cloneFailureDescription(from: error.localizedDescription)

        if failureDescription.kind == .sshAuthentication || failureDescription.kind == .sshHostKey {
            credentialHost = nil
            sshHelpRemoteURL = remote
            sshHelpErrorMessage = error.localizedDescription
            showSSHHelpSheet = true
            return
        }

        guard failureDescription.kind == .authentication,
              let host = CloneRepositoryValidation.credentialHost(from: remote) else {
            credentialHost = nil
            sshHelpRemoteURL = nil
            sshHelpErrorMessage = nil
            return
        }

        credentialHost = host
        sshHelpRemoteURL = nil
        sshHelpErrorMessage = nil
        showCredentialSheet = true
    }

    func saveCredentialAndRetryClone() {
        guard let credentialHost else { return }

        credentialErrorMessage = nil
        isSavingCredential = true

        let username = credentialUsername
        let token = credentialToken

        Task.detached(priority: .userInitiated) {
            do {
                try GitRepositoryCLI.approveCredential(
                    host: credentialHost,
                    username: username,
                    password: token
                )

                await MainActor.run {
                    isSavingCredential = false
                    showCredentialSheet = false
                    credentialToken = ""
                    cloneRepository()
                }
            } catch {
                await MainActor.run {
                    isSavingCredential = false
                    credentialErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func loadGitHubRepositories() {
        let host = normalizedGitHubHost(githubHost)
        let username = githubUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = githubToken

        guard host.isEmpty == false, username.isEmpty == false, token.isEmpty == false else { return }

        isLoadingGitHubRepositories = true
        githubErrorMessage = nil

        Task.detached(priority: .userInitiated) {
            do {
                let repositories = try await GitHubCloneAPI.repositories(host: host, token: token)
                try GitRepositoryCLI.approveCredential(
                    host: host,
                    username: username,
                    password: token
                )

                await MainActor.run {
                    githubHost = host
                    githubRepositories = repositories
                    isLoadingGitHubRepositories = false
                    githubToken = ""
                    githubErrorMessage = repositories.isEmpty ? "未找到可访问仓库。请确认 token 权限包含 repo/read:org 或对应 Enterprise 权限。" : nil
                }
            } catch {
                await MainActor.run {
                    isLoadingGitHubRepositories = false
                    githubErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func selectGitHubRepository(_ repository: GitHubCloneRepository) {
        remoteURL = repository.cloneURL
        didManuallyEditRepositoryName = false
        autoFillRepositoryName(from: repository.cloneURL)
    }

    func openGitHubTokenSettings() {
        let host = normalizedGitHubHost(githubHost)
        let urlString = host == "github.com"
            ? "https://github.com/settings/tokens"
            : "https://\(host)/settings/tokens"

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    func normalizedGitHubHost(_ value: String) -> String {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        return trimmed.split(separator: "/").first.map(String.init) ?? trimmed
    }
}

private struct GitHubCloneRepository: Identifiable, Decodable, Sendable {
    let id: Int
    let fullName: String
    let cloneURL: String
    let description: String?
    let isPrivate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case cloneURL = "clone_url"
        case description
        case isPrivate = "private"
    }
}

private enum GitHubCloneAPI {
    static func repositories(host: String, token: String) async throws -> [GitHubCloneRepository] {
        var components = URLComponents(string: apiBaseURL(host: host).appendingPathComponent("user/repos").absoluteString)
        components?.queryItems = [
            URLQueryItem(name: "per_page", value: "100"),
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "affiliation", value: "owner,collaborator,organization_member"),
        ]

        guard let url = components?.url else {
            throw NSError(domain: "GitOK.GitHubClone", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "GitHub API 地址无效"
            ])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("GitOK", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GitOK.GitHubClone", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "GitHub API 没有返回有效响应"
            ])
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "GitOK.GitHubClone", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: apiErrorMessage(statusCode: httpResponse.statusCode, data: data)
            ])
        }

        return try JSONDecoder().decode([GitHubCloneRepository].self, from: data)
    }

    private static func apiBaseURL(host: String) -> URL {
        if host == "github.com" {
            return URL(string: "https://api.github.com")!
        }
        return URL(string: "https://\(host)/api/v3")!
    }

    private static func apiErrorMessage(statusCode: Int, data: Data) -> String {
        if let payload = try? JSONDecoder().decode(GitHubAPIError.self, from: data) {
            return "GitHub API 请求失败 (\(statusCode)): \(payload.message)"
        }
        return "GitHub API 请求失败 (\(statusCode))"
    }

    private struct GitHubAPIError: Decodable {
        let message: String
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
