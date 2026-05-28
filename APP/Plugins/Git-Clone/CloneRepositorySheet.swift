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
            return String(localized: "Please enter a remote repository URL", table: "Git-Clone")
        }

        if let repositoryNameMessage = CloneRepositoryValidation.validateRepositoryName(trimmedRepositoryName) {
            return repositoryNameMessage
        }

        guard destinationURL != nil else {
            return String(localized: "Invalid destination path", table: "Git-Clone")
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
            Text("Clone Repository", tableName: "Git-Clone")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Clone a Git repository from a remote URL and automatically add it to the project list.", tableName: "Git-Clone")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    var remoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Remote Repository", tableName: "Git-Clone")
                .font(.headline)

            TextField("https://github.com/owner/repo.git", text: $remoteURL)
                .textFieldStyle(.roundedBorder)

            Text("Repository Name", tableName: "Git-Clone")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(String(localized: "Repository Name", table: "Git-Clone"), text: $repositoryName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: repositoryName) { oldValue, newValue in
                    defer { isAutoFillingRepositoryName = false }
                    if oldValue != newValue {
                        guard isAutoFillingRepositoryName == false else { return }
                        didManuallyEditRepositoryName = true
                    }
                }

            if normalizedRemoteURL != trimmedRemoteURL, trimmedRemoteURL.isEmpty == false {
                Text("Will use: \(normalizedRemoteURL)", tableName: "Git-Clone")
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
                    TextField(String(localized: "github.com or ghe.example.com", table: "Git-Clone"), text: $githubHost)
                        .textFieldStyle(.roundedBorder)

                    TextField(String(localized: "Username", table: "Git-Clone"), text: $githubUsername)
                        .textFieldStyle(.roundedBorder)
                }

                SecureField(String(localized: "Personal Access Token", table: "Git-Clone"), text: $githubToken)
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
                            Text("Connect and List Repositories", tableName: "Git-Clone")
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

                    Button(String(localized: "Create Token", table: "Git-Clone")) {
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
                    Text("Token will be saved via the current Git credential helper. Repository list comes from GitHub/GitHub Enterprise API.", tableName: "Git-Clone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if githubRepositories.isEmpty == false {
                    TextField(String(localized: "Search Repositories", table: "Git-Clone"), text: $githubSearchText)
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
            Label(String(localized: "GitHub / Enterprise Account Clone", table: "Git-Clone"), systemImage: "person.crop.circle.badge.plus")
                .font(.headline)
        }
    }

    var destinationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Local Path", tableName: "Git-Clone")
                .font(.headline)

            HStack {
                Text(destinationFolder.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(String(localized: "Choose Directory", table: "Git-Clone")) {
                    chooseDestinationFolder()
                }
            }

            if let destinationURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Final Path", tableName: "Git-Clone")
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
                Text("Target directory exists but is empty. Cloning directly into it is allowed.", tableName: "Git-Clone")
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
                Text("Ready to Clone", tableName: "Git-Clone")
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
                        Button(String(localized: "Enter Credentials and Retry", table: "Git-Clone")) {
                            showCredentialSheet = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if sshHelpRemoteURL != nil {
                        Button(String(localized: "View SSH Handling", table: "Git-Clone")) {
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
                Label(String(localized: "Git Credentials Required", table: "Git-Clone"), systemImage: "key.fill")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(String(localized: "After saving HTTPS credentials for %@, GitOK will automatically retry the clone. Credentials will be saved via the current Git credential helper.", table: "Git-Clone", comment: "Credential sheet description").replacingOccurrences(of: "%@", with: credentialHost ?? String(localized: "remote server", table: "Git-Clone")))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                TextField(String(localized: "Username", table: "Git-Clone"), text: $credentialUsername)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isSavingCredential)

                SecureField(String(localized: "Personal Access Token or Password", table: "Git-Clone"), text: $credentialToken)
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

                Button(String(localized: "Cancel", table: "Git-Clone")) {
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
                        Text("Save and Retry", tableName: "Git-Clone")
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

            Button(String(localized: "Cancel", table: "Git-Clone")) {
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
                    Text("Clone", tableName: "Git-Clone")
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
        cloneProgressMessage = String(localized: "Ready to Clone", table: "Git-Clone")
        isCloning = true
        credentialHost = nil
        credentialErrorMessage = nil
        sshHelpRemoteURL = nil
        sshHelpErrorMessage = nil

        Task { @MainActor in
            data.activityStatus = String(localized: "Cloning...", table: "Git-Clone")
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
                        alert_info(String(localized: "Cloned %@", table: "Git-Clone", comment: "Success message after cloning a repository").replacingOccurrences(of: "%@", with: repositoryName))
                        dismiss()
                    } else {
                        data.activityStatus = nil
                        isCloning = false
                        cloneProgressMessage = nil
                        errorMessage = String(localized: "Repository cloned locally, but failed to add to project list: %@", table: "Git-Clone").replacingOccurrences(of: "%@", with: destinationURL.path)
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
                    githubErrorMessage = repositories.isEmpty ? String(localized: "No accessible repositories found. Please verify that the token permissions include repo/read:org or corresponding Enterprise permissions.", table: "Git-Clone") : nil
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
                NSLocalizedDescriptionKey: String(localized: "GitHub API URL is invalid", table: "Git-Clone")
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
                NSLocalizedDescriptionKey: String(localized: "GitHub API did not return a valid response", table: "Git-Clone")
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
            return String(localized: "GitHub API request failed (\(statusCode)): \(payload.message)", table: "Git-Clone")
        }
        return String(localized: "GitHub API request failed (\(statusCode))", table: "Git-Clone")
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
