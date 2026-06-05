import Foundation
import Clibgit2
import LibGit2Swift

public enum CloneRepositoryValidation {
    public enum CloneFailureKind: Equatable, Sendable {
        case authentication
        case sshAuthentication
        case sshHostKey
        case proxy
        case certificate
        case repositoryUnavailable
        case network
        case destination
        case unknown
    }

    public struct CloneFailureDescription: Equatable, Sendable {
        public let kind: CloneFailureKind
        public let title: String
        public let recoverySuggestion: String

        public init(kind: CloneFailureKind, title: String, recoverySuggestion: String) {
            self.kind = kind
            self.title = title
            self.recoverySuggestion = recoverySuggestion
        }
    }

    public struct NetworkConfiguration: Equatable, Sendable {
        public var httpProxy: String
        public var httpsProxy: String
        public var sslVerify: Bool
        public var sslCAInfo: String

        public init(
            httpProxy: String = "",
            httpsProxy: String = "",
            sslVerify: Bool = true,
            sslCAInfo: String = ""
        ) {
            self.httpProxy = httpProxy
            self.httpsProxy = httpsProxy
            self.sslVerify = sslVerify
            self.sslCAInfo = sslCAInfo
        }
    }

    public enum DestinationState: Equatable, Sendable {
        case available
        case existingEmptyDirectory
        case existingProject
        case existingNonEmptyDirectory
        case existingFile
    }

    public static func normalizedRemoteURL(from rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard looksLikeGitHubShortcut(trimmed) else {
            return trimmed
        }

        return "https://github.com/\(trimmed).git"
    }

    public static func inferredRepositoryName(from remote: String) -> String? {
        let normalized = normalizedRemoteURL(from: remote)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard normalized.isEmpty == false else { return nil }

        let candidate = normalized
            .split(separator: "/")
            .last
            .map(String.init)?
            .replacingOccurrences(of: ".git", with: "")

        guard let candidate else { return nil }
        return sanitizeRepositoryName(candidate)
    }

    public static func credentialHost(from remote: String) -> String? {
        let normalized = normalizedRemoteURL(from: remote)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let components = URLComponents(string: normalized),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host,
              host.isEmpty == false else {
            return nil
        }

        return host
    }

    public static func sshHost(from remote: String) -> String? {
        let normalized = normalizedRemoteURL(from: remote)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.isEmpty == false else { return nil }

        if let components = URLComponents(string: normalized),
           components.scheme?.lowercased() == "ssh",
           let host = components.host,
           host.isEmpty == false {
            return host
        }

        let pattern = #"^[^@/\s]+@([^:\s]+):.+$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              let range = Range(match.range(at: 1), in: normalized) else {
            return nil
        }

        return String(normalized[range])
    }

    public static func sanitizeRepositoryName(_ rawValue: String) -> String {
        rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "\\", with: "")
    }

    public static func validateRepositoryName(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "请输入仓库名称"
        }

        if trimmed == "." || trimmed == ".." {
            return "仓库名称不能为 . 或 .."
        }

        let invalidCharacters = CharacterSet(charactersIn: "/:\\")
        if trimmed.rangeOfCharacter(from: invalidCharacters) != nil {
            return "仓库名称不能包含 /、\\ 或 :"
        }

        return nil
    }

    public static func destinationState(for destinationURL: URL, projectExists: Bool) -> DestinationState {
        var isDirectory: ObjCBool = false
        let path = destinationURL.path

        if projectExists {
            return .existingProject
        }

        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return .available
        }

        guard isDirectory.boolValue else {
            return .existingFile
        }

        let contents = (try? FileManager.default.contentsOfDirectory(
            at: destinationURL,
            includingPropertiesForKeys: nil,
            options: []
        )) ?? []

        return contents.isEmpty ? .existingEmptyDirectory : .existingNonEmptyDirectory
    }

    public static func destinationValidationMessage(for state: DestinationState) -> String? {
        switch state {
        case .available, .existingEmptyDirectory:
            return nil
        case .existingProject:
            return "该目录已经在项目列表中"
        case .existingNonEmptyDirectory:
            return "目标目录已存在且不为空，请更换目录或仓库名称"
        case .existingFile:
            return "目标路径已存在同名文件"
        }
    }

    public static func cloneFailureDescription(from output: String) -> CloneFailureDescription {
        let normalizedOutput = output.lowercased()

        if normalizedOutput.contains("ssl certificate problem")
            || normalizedOutput.contains("certificate verify failed")
            || normalizedOutput.contains("unable to get local issuer certificate")
            || normalizedOutput.contains("self-signed certificate")
            || normalizedOutput.contains("server certificate verification failed")
            || normalizedOutput.contains("schannel") {
            return CloneFailureDescription(
                kind: .certificate,
                title: "证书验证失败",
                recoverySuggestion: "请确认企业证书已被系统信任，或在网络设置中配置 Git 使用的 CA 证书文件。"
            )
        }

        if normalizedOutput.contains("407 proxy authentication required")
            || normalizedOutput.contains("http code 407 from proxy")
            || normalizedOutput.contains("could not resolve proxy")
            || normalizedOutput.contains("failed to connect to proxy")
            || normalizedOutput.contains("proxy connect aborted")
            || normalizedOutput.contains("proxy authentication required")
            || normalizedOutput.contains("received http code 407") {
            return CloneFailureDescription(
                kind: .proxy,
                title: "代理连接失败",
                recoverySuggestion: "请检查 HTTP/HTTPS proxy 地址、认证信息和企业网络连接后重试。"
            )
        }

        if normalizedOutput.contains("host key verification failed")
            || normalizedOutput.contains("no matching host key type found")
            || normalizedOutput.contains("remote host identification has changed")
            || normalizedOutput.contains("offending key")
            || normalizedOutput.contains("known_hosts") {
            return CloneFailureDescription(
                kind: .sshHostKey,
                title: "SSH 主机验证失败",
                recoverySuggestion: "请确认远程主机指纹可信，并更新 ~/.ssh/known_hosts 后重试。"
            )
        }

        if normalizedOutput.contains("permission denied (publickey)")
            || normalizedOutput.contains("permission denied (publickey,password)")
            || normalizedOutput.contains("permission denied, please try again")
            || normalizedOutput.contains("could not read passphrase")
            || normalizedOutput.contains("bad passphrase")
            || normalizedOutput.contains("incorrect passphrase")
            || normalizedOutput.contains("load key")
            || normalizedOutput.contains("sign_and_send_pubkey")
            || normalizedOutput.contains("agent admitted failure")
            || normalizedOutput.contains("no such identity") {
            return CloneFailureDescription(
                kind: .sshAuthentication,
                title: "SSH 认证失败",
                recoverySuggestion: "请确认 SSH key 已添加到 ssh-agent/Keychain，或先在终端执行 ssh-add 输入 passphrase 后重试。"
            )
        }

        if normalizedOutput.contains("authentication failed")
            || normalizedOutput.contains("could not read username")
            || normalizedOutput.contains("could not read password")
            || normalizedOutput.contains("terminal prompts disabled") {
            return CloneFailureDescription(
                kind: .authentication,
                title: "认证失败",
                recoverySuggestion: "请确认远程地址和凭据是否正确；私有仓库需要配置 Git credential helper、token 或可用的 SSH key。"
            )
        }

        if normalizedOutput.contains("repository not found")
            || normalizedOutput.contains("not found")
            || normalizedOutput.contains("does not appear to be a git repository")
            || normalizedOutput.contains("could not read from remote repository") {
            return CloneFailureDescription(
                kind: .repositoryUnavailable,
                title: "仓库不可用",
                recoverySuggestion: "请检查仓库地址是否正确，以及当前账号是否有访问权限。"
            )
        }

        if normalizedOutput.contains("could not resolve host")
            || normalizedOutput.contains("failed to connect")
            || normalizedOutput.contains("connection timed out")
            || normalizedOutput.contains("network is unreachable") {
            return CloneFailureDescription(
                kind: .network,
                title: "网络连接失败",
                recoverySuggestion: "请检查网络、代理、VPN 或企业证书配置后重试。"
            )
        }

        if normalizedOutput.contains("destination path")
            || normalizedOutput.contains("already exists")
            || normalizedOutput.contains("permission denied") {
            return CloneFailureDescription(
                kind: .destination,
                title: "目标路径不可用",
                recoverySuggestion: "请更换本地目录、仓库名称，或确认目标目录有写入权限。"
            )
        }

        return CloneFailureDescription(
            kind: .unknown,
            title: "克隆失败",
            recoverySuggestion: "请查看 Git 输出并修正后重试。"
        )
    }

    public static func cloneFailureMessage(from output: String) -> String {
        let description = cloneFailureDescription(from: output)
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedOutput.isEmpty == false else {
            return "\(description.title)：\(description.recoverySuggestion)"
        }
        return "\(description.title)：\(description.recoverySuggestion)\n\nGit 输出：\(trimmedOutput)"
    }

    public static func loadGlobalNetworkConfiguration() throws -> NetworkConfiguration {
        NetworkConfiguration(
            httpProxy: try readGlobalGitConfig("http.proxy"),
            httpsProxy: try readGlobalGitConfig("https.proxy"),
            sslVerify: try readGlobalGitConfig("http.sslVerify").lowercased() != "false",
            sslCAInfo: try readGlobalGitConfig("http.sslCAInfo")
        )
    }

    public static func saveGlobalNetworkConfiguration(_ configuration: NetworkConfiguration) throws {
        try writeGlobalGitConfig("http.proxy", value: configuration.httpProxy)
        try writeGlobalGitConfig("https.proxy", value: configuration.httpsProxy)
        try writeGlobalGitConfig("http.sslVerify", value: configuration.sslVerify ? nil : "false")
        try writeGlobalGitConfig("http.sslCAInfo", value: configuration.sslCAInfo)
    }

    private static func looksLikeGitHubShortcut(_ value: String) -> Bool {
        guard value.contains("://") == false else { return false }
        guard value.hasPrefix("git@") == false else { return false }
        let parts = value.split(separator: "/")
        return parts.count == 2 && parts.allSatisfy { $0.isEmpty == false }
    }

    private static func readGlobalGitConfig(_ key: String) throws -> String {
        try LibGit2.getGlobalConfig(key: key)
    }

    private static func writeGlobalGitConfig(_ key: String, value: String?) throws {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        try LibGit2.setGlobalConfig(key: key, value: trimmed.isEmpty ? nil : trimmed)
    }

    @discardableResult
    private static func runGitConfig(_ arguments: [String], allowNonZeroExit: Bool) throws -> String {
        throw GitRepositoryCLI.nativeGitUnavailableError(arguments: arguments)
    }
}

public struct GitRepositoryCLI {
    public let repositoryURL: URL

    /// 系统 git CLI 的缓存路径（首次检测后缓存）
    private nonisolated(unsafe) static var cachedGitPath: String?
    private nonisolated(unsafe) static var hasCheckedGit = false
    private static let maxGitCommandOutputBytes = 32 * 1024 * 1024
    private static let maxGitCommandErrorBytes = 1 * 1024 * 1024

    public init(repositoryURL: URL) {
        GitRuntime.initialize()
        self.repositoryURL = repositoryURL
    }

    /// 检测系统是否安装了 git CLI
    /// - Returns: 如果系统有 git CLI 返回 true
    public static func isGitCLIAvailable() -> Bool {
        return gitCLIPath() != nil
    }

    /// 获取系统 git CLI 的路径
    /// - Returns: git 可执行文件路径，不存在则返回 nil
    public static func gitCLIPath() -> String? {
        if hasCheckedGit {
            return cachedGitPath
        }

        hasCheckedGit = true

        let candidates = [
            "/usr/bin/git",
            "/usr/local/bin/git",
            "/opt/homebrew/bin/git",
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedGitPath = path
                return path
            }
        }

        // 尝试通过 which 查找
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", "git"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if output.isEmpty == false && FileManager.default.isExecutableFile(atPath: output) {
                    cachedGitPath = output
                    return output
                }
            }
        } catch {
            // which 命令失败，忽略
        }

        return nil
    }

    static func nativeGitUnavailableError(arguments: [String]) -> NSError {
        NSError(
            domain: "GitOK.GitCommand",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "该 Git 操作尚未迁移到 LibGit2Swift，已阻止调用系统 git：\(arguments.joined(separator: " "))"
            ]
        )
    }

    static func unsupportedNativeGitOperation(_ message: String) -> NSError {
        NSError(
            domain: "GitOK.GitCommand",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    public struct GitLFSStatus: Equatable, Sendable {
        public let isAvailable: Bool
        public let version: String?

        public init(isAvailable: Bool, version: String?) {
            self.isAvailable = isAvailable
            self.version = version
        }
    }

    public struct GitLFSLargeFileCandidate: Equatable, Sendable {
        public let path: String
        public let byteSize: Int64

        public init(path: String, byteSize: Int64) {
            self.path = path
            self.byteSize = byteSize
        }
    }

    public struct GitLFSAttributeMismatch: Equatable, Sendable {
        public enum Kind: String, Sendable {
            case pointerWithoutLFSAttribute
            case lfsAttributeWithoutPointer
        }

        public let path: String
        public let kind: Kind

        public init(path: String, kind: Kind) {
            self.path = path
            self.kind = kind
        }
    }

    public struct GitSubmodule: Equatable, Sendable {
        public enum Status: String, Sendable {
            case initialized
            case uninitialized
            case modified
            case conflicted
        }

        public let path: String
        public let commitHash: String
        public let status: Status
        public let description: String?

        public init(path: String, commitHash: String, status: Status, description: String?) {
            self.path = path
            self.commitHash = commitHash
            self.status = status
            self.description = description
        }
    }

    public struct CreateRepositoryOptions: Equatable, Sendable {
        public var readmeContent: String?
        public var gitignoreContent: String?
        public var licenseContent: String?
        public var initialCommitMessage: String?
        public var userName: String?
        public var userEmail: String?

        public init(
            readmeContent: String? = nil,
            gitignoreContent: String? = nil,
            licenseContent: String? = nil,
            initialCommitMessage: String? = nil,
            userName: String? = nil,
            userEmail: String? = nil
        ) {
            self.readmeContent = readmeContent
            self.gitignoreContent = gitignoreContent
            self.licenseContent = licenseContent
            self.initialCommitMessage = initialCommitMessage
            self.userName = userName
            self.userEmail = userEmail
        }
    }

    public static func initialize(at repositoryURL: URL) throws {
        if FileManager.default.fileExists(atPath: repositoryURL.path) == false {
            try FileManager.default.createDirectory(at: repositoryURL, withIntermediateDirectories: true)
        }

        let repo = try LibGit2.createRepository(at: repositoryURL.path)
        git_repository_free(repo)
    }

    public static func create(at repositoryURL: URL, options: CreateRepositoryOptions = CreateRepositoryOptions()) throws {
        GitRuntime.initialize()
        let destinationExistsBeforeCreate = FileManager.default.fileExists(atPath: repositoryURL.path)

        do {
            try initialize(at: repositoryURL)
            try writeCreateRepositoryFiles(at: repositoryURL, options: options)

            let userName = options.userName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let userEmail = options.userEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
            if userName?.isEmpty == false {
                try LibGit2.setConfig(key: "user.name", value: userName!, at: repositoryURL.path, verbose: false)
            }

            if userEmail?.isEmpty == false {
                try LibGit2.setConfig(key: "user.email", value: userEmail!, at: repositoryURL.path, verbose: false)
            }

            if let message = options.initialCommitMessage?.trimmingCharacters(in: .whitespacesAndNewlines), message.isEmpty == false {
                try LibGit2.addFiles([], at: repositoryURL.path, verbose: false)
                _ = try LibGit2.createCommit(message: message, at: repositoryURL.path, verbose: false)
            }
        } catch {
            if destinationExistsBeforeCreate == false {
                try? FileManager.default.removeItem(at: repositoryURL)
            }
            throw error
        }
    }

    public static func clone(
        remoteURL: String,
        destinationURL: URL,
        progress: (@Sendable (String) -> Void)? = nil
    ) throws {
        GitRuntime.initialize()
        let parentURL = destinationURL.deletingLastPathComponent()
        let destinationExistsBeforeClone = FileManager.default.fileExists(atPath: destinationURL.path)

        if FileManager.default.fileExists(atPath: parentURL.path) == false {
            try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
        }

        do {
            progress?("Cloning \(remoteURL)")
            try LibGit2.clone(url: remoteURL, to: destinationURL.path)
        } catch {
            if destinationExistsBeforeClone == false {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: CloneRepositoryValidation.cloneFailureMessage(from: error.localizedDescription)]
            )
        }

        guard FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent(".git").path) else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Git clone 已完成，但目标目录不是有效的 Git 仓库"]
            )
        }
    }

    public static func approveCredential(
        protocol scheme: String = "https",
        host: String,
        username: String,
        password: String
    ) throws {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedHost.isEmpty == false, trimmedUsername.isEmpty == false, password.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "凭据不完整"]
            )
        }
        throw Self.unsupportedNativeGitOperation("保存 Git 凭据需要系统 Git credential helper；当前版本不会调用系统 git。")
    }

    public func stashSave(message: String? = nil) throws {
        _ = try LibGit2.stash(message: message, at: repositoryURL.path, verbose: false)
    }

    public func stashList() throws -> [GitStashEntry] {
        try LibGit2.getStashList(at: repositoryURL.path).map { entry in
            return GitStashEntry(
                index: entry.index,
                message: entry.message,
                branchName: nil,
                relativeDate: nil,
                changedFileCount: 0,
                diffPreview: ""
            )
        }
    }

    public func stashApply(index: Int) throws {
        try LibGit2.stashApply(index: index, at: repositoryURL.path, verbose: false)
    }

    public func stashPop(index: Int) throws {
        try LibGit2.stashPop(index: index, at: repositoryURL.path, verbose: false)
    }

    public func stashDrop(index: Int) throws {
        try LibGit2.stashDrop(index: index, at: repositoryURL.path, verbose: false)
    }

    public func stashBranch(name: String, index: Int) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "分支名称不能为空"]
            )
        }

        try LibGit2.stashBranch(name: trimmedName, index: index, at: repositoryURL.path, verbose: false)
    }

    public func fetch(remote: String = "origin") throws {
        try LibGit2.fetch(at: repositoryURL.path, remote: remote, prune: true, verbose: false)
    }

    public func remoteNames() throws -> [String] {
        try LibGit2.getRemoteList(at: repositoryURL.path).map(\.name)
    }

    public func remotes() throws -> [GitRemoteSummary] {
        try LibGit2.getRemoteList(at: repositoryURL.path).map { remote in
            GitRemoteSummary(
                id: remote.id,
                name: remote.name,
                url: remote.url,
                fetchURL: remote.fetchURL,
                pushURL: remote.pushURL,
                isDefault: remote.isDefault
            )
        }
    }

    public func addRemote(name: String, url: String) throws {
        try LibGit2.addRemote(name: name, url: url, at: repositoryURL.path, verbose: false)
    }

    public func updateRemote(originalName: String, newName: String, newURL: String) throws {
        let trimmedOriginalName = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewURL = newURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedOriginalName.isEmpty == false else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "原远程仓库名称不能为空"])
        }

        guard trimmedNewName.isEmpty == false else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "远程仓库名称不能为空"])
        }

        guard trimmedNewURL.isEmpty == false else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "远程仓库 URL 不能为空"])
        }

        if trimmedOriginalName != trimmedNewName {
            try LibGit2.removeRemote(name: trimmedOriginalName, at: repositoryURL.path, verbose: false)
            try LibGit2.addRemote(name: trimmedNewName, url: trimmedNewURL, at: repositoryURL.path, verbose: false)
        } else {
            try LibGit2.setRemoteURL(name: trimmedOriginalName, url: trimmedNewURL, at: repositoryURL.path, verbose: false)
        }
    }

    public func removeRemote(name: String) throws {
        try LibGit2.removeRemote(name: name, at: repositoryURL.path, verbose: false)
    }

    public func currentBranchName() throws -> String? {
        let branch = try LibGit2.getCurrentBranch(at: repositoryURL.path)
        return branch.isEmpty ? nil : branch
    }

    public func currentUpstreamRemoteName() throws -> String? {
        guard let branch = try currentBranchName() else { return nil }
        let upstream = try LibGit2.getConfig(key: "branch.\(branch).remote", at: repositoryURL.path, verbose: false)
        return upstream.isEmpty ? nil : upstream
    }

    public func pull() throws {
        try performWithResolvedSSHURL(operation: "pull") {
            try LibGit2.pull(at: repositoryURL.path, verbose: false)
        }
    }

    public func push() throws {
        try performWithResolvedSSHURL(operation: "push") {
            try LibGit2.push(at: repositoryURL.path, verbose: false)
        }
    }

    public func sync() throws {
        try fetch()
        let trackingState = try aheadBehind()

        if trackingState.hasUpstream,
           trackingState.ahead > 0,
           trackingState.behind > 0 {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Local and remote branches have diverged. Pull or push manually."
                ]
            )
        }

        if trackingState.hasUpstream, trackingState.behind > 0 {
            try pull()
        }

        if trackingState.hasUpstream == false || trackingState.ahead > 0 {
            try push()
        }
    }

    private func performWithResolvedSSHURL(operation _: String, block: () throws -> Void) throws {
        guard let remoteURL = LibGit2.getRemoteURL(at: repositoryURL.path, remote: "origin") else {
            try block()
            return
        }

        let resolvedURL = SSHConfigURLResolver.applySSHConfig(to: remoteURL)
        guard resolvedURL != remoteURL else {
            try block()
            return
        }

        try LibGit2.setRemoteURL(at: repositoryURL.path, remote: "origin", url: resolvedURL)
        defer {
            try? LibGit2.setRemoteURL(at: repositoryURL.path, remote: "origin", url: remoteURL)
        }

        try block()
    }

    public func isGitRepository() -> Bool {
        LibGit2.isGitRepository(at: repositoryURL.path)
    }

    public func commitList() throws -> [GitCommit] {
        try LibGit2.getCommitList(at: repositoryURL.path)
    }

    public func hasUncommittedChanges(verbose: Bool = true) throws -> Bool {
        try LibGit2.hasUncommittedChanges(at: repositoryURL.path, verbose: verbose)
    }

    public func diffFileList(staged: Bool = false) throws -> [GitDiffFile] {
        try LibGit2.getDiffFileList(at: repositoryURL.path, staged: staged)
    }

    public func currentBranchInfo() throws -> GitBranch? {
        try LibGit2.getCurrentBranchInfo(at: repositoryURL.path)
    }

    public func checkout(branch: String) throws {
        try LibGit2.checkout(branch: branch, at: repositoryURL.path)
    }

    public func branchList(includeRemote: Bool = false) throws -> [GitBranch] {
        try LibGit2.getBranchList(at: repositoryURL.path, includeRemote: includeRemote)
    }

    public func checkoutNewBranch(named branchName: String) throws {
        try LibGit2.checkoutNewBranch(named: branchName, at: repositoryURL.path)
    }

    public func merge(branchName: String, verbose: Bool = false) throws {
        try LibGit2.merge(branchName: branchName, at: repositoryURL.path, verbose: verbose)
    }

    public func addAllFiles() throws {
        try LibGit2.addFiles([], at: repositoryURL.path, verbose: false)
    }

    public func configValue(key: String) throws -> String {
        try LibGit2.getConfig(key: key, at: repositoryURL.path, verbose: false)
    }

    public func userConfig() throws -> (name: String, email: String) {
        try LibGit2.getUserConfig(at: repositoryURL.path, verbose: false)
    }

    public func setUserConfig(name: String, email: String) throws {
        try LibGit2.setUserConfig(name: name, email: email, at: repositoryURL.path, verbose: false)
    }

    public func unpushedCommits() throws -> [GitCommit] {
        try LibGit2.getUnPushedCommits(at: repositoryURL.path, verbose: false)
    }

    public func unpulledCount() throws -> Int {
        try LibGit2.getUnPulledCount(at: repositoryURL.path)
    }

    public func createCommit(message: String) throws -> String {
        try LibGit2.createCommit(message: message, at: repositoryURL.path, verbose: false)
    }

    public func commitList(page: Int, size: Int) throws -> [GitCommit] {
        try LibGit2.getCommitListWithPagination(at: repositoryURL.path, page: page, size: size)
    }

    public func commitGraphList(page: Int, size: Int) throws -> [GitCommit] {
        try LibGit2.getCommitGraphListWithPagination(at: repositoryURL.path, page: page, size: size)
    }

    public func reset(to commitHash: String?, mode: String) throws {
        try LibGit2.reset(to: commitHash, mode: mode, at: repositoryURL.path, verbose: false)
    }

    public func fileContent(atCommit commitHash: String, file filePath: String) throws -> String {
        try LibGit2.getFileContent(atCommit: commitHash, file: filePath, at: repositoryURL.path)
    }

    public func fileContentChange(atCommit commitHash: String, file filePath: String) throws -> (before: String?, after: String?) {
        try LibGit2.getFileContentChange(atCommit: commitHash, file: filePath, at: repositoryURL.path)
    }

    public func uncommittedFileContentChange(for filePath: String) throws -> (before: String?, after: String?) {
        try LibGit2.getUncommittedFileContentChange(for: filePath, at: repositoryURL.path)
    }

    public func fileDiff(atCommit commitHash: String, for filePath: String) throws -> String {
        try LibGit2.getFileDiff(atCommit: commitHash, for: filePath, at: repositoryURL.path)
    }

    public func uncommittedFileDiff(for filePath: String, ignoreWhitespace: Bool = false) throws -> String {
        let stagedDiff = try fileDiff(filePath, staged: true, ignoreWhitespace: ignoreWhitespace)
        let unstagedDiff = try fileDiff(filePath, staged: false, ignoreWhitespace: ignoreWhitespace)
        return [stagedDiff, unstagedDiff]
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .joined(separator: "\n")
    }

    public func fileData(atCommit commitHash: String, file filePath: String) throws -> Data {
        try LibGit2.getFileData(atCommit: commitHash, file: filePath, at: repositoryURL.path)
    }

    public func commitDiffFiles(atCommit commitHash: String) throws -> [GitDiffFile] {
        try LibGit2.getCommitDiffFiles(atCommit: commitHash, at: repositoryURL.path)
    }

    public func remoteList() throws -> [GitRemote] {
        try LibGit2.getRemoteList(at: repositoryURL.path)
    }

    public func tags(for commitHash: String) throws -> [String] {
        try LibGit2.getTags(at: repositoryURL.path, for: commitHash)
    }

    public func submodules() throws -> [GitSubmodule] {
        try LibGit2.submodules(at: repositoryURL.path).map { submodule in
            GitSubmodule(
                path: submodule.path,
                commitHash: submodule.commitHash,
                status: gitCoreSubmoduleStatus(submodule.status),
                description: submodule.description
            )
        }
    }

    public func initializeSubmodules(paths: [String] = [], recursive: Bool = true, allowFileProtocol: Bool = false) throws {
        try LibGit2.initializeSubmodules(paths: paths, at: repositoryURL.path, recursive: recursive, verbose: false)
    }

    public func updateSubmodules(paths: [String] = [], recursive: Bool = true, allowFileProtocol: Bool = false) throws {
        try LibGit2.updateSubmodules(paths: paths, at: repositoryURL.path, initialize: false, recursive: recursive, verbose: false)
    }

    public func submoduleDiff(path: String) throws -> String {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPath.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "子模块路径不能为空"]
            )
        }

        return try LibGit2.submoduleDiff(path: trimmedPath, at: repositoryURL.path)
    }

    public func lfsStatus() -> GitLFSStatus {
        GitLFSStatus(isAvailable: false, version: nil)
    }

    public func initializeLFS() throws {
        throw Self.unsupportedNativeGitOperation("LibGit2Swift 尚未实现 Git LFS 初始化")
    }

    public func lfsLargeFileCandidates(
        thresholdBytes: Int64 = 50 * 1024 * 1024,
        maxCount: Int = 200
    ) throws -> [GitLFSLargeFileCandidate] {
        guard thresholdBytes > 0 else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "大文件阈值必须大于 0"]
            )
        }
        guard maxCount > 0 else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "大文件候选数量必须大于 0"]
            )
        }

        let repositoryURL = repositoryURL.standardizedFileURL
        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isRegularFileKey,
            .fileSizeKey,
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: repositoryURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsPackageDescendants]
        ) else {
            return []
        }

        var candidates: [GitLFSLargeFileCandidate] = []
        let pruneThreshold = max(maxCount * 2, 1000)

        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == ".git" {
                enumerator.skipDescendants()
                continue
            }

            let values = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard values.isRegularFile == true, let fileSize = values.fileSize else { continue }

            let byteSize = Int64(fileSize)
            guard byteSize >= thresholdBytes else { continue }

            candidates.append(
                GitLFSLargeFileCandidate(
                    path: Self.relativePath(for: fileURL.standardizedFileURL, in: repositoryURL),
                    byteSize: byteSize
                )
            )

            if candidates.count > pruneThreshold {
                candidates = Self.sortedLFSLargeFileCandidates(candidates, limit: maxCount)
            }
        }

        return Self.sortedLFSLargeFileCandidates(candidates, limit: maxCount)
    }

    private static func sortedLFSLargeFileCandidates(
        _ candidates: [GitLFSLargeFileCandidate],
        limit: Int
    ) -> [GitLFSLargeFileCandidate] {
        let sorted = candidates.sorted {
            if $0.byteSize == $1.byteSize {
                return $0.path < $1.path
            }
            return $0.byteSize > $1.byteSize
        }
        return Array(sorted.prefix(limit))
    }

    public func lfsAttributeMismatches() throws -> [GitLFSAttributeMismatch] {
        let paths = try trackedFilePaths()
        var mismatches: [GitLFSAttributeMismatch] = []

        for path in paths {
            let hasLFSAttribute = try fileHasLFSFilterAttribute(path)
            let storesLFSPointer = try indexStoresLFSPointer(path)

            if storesLFSPointer && hasLFSAttribute == false {
                mismatches.append(GitLFSAttributeMismatch(path: path, kind: .pointerWithoutLFSAttribute))
            } else if hasLFSAttribute && storesLFSPointer == false {
                mismatches.append(GitLFSAttributeMismatch(path: path, kind: .lfsAttributeWithoutPointer))
            }
        }

        return mismatches.sorted { $0.path < $1.path }
    }

    public func deleteLocalBranch(named branchName: String) throws {
        let trimmedName = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "分支名称不能为空"]
            )
        }

        let currentBranch = try LibGit2.getCurrentBranch(at: repositoryURL.path)
        guard currentBranch != trimmedName else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "不能删除当前分支"]
            )
        }

        try LibGit2.deleteBranch(named: trimmedName, at: repositoryURL.path)
    }

    public func renameBranch(from currentName: String, to newName: String) throws {
        let trimmedCurrentName = currentName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedCurrentName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "原分支名称不能为空"]
            )
        }

        guard trimmedNewName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "新分支名称不能为空"]
            )
        }

        guard LibGit2.isValidBranchName(trimmedNewName) else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "新分支名称无效"])
        }
        try LibGit2.renameBranch(named: trimmedCurrentName, to: trimmedNewName, at: repositoryURL.path)
    }

    public func remoteBranches(remote: String? = nil) throws -> [String] {
        try LibGit2.getRemoteBranchNames(at: repositoryURL.path, remote: remote)
    }

    public func branches() throws -> [GitBranchSummary] {
        let currentBranch = try? LibGit2.getCurrentBranch(at: repositoryURL.path)
        return try LibGit2.getBranchList(at: repositoryURL.path).map { branch in
            GitBranchSummary(
                name: branch.name,
                isRemote: false,
                isCurrent: branch.isCurrent || branch.name == currentBranch
            )
        }
    }

    public func createBranch(named branchName: String) throws {
        let trimmedName = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "分支名称不能为空"])
        }

        guard LibGit2.isValidBranchName(trimmedName) else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "分支名称无效"])
        }

        try LibGit2.checkoutNewBranch(named: trimmedName, at: repositoryURL.path)
    }

    public func checkoutBranch(named branchName: String) throws {
        let trimmedName = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "分支名称不能为空"])
        }

        _ = try LibGit2.checkout(branch: trimmedName, at: repositoryURL.path, verbose: false)
    }

    public func mergeBranches(fromBranch sourceBranchName: String, toBranch targetBranchName: String) throws {
        let source = sourceBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = targetBranchName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard source.isEmpty == false else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "来源分支不能为空"])
        }

        guard target.isEmpty == false else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "目标分支不能为空"])
        }

        _ = try LibGit2.checkout(branch: target, at: repositoryURL.path, verbose: false)
        try LibGit2.merge(branchName: source, at: repositoryURL.path, verbose: false)
    }

    public func setUpstream(localBranch: String, upstreamBranch: String) throws {
        let trimmedLocalBranch = localBranch.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUpstreamBranch = upstreamBranch.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedLocalBranch.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "本地分支名称不能为空"]
            )
        }

        guard trimmedUpstreamBranch.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "上游分支不能为空"]
            )
        }

        try LibGit2.setUpstream(localBranch: trimmedLocalBranch, upstreamBranch: trimmedUpstreamBranch, at: repositoryURL.path)
    }

    public func unsetUpstream(localBranch: String) throws {
        let trimmedLocalBranch = localBranch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLocalBranch.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "本地分支名称不能为空"]
            )
        }

        try LibGit2.unsetUpstream(localBranch: trimmedLocalBranch, at: repositoryURL.path)
    }

    public func deleteRemoteBranch(named branchName: String, remote: String = "origin") throws {
        let trimmedName = branchName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemote = remote.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "远程分支名称不能为空"]
            )
        }

        guard trimmedRemote.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "远程仓库名称不能为空"]
            )
        }

        let shortBranchName = trimmedName.hasPrefix(trimmedRemote + "/")
            ? String(trimmedName.dropFirst(trimmedRemote.count + 1))
            : trimmedName

        guard shortBranchName.isEmpty == false && shortBranchName != "HEAD" else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "不能删除远程 HEAD"]
            )
        }

        try LibGit2.deleteRemoteBranch(named: shortBranchName, remote: trimmedRemote, at: repositoryURL.path, verbose: false)
    }

    public func publishBranch(localBranch: String, remote: String = "origin", remoteBranch: String? = nil) throws {
        let trimmedLocalBranch = localBranch.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemote = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemoteBranch = remoteBranch?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedLocalBranch.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "本地分支名称不能为空"]
            )
        }

        guard trimmedRemote.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "远程仓库名称不能为空"]
            )
        }

        try LibGit2.publishBranch(
            localBranch: trimmedLocalBranch,
            remote: trimmedRemote,
            remoteBranch: trimmedRemoteBranch,
            at: repositoryURL.path,
            verbose: false
        )
    }

    public func compareBranches(base: String, head: String) throws -> GitBranchCompare {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHead = head.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedBase.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Base 分支不能为空"]
            )
        }

        guard trimmedHead.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Head 分支不能为空"]
            )
        }

        return try mapBranchCompare(base: trimmedBase, head: trimmedHead)
    }

    public func rebaseStatus() throws -> GitRebaseStatus {
        let rebaseMergePath = try gitPath("rebase-merge")
        let rebaseApplyPath = try gitPath("rebase-apply")
        let rebasePath: URL

        if FileManager.default.fileExists(atPath: rebaseMergePath.path) {
            rebasePath = rebaseMergePath
        } else if FileManager.default.fileExists(atPath: rebaseApplyPath.path) {
            rebasePath = rebaseApplyPath
        } else {
            return .inactive
        }

        let branchName = try readFileIfExists(rebasePath.appendingPathComponent("head-name"))?
            .replacingOccurrences(of: "refs/heads/", with: "")
        let onto = try readFileIfExists(rebasePath.appendingPathComponent("onto"))
        let currentStep = try readFileIfExists(rebasePath.appendingPathComponent("msgnum")).flatMap { Int($0) }
        let totalSteps = try readFileIfExists(rebasePath.appendingPathComponent("end")).flatMap { Int($0) }

        return GitRebaseStatus(
            isRebasing: true,
            branchName: branchName,
            onto: onto,
            currentStep: currentStep,
            totalSteps: totalSteps
        )
    }

    public func startRebase(branch: String, onto upstream: String) throws {
        let trimmedBranch = branch.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUpstream = upstream.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedBranch.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Rebase 分支不能为空"]
            )
        }

        guard trimmedUpstream.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Rebase 目标不能为空"]
            )
        }

        throw Self.unsupportedNativeGitOperation("LibGit2Swift 尚未实现 rebase")
    }

    public func continueRebase() throws {
        throw Self.unsupportedNativeGitOperation("LibGit2Swift 尚未实现 rebase --continue")
    }

    public func abortRebase() throws {
        throw Self.unsupportedNativeGitOperation("LibGit2Swift 尚未实现 rebase --abort")
    }

    public func cherryPickStatus() throws -> GitCherryPickStatus {
        guard let commitHash = try readGitPathFile("CHERRY_PICK_HEAD"), commitHash.isEmpty == false else {
            return .inactive
        }
        return GitCherryPickStatus(isCherryPicking: true, commitHash: commitHash)
    }

    public func cherryPick(commits: [String], onto branch: String? = nil) throws {
        let trimmedCommits = commits
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard trimmedCommits.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cherry-pick 提交不能为空"]
            )
        }

        if let branch {
            let trimmedBranch = branch.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedBranch.isEmpty == false else {
                throw NSError(
                    domain: "GitOK.GitCommand",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "目标分支不能为空"]
                )
            }
            try LibGit2.checkout(branch: trimmedBranch, at: repositoryURL.path, verbose: false)
        }
        try LibGit2.cherryPick(commits: trimmedCommits, at: repositoryURL.path, verbose: false)
    }

    public func continueCherryPick() throws {
        try LibGit2.continueCherryPick(at: repositoryURL.path, verbose: false)
    }

    public func abortCherryPick() throws {
        try LibGit2.abortCherryPick(at: repositoryURL.path, verbose: false)
    }

    public func revertCommit(_ commitHash: String) throws {
        let trimmedHash = commitHash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedHash.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Revert 提交不能为空"]
            )
        }

        try LibGit2.revertCommit(trimmedHash, at: repositoryURL.path, verbose: false)
    }

    public func reset(to commitHash: String, mode: GitResetMode) throws {
        let trimmedHash = commitHash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedHash.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Reset 目标提交不能为空"]
            )
        }

        try LibGit2.reset(to: trimmedHash, mode: mode.rawValue, at: repositoryURL.path, verbose: false)
    }

    public func squashLastCommits(count: Int, message: String) throws {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard count >= 2 else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Squash 至少需要 2 个提交"]
            )
        }

        guard trimmedMessage.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Squash 提交信息不能为空"]
            )
        }

        let commits = try LibGit2.getCommitList(at: repositoryURL.path)
        guard commits.count > count else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Squash 需要保留至少一个父提交"]
            )
        }

        let targetParent = commits[count].hash
        try LibGit2.reset(to: targetParent, mode: "mixed", at: repositoryURL.path, verbose: false)
        try LibGit2.addFiles([], at: repositoryURL.path, verbose: false)
        _ = try LibGit2.createCommit(message: trimmedMessage, at: repositoryURL.path, verbose: false)
    }

    public func createLightweightTag(named tagName: String, commitHash: String) throws {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHash = commitHash.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "标签名称不能为空"]
            )
        }

        guard trimmedHash.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "提交哈希不能为空"]
            )
        }

        guard LibGit2.isValidTagName(trimmedName) else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "标签名称无效"])
        }
        try LibGit2.createTag(named: trimmedName, message: nil, at: trimmedHash, in: repositoryURL.path, verbose: false)
    }

    public func createAnnotatedTag(named tagName: String, commitHash: String, message: String) throws {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHash = commitHash.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "标签名称不能为空"]
            )
        }

        guard trimmedHash.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "提交哈希不能为空"]
            )
        }

        guard trimmedMessage.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "标签说明不能为空"]
            )
        }

        guard LibGit2.isValidTagName(trimmedName) else {
            throw NSError(domain: "GitOK.GitCommand", code: -1, userInfo: [NSLocalizedDescriptionKey: "标签名称无效"])
        }
        try LibGit2.createTag(named: trimmedName, message: trimmedMessage, at: trimmedHash, in: repositoryURL.path, verbose: false)
    }

    public func deleteLocalTag(named tagName: String) throws {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "标签名称不能为空"]
            )
        }

        try LibGit2.deleteTag(named: trimmedName, at: repositoryURL.path, verbose: false)
    }

    public func pushTag(named tagName: String, remote: String = "origin") throws {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemote = remote.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "标签名称不能为空"]
            )
        }

        guard trimmedRemote.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "远程仓库名称不能为空"]
            )
        }

        try LibGit2.pushTag(named: trimmedName, remote: trimmedRemote, at: repositoryURL.path, verbose: false)
    }

    public func deleteRemoteTag(named tagName: String, remote: String = "origin") throws {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemote = remote.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "标签名称不能为空"]
            )
        }

        guard trimmedRemote.isEmpty == false else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "远程仓库名称不能为空"]
            )
        }

        try LibGit2.deleteRemoteTag(named: trimmedName, remote: trimmedRemote, at: repositoryURL.path, verbose: false)
    }

    public func aheadBehind() throws -> GitAheadBehind {
        let state = try LibGit2.aheadBehind(at: repositoryURL.path)
        return GitAheadBehind(ahead: state.ahead, behind: state.behind, hasUpstream: state.hasUpstream)
    }

    public func unpushedCommitCount() throws -> Int {
        try aheadBehind().ahead
    }

    public func unpushedCommitHashes() throws -> [String] {
        let state = try aheadBehind()
        guard state.ahead > 0 else { return [] }

        let repo = try LibGit2.openRepository(at: repositoryURL.path)
        defer { git_repository_free(repo) }

        var headOID = git_oid()
        guard git_reference_name_to_id(&headOID, repo, "HEAD") == 0 else {
            return []
        }

        var headRef: OpaquePointer?
        guard git_reference_lookup(&headRef, repo, "HEAD") == 0, let ref = headRef else {
            return []
        }
        defer { git_reference_free(headRef) }

        var targetRef: OpaquePointer?
        guard git_reference_resolve(&targetRef, ref) == 0, let branchRef = targetRef else {
            return []
        }
        defer { git_reference_free(targetRef) }

        var upstreamRef: OpaquePointer?
        guard git_branch_upstream(&upstreamRef, branchRef) == 0, let upstream = upstreamRef else {
            return []
        }
        defer { git_reference_free(upstreamRef) }

        guard let upstreamName = git_reference_shorthand(upstream) else {
            return []
        }
        let remoteTrackingBranchName = "refs/remotes/\(String(cString: upstreamName))"

        var upstreamOID = git_oid()
        guard git_reference_name_to_id(&upstreamOID, repo, remoteTrackingBranchName) == 0 else {
            return []
        }

        var revwalk: OpaquePointer?
        guard git_revwalk_new(&revwalk, repo) == 0, let walker = revwalk else {
            throw LibGit2Error.cannotCreateRevwalk
        }
        defer { git_revwalk_free(walker) }

        git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL.rawValue)
        git_revwalk_push(walker, &headOID)
        git_revwalk_hide(walker, &upstreamOID)

        var hashes: [String] = []
        hashes.reserveCapacity(state.ahead)
        var oid = git_oid()
        while git_revwalk_next(&oid, walker) == 0 && hashes.count < state.ahead {
            hashes.append(LibGit2.oidToString(oid))
        }

        return hashes
    }

    public func addFiles(_ filePaths: [String]) throws {
        guard filePaths.isEmpty == false else { return }
        try LibGit2.addFiles(filePaths, at: repositoryURL.path, verbose: false)
    }

    public func fileDiff(_ filePath: String, staged: Bool, ignoreWhitespace: Bool = false) throws -> String {
        return try LibGit2.getFileDiff(
            for: filePath,
            at: repositoryURL.path,
            staged: staged,
            ignoreWhitespace: ignoreWhitespace
        )
    }

    public func applyPatch(_ patch: String, mode: GitPatchApplyMode) throws {
        try LibGit2.applyPatch(patch, mode: mode == .stage ? .stage : .unstage, at: repositoryURL.path)
    }

    public func unstageFiles(_ filePaths: [String]) throws {
        guard filePaths.isEmpty == false else { return }
        for filePath in filePaths {
            let patch = try LibGit2.getFileDiff(for: filePath, at: repositoryURL.path, staged: true)
            if patch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                try LibGit2.applyPatch(patch, mode: .unstage, at: repositoryURL.path)
            }
        }
    }

    public func discardFileChanges(_ filePath: String) throws {
        let trackedInHead = try isTrackedInHead(filePath)

        if trackedInHead {
            try unstageFiles([filePath])
            try LibGit2.checkoutFile(filePath, at: repositoryURL.path, verbose: false)
            return
        }

        try unstageFiles([filePath])
        try removeWorkingTreeItem(filePath)
    }

    public func discardAllChanges() throws {
        let entries = try statusEntries()
        var trackedPaths: [String] = []
        var newPaths: [String] = []

        for entry in entries {
            if try isTrackedInHead(entry.path) {
                trackedPaths.append(entry.path)
            } else {
                newPaths.append(entry.path)
            }
        }

        if trackedPaths.isEmpty == false {
            try LibGit2.reset(to: nil, mode: "hard", at: repositoryURL.path, verbose: false)
        }

        if newPaths.isEmpty == false {
            for path in newPaths {
                try removeWorkingTreeItem(path)
            }
        }
    }

    public func isMerging() throws -> Bool {
        try readGitPathFile("MERGE_HEAD")?.isEmpty == false
    }

    public func getCurrentMergeBranchName() throws -> String? {
        guard try isMerging() else { return nil }

        if let mergeMessage = try readGitPathFile("MERGE_MSG"),
           let branchRange = mergeMessage.range(of: #"Merge branch '([^']+)'"#, options: .regularExpression) {
            let matched = String(mergeMessage[branchRange])
            return matched
                .replacingOccurrences(of: "Merge branch '", with: "")
                .replacingOccurrences(of: "'", with: "")
        }

        return nil
    }

    public func getMergeConflictFiles() throws -> [String] {
        try lightweightStatusEntries()
            .filter { $0.indexStatus == "U" || $0.workTreeStatus == "U" }
            .map(\.path)
    }

    public func statusEntries() throws -> [GitStatusEntry] {
        var entries: [GitStatusEntry] = []
        entries += try LibGit2.getDiffFileList(at: repositoryURL.path, staged: true).map {
            GitStatusEntry(path: $0.file, indexStatus: Character($0.changeType), workTreeStatus: " ")
        }
        entries += try LibGit2.getDiffFileList(at: repositoryURL.path, staged: false).map {
            GitStatusEntry(path: $0.file, indexStatus: " ", workTreeStatus: Character($0.changeType))
        }
        return mergedStatusEntries(entries)
    }

    public func lightweightStatusEntries() throws -> [GitStatusEntry] {
        let output = try Self.runGitData(
            ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
            in: repositoryURL,
            defaultErrorMessage: "无法读取工作区状态"
        )
        return Self.parsePorcelainStatusEntries(output)
    }

    static func parsePorcelainStatusEntries(_ data: Data) -> [GitStatusEntry] {
        var entries: [GitStatusEntry] = []
        var recordStart = data.startIndex

        while recordStart < data.endIndex {
            var recordEnd = recordStart
            while recordEnd < data.endIndex && data[recordEnd] != 0 {
                recordEnd = data.index(after: recordEnd)
            }

            let nextRecordStart = recordEnd < data.endIndex ? data.index(after: recordEnd) : data.endIndex

            guard recordEnd > recordStart else {
                recordStart = nextRecordStart
                continue
            }

            let record = data[recordStart..<recordEnd]
            guard record.count >= 4,
                  record[record.index(record.startIndex, offsetBy: 2)] == UInt8(ascii: " ") else {
                recordStart = nextRecordStart
                continue
            }

            let line = String(decoding: record, as: UTF8.self)
            let indexStatus = Character(String(line[line.startIndex]))
            let workTreeStatus = Character(String(line[line.index(after: line.startIndex)]))
            let pathStartIndex = line.index(line.startIndex, offsetBy: 3)
            let path = String(line[pathStartIndex...])
            if path.isEmpty == false {
                entries.append(GitStatusEntry(
                    path: path,
                    indexStatus: indexStatus,
                    workTreeStatus: workTreeStatus
                ))
            }

            recordStart = nextRecordStart

            if indexStatus == "R" || indexStatus == "C" {
                while recordStart < data.endIndex {
                    let byte = data[recordStart]
                    recordStart = data.index(after: recordStart)
                    if byte == 0 {
                        break
                    }
                }
            }
        }

        return entries.sorted { $0.path < $1.path }
    }

    private func mergedStatusEntries(_ entries: [GitStatusEntry]) -> [GitStatusEntry] {
        var entriesByPath: [String: GitStatusEntry] = [:]

        for entry in entries {
            guard let existingEntry = entriesByPath[entry.path] else {
                entriesByPath[entry.path] = entry
                continue
            }

            entriesByPath[entry.path] = GitStatusEntry(
                path: entry.path,
                indexStatus: existingEntry.indexStatus == " " ? entry.indexStatus : existingEntry.indexStatus,
                workTreeStatus: existingEntry.workTreeStatus == " " ? entry.workTreeStatus : existingEntry.workTreeStatus
            )
        }

        return entriesByPath.values.sorted { $0.path < $1.path }
    }

    public func mergeFileContent(path: String, version: GitMergeFileVersion) throws -> String {
        try LibGit2.conflictFileContent(
            path: path,
            version: libGit2ConflictVersion(version),
            at: repositoryURL.path
        )
    }

    public func mergeFileDiff(path: String) throws -> String {
        throw Self.unsupportedNativeGitOperation("LibGit2Swift 尚未实现冲突合并 diff")
    }

    public func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion) throws {
        let stages = try unmergedStages(for: path)
        if stages.isEmpty || stages.contains(version.stageNumber) {
            try checkoutExistingMergeFileVersion(path: path, version: version)
            try addFiles([path])
            return
        }

        switch version {
        case .ours, .theirs:
            try Self.runGit(
                ["rm", "--ignore-unmatch", "-f", "--", path],
                in: repositoryURL,
                defaultErrorMessage: "无法选择合并文件版本"
            )
        case .base:
            try checkoutExistingMergeFileVersion(path: path, version: version)
            try addFiles([path])
        }
    }

    private func checkoutExistingMergeFileVersion(path: String, version: GitMergeFileVersion) throws {
        switch version {
        case .ours:
            try LibGit2.checkoutConflictFileVersion(path: path, version: .ours, at: repositoryURL.path)
        case .theirs:
            try LibGit2.checkoutConflictFileVersion(path: path, version: .theirs, at: repositoryURL.path)
        case .base:
            try LibGit2.checkoutConflictFileVersion(path: path, version: .base, at: repositoryURL.path)
        }
    }

    private func unmergedStages(for path: String) throws -> Set<Int> {
        let output = try Self.runGit(
            ["ls-files", "-u", "--", path],
            in: repositoryURL,
            defaultErrorMessage: "无法读取合并冲突状态"
        )

        return Set(
            output
                .split(separator: "\n")
                .compactMap { line in
                    let components = line.split(maxSplits: 3, omittingEmptySubsequences: true) {
                        $0 == " " || $0 == "\t"
                    }
                    guard components.count >= 3 else { return nil }
                    return Int(components[2])
                }
        )
    }

    public func abortMerge() throws {
        try LibGit2.abortMerge(at: repositoryURL.path)
    }

    public func continueMerge() throws {
        let branchName = (try? getCurrentMergeBranchName()) ?? "MERGE_HEAD"
        try LibGit2.continueMerge(branchName: branchName, at: repositoryURL.path, verbose: false)
    }

    private func readGitPathFile(_ relativeGitPath: String) throws -> String? {
        let fileURL = try gitPath(relativeGitPath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try String(contentsOf: fileURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func gitPath(_ relativeGitPath: String) throws -> URL {
        let gitDirectory = try LibGit2.gitDirectory(at: repositoryURL.path)
        return URL(fileURLWithPath: gitDirectory, isDirectory: true)
            .appendingPathComponent(relativeGitPath)
            .standardizedFileURL
    }

    private func readFileIfExists(_ url: URL) throws -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isTrackedInHead(_ filePath: String) throws -> Bool {
        (try? LibGit2.getFileContent(atCommit: "HEAD", file: filePath, at: repositoryURL.path)) != nil
    }

    private func removeWorkingTreeItem(_ filePath: String) throws {
        let repoURL = repositoryURL.standardizedFileURL
        let targetURL = URL(fileURLWithPath: filePath, relativeTo: repoURL).standardizedFileURL

        guard targetURL.path == repoURL.path || targetURL.path.hasPrefix(repoURL.path + "/") else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "非法文件路径: \(filePath)"]
            )
        }

        guard FileManager.default.fileExists(atPath: targetURL.path) else { return }
        try FileManager.default.removeItem(at: targetURL)
    }

    private func branchCompareCommits(base: String, head: String) throws -> [GitBranchCompareCommit] {
        try mapBranchCompare(base: base, head: head).commits
    }

    private func branchCompareFiles(base: String, head: String) throws -> [GitBranchCompareFile] {
        try mapBranchCompare(base: base, head: head).files
    }

    private func trackedFilePaths() throws -> [String] {
        try LibGit2.getDiffFileList(at: repositoryURL.path, staged: true).map(\.file)
    }

    private func fileHasLFSFilterAttribute(_ filePath: String) throws -> Bool {
        false
    }

    private func indexStoresLFSPointer(_ filePath: String) throws -> Bool {
        false
    }

    private func submoduleEnvironment(allowFileProtocol: Bool) -> [String: String] {
        guard allowFileProtocol else { return [:] }
        return ["GIT_ALLOW_PROTOCOL": "file:git:ssh:https:http"]
    }

    private func libGit2ConflictVersion(_ version: GitMergeFileVersion) -> GitConflictFileVersion {
        switch version {
        case .base:
            return .base
        case .ours:
            return .ours
        case .theirs:
            return .theirs
        }
    }

    private func gitCoreSubmoduleStatus(_ status: GitSubmoduleInfo.Status) -> GitSubmodule.Status {
        switch status {
        case .initialized:
            return .initialized
        case .uninitialized:
            return .uninitialized
        case .modified:
            return .modified
        case .conflicted:
            return .conflicted
        }
    }

    private func mapBranchCompare(base: String, head: String) throws -> GitBranchCompare {
        let value = try LibGit2.compareBranches(base: base, head: head, at: repositoryURL.path)
        return GitBranchCompare(
            base: value.base,
            head: value.head,
            ahead: value.ahead,
            behind: value.behind,
            commits: value.commits.map {
                GitBranchCompareCommit(hash: $0.hash, author: $0.author, date: $0.date, subject: $0.subject)
            },
            files: value.files.map {
                GitBranchCompareFile(status: $0.status, path: $0.path, oldPath: $0.oldPath)
            }
        )
    }

    private static func writeCreateRepositoryFiles(at repositoryURL: URL, options: CreateRepositoryOptions) throws {
        if let readmeContent = options.readmeContent {
            try writeFileIfNeeded(repositoryURL.appendingPathComponent("README.md"), content: readmeContent)
        }

        if let gitignoreContent = options.gitignoreContent {
            try writeFileIfNeeded(repositoryURL.appendingPathComponent(".gitignore"), content: gitignoreContent)
        }

        if let licenseContent = options.licenseContent {
            try writeFileIfNeeded(repositoryURL.appendingPathComponent("LICENSE"), content: licenseContent)
        }
    }

    private static func writeFileIfNeeded(_ url: URL, content: String) throws {
        guard FileManager.default.fileExists(atPath: url.path) == false else { return }
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func relativePath(for fileURL: URL, in repositoryURL: URL) -> String {
        let repositoryPath = repositoryURL.path
        let filePath = fileURL.path

        guard filePath.hasPrefix(repositoryPath + "/") else {
            return fileURL.lastPathComponent
        }

        return String(filePath.dropFirst(repositoryPath.count + 1))
    }

    @discardableResult
    private static func runGit(_ arguments: [String], in repositoryURL: URL, defaultErrorMessage: String) throws -> String {
        let outputData = try runGitData(arguments, in: repositoryURL, defaultErrorMessage: defaultErrorMessage)
        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @discardableResult
    private static func runGitData(_ arguments: [String], in repositoryURL: URL, defaultErrorMessage: String) throws -> Data {
        guard let gitPath = gitCLIPath() else {
            throw nativeGitUnavailableError(arguments: arguments)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = arguments
        process.currentDirectoryURL = repositoryURL

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        let outputCollector = ProcessOutputCollector(maxBytes: maxGitCommandOutputBytes)
        let errorCollector = ProcessOutputCollector(maxBytes: maxGitCommandErrorBytes)
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            outputCollector.append(handle.availableData)
        }
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            errorCollector.append(handle.availableData)
        }

        defer {
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
        }

        try process.run()
        process.waitUntilExit()

        outputCollector.append(outputPipe.fileHandleForReading.readDataToEndOfFile())
        errorCollector.append(errorPipe.fileHandleForReading.readDataToEndOfFile())

        let outputData = outputCollector.dataValue
        let errorData = errorCollector.dataValue
        let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if outputCollector.isTruncated {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Git command output exceeded \(maxGitCommandOutputBytes / 1024 / 1024) MB: \(arguments.joined(separator: " "))"
                ]
            )
        }

        if process.terminationStatus != 0 {
            var message = errorOutput.isEmpty ? defaultErrorMessage : errorOutput
            if errorCollector.isTruncated {
                message += "\n\nGit command error output was truncated."
            }
            throw NSError(
                domain: "GitOK.GitCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        return outputData
    }

    /// 使用系统 git CLI 执行推送（网络错误降级方案）
    /// - Parameters:
    ///   - remote: 远程仓库名称
    ///   - branch: 分支名称（nil 表示使用当前分支）
    /// - Throws: git CLI 不存在或推送失败时抛出错误
    public func cliPush(remote: String = "origin", branch: String? = nil) throws {
        guard Self.isGitCLIAvailable() else {
            throw Self.nativeGitUnavailableError(arguments: ["push", remote, branch ?? ""])
        }

        // 获取当前分支名（如果未指定）
        let effectiveBranch: String
        if let branch {
            effectiveBranch = branch
        } else {
            let branchOutput = try Self.runGit(
                ["branch", "--show-current"],
                in: repositoryURL,
                defaultErrorMessage: "Failed to get current branch"
            )
            effectiveBranch = branchOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard effectiveBranch.isEmpty == false else {
                throw NSError(
                    domain: "GitOK.GitCommand",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot determine current branch"]
                )
            }
        }

        try Self.runGit(
            ["push", "-u", remote, effectiveBranch],
            in: repositoryURL,
            defaultErrorMessage: "Git CLI push failed"
        )
    }
}

private final class ProcessOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private var pendingText = ""
    private let progress: (@Sendable (String) -> Void)?
    private let maxBytes: Int?
    private var truncated = false

    init(maxBytes: Int? = nil, progress: (@Sendable (String) -> Void)? = nil) {
        self.maxBytes = maxBytes
        self.progress = progress
    }

    var output: String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: data, encoding: .utf8) ?? ""
    }

    var dataValue: Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }

    var isTruncated: Bool {
        lock.lock()
        defer { lock.unlock() }
        return truncated
    }

    func append(_ chunk: Data) {
        guard chunk.isEmpty == false else { return }

        let text = String(data: chunk, encoding: .utf8) ?? ""
        let progressLines: [String]

        lock.lock()
        if let maxBytes {
            let remainingBytes = maxBytes - data.count
            if remainingBytes > 0 {
                data.append(chunk.prefix(remainingBytes))
            }
            if chunk.count > remainingBytes {
                truncated = true
            }
        } else {
            data.append(chunk)
        }
        guard progress != nil else {
            lock.unlock()
            return
        }
        pendingText += text

        let separators = CharacterSet(charactersIn: "\n\r")
        let parts = pendingText.components(separatedBy: separators)
        pendingText = parts.last ?? ""
        progressLines = parts.dropLast().map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        lock.unlock()

        for line in progressLines where line.isEmpty == false {
            progress?(line)
        }
    }
}
