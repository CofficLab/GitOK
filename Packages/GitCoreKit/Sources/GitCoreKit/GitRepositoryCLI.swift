import Foundation

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
        try runGitConfig(["config", "--global", "--get", key], allowNonZeroExit: true)
    }

    private static func writeGlobalGitConfig(_ key: String, value: String?) throws {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if trimmed.isEmpty {
            _ = try runGitConfig(["config", "--global", "--unset", key], allowNonZeroExit: true)
        } else {
            _ = try runGitConfig(["config", "--global", key, trimmed], allowNonZeroExit: false)
        }
    }

    @discardableResult
    private static func runGitConfig(_ arguments: [String], allowNonZeroExit: Bool) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard allowNonZeroExit || process.terminationStatus == 0 else {
            let message = stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "GitOK.GitCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "读取 Git 网络配置失败" : message]
            )
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct GitRepositoryCLI {
    public let repositoryURL: URL

    public init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
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

        try runGit(["init"], in: repositoryURL, defaultErrorMessage: "git init 命令执行失败")
    }

    public static func create(at repositoryURL: URL, options: CreateRepositoryOptions = CreateRepositoryOptions()) throws {
        let destinationExistsBeforeCreate = FileManager.default.fileExists(atPath: repositoryURL.path)

        do {
            try initialize(at: repositoryURL)
            try writeCreateRepositoryFiles(at: repositoryURL, options: options)

            if let userName = options.userName?.trimmingCharacters(in: .whitespacesAndNewlines), userName.isEmpty == false {
                try runGit(["config", "user.name", userName], in: repositoryURL, defaultErrorMessage: "设置 git user.name 失败")
            }

            if let userEmail = options.userEmail?.trimmingCharacters(in: .whitespacesAndNewlines), userEmail.isEmpty == false {
                try runGit(["config", "user.email", userEmail], in: repositoryURL, defaultErrorMessage: "设置 git user.email 失败")
            }

            if let message = options.initialCommitMessage?.trimmingCharacters(in: .whitespacesAndNewlines), message.isEmpty == false {
                try runGit(["add", "."], in: repositoryURL, defaultErrorMessage: "添加初始文件失败")
                try runGit(["commit", "--allow-empty", "-m", message], in: repositoryURL, defaultErrorMessage: "创建初始提交失败")
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
        let parentURL = destinationURL.deletingLastPathComponent()
        let destinationExistsBeforeClone = FileManager.default.fileExists(atPath: destinationURL.path)

        if FileManager.default.fileExists(atPath: parentURL.path) == false {
            try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
        }

        let process = Process()
        process.currentDirectoryURL = parentURL
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "clone", remoteURL, destinationURL.path]
        process.environment = {
            var env = ProcessInfo.processInfo.environment
            env["GIT_TERMINAL_PROMPT"] = "0"
            env["GIT_ASKPASS"] = "true"
            return env
        }()

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let outputCollector = ProcessOutputCollector(progress: progress)
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            outputCollector.append(handle.availableData)
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            outputCollector.append(handle.availableData)
        }

        try process.run()
        process.waitUntilExit()

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
        outputCollector.append(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
        outputCollector.append(stderrPipe.fileHandleForReading.readDataToEndOfFile())
        let output = outputCollector.output

        guard process.terminationStatus == 0 else {
            if destinationExistsBeforeClone == false {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            throw NSError(
                domain: "GitOK.GitCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: CloneRepositoryValidation.cloneFailureMessage(from: output)]
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

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "credential", "approve"]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let input = """
        protocol=\(scheme)
        host=\(trimmedHost)
        username=\(trimmedUsername)
        password=\(password)

        """
        if let data = input.data(using: .utf8) {
            stdinPipe.fileHandleForWriting.write(data)
        }
        stdinPipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let message = stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "GitOK.GitCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "保存 Git 凭据失败" : message]
            )
        }
    }

    public func stashSave(message: String? = nil) throws {
        var arguments = ["stash", "push", "--include-untracked"]
        if let message, message.isEmpty == false {
            arguments += ["-m", message]
        }
        _ = try runGit(arguments)
    }

    public func stashList() throws -> [GitStashEntry] {
        let output = try runGit(["stash", "list", "--format=%gd%x1f%cr%x1f%gs"])
        return try GitParsers.parseStashList(output).map { entry in
            let files = try stashChangedFiles(index: entry.index)
            let preview = try stashDiffPreview(index: entry.index)
            return GitStashEntry(
                index: entry.index,
                message: entry.message,
                branchName: entry.branchName,
                relativeDate: entry.relativeDate,
                changedFileCount: files.count,
                diffPreview: preview
            )
        }
    }

    public func stashApply(index: Int) throws {
        _ = try runGit(["stash", "apply", "stash@{\(index)}"])
    }

    public func stashPop(index: Int) throws {
        _ = try runGit(["stash", "pop", "stash@{\(index)}"])
    }

    public func stashDrop(index: Int) throws {
        _ = try runGit(["stash", "drop", "stash@{\(index)}"])
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

        _ = try runGit(["stash", "branch", trimmedName, "stash@{\(index)}"])
    }

    private func stashChangedFiles(index: Int) throws -> [String] {
        let output = try runGit(
            ["stash", "show", "--include-untracked", "--name-only", "--format=", "stash@{\(index)}"],
            allowNonZeroExit: true,
            trimOutput: false
        )

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private func stashDiffPreview(index: Int) throws -> String {
        let output = try runGit(
            ["stash", "show", "--include-untracked", "--patch", "--stat", "--color=never", "stash@{\(index)}"],
            allowNonZeroExit: true,
            trimOutput: false
        )
        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).prefix(120)
        return lines.joined(separator: "\n")
    }

    public func fetch(remote: String = "origin") throws {
        _ = try runGit(["fetch", "--prune", remote])
    }

    public func submodules() throws -> [GitSubmodule] {
        let output = try runGit(["submodule", "status", "--recursive"], allowNonZeroExit: true, trimOutput: false)
        return Self.parseSubmoduleStatus(output)
    }

    public static func parseSubmoduleStatus(_ output: String) -> [GitSubmodule] {
        output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { parseSubmoduleStatusLine(String($0)) }
            .sorted { $0.path < $1.path }
    }

    public func initializeSubmodules(paths: [String] = [], recursive: Bool = true, allowFileProtocol: Bool = false) throws {
        var arguments = ["submodule", "update", "--init"]
        if recursive {
            arguments.append("--recursive")
        }
        if paths.isEmpty == false {
            arguments.append("--")
            arguments.append(contentsOf: paths)
        }
        _ = try runGit(arguments, environment: submoduleEnvironment(allowFileProtocol: allowFileProtocol))
    }

    public func updateSubmodules(paths: [String] = [], recursive: Bool = true, allowFileProtocol: Bool = false) throws {
        var arguments = ["submodule", "update", "--remote", "--merge"]
        if recursive {
            arguments.append("--recursive")
        }
        if paths.isEmpty == false {
            arguments.append("--")
            arguments.append(contentsOf: paths)
        }
        _ = try runGit(arguments, environment: submoduleEnvironment(allowFileProtocol: allowFileProtocol))
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

        return try runGit(["diff", "--submodule=log", "--", trimmedPath], trimOutput: false)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func lfsStatus() -> GitLFSStatus {
        guard let output = try? runGit(["lfs", "version"]) else {
            return GitLFSStatus(isAvailable: false, version: nil)
        }

        return GitLFSStatus(
            isAvailable: true,
            version: Self.parseLFSVersion(from: output)
        )
    }

    public static func parseLFSVersion(from output: String) -> String? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("git-lfs/") else { return nil }

        let version = trimmed
            .dropFirst("git-lfs/".count)
            .split(separator: " ")
            .first
            .map(String.init)

        return version?.isEmpty == false ? version : nil
    }

    public func initializeLFS() throws {
        _ = try runGit(["lfs", "install", "--local"])
    }

    public func lfsLargeFileCandidates(thresholdBytes: Int64 = 50 * 1024 * 1024) throws -> [GitLFSLargeFileCandidate] {
        guard thresholdBytes > 0 else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "大文件阈值必须大于 0"]
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
        }

        return candidates.sorted {
            if $0.byteSize == $1.byteSize {
                return $0.path < $1.path
            }
            return $0.byteSize > $1.byteSize
        }
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

    public static func isLFSPointerBlob(_ content: String) -> Bool {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first == "version https://git-lfs.github.com/spec/v1" else { return false }

        let hasOID = lines.contains { line in
            line.range(of: #"^oid sha256:[0-9a-f]{64}$"#, options: .regularExpression) != nil
        }
        let hasSize = lines.contains { line in
            line.range(of: #"^size [0-9]+$"#, options: .regularExpression) != nil
        }

        return hasOID && hasSize
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

        let currentBranch = try runGit(["branch", "--show-current"])
        guard currentBranch != trimmedName else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "不能删除当前分支"]
            )
        }

        _ = try runGit(["branch", "-d", trimmedName])
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

        _ = try runGit(["check-ref-format", "--branch", trimmedNewName])
        _ = try runGit(["branch", "-m", trimmedCurrentName, trimmedNewName])
    }

    public func remoteBranches(remote: String? = nil) throws -> [String] {
        let output = try runGit(["branch", "-r", "--format=%(refname:short)"])
        let trimmedRemote = remote?.trimmingCharacters(in: .whitespacesAndNewlines)

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false && $0.hasSuffix("/HEAD") == false }
            .filter { branch in
                guard let trimmedRemote, trimmedRemote.isEmpty == false else { return true }
                return branch.hasPrefix(trimmedRemote + "/")
            }
            .sorted()
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

        _ = try runGit(["branch", "--set-upstream-to=\(trimmedUpstreamBranch)", trimmedLocalBranch])
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

        _ = try runGit(["branch", "--unset-upstream", trimmedLocalBranch])
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

        _ = try runGit(["push", trimmedRemote, "--delete", shortBranchName])
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

        let destinationBranch = (trimmedRemoteBranch?.isEmpty == false ? trimmedRemoteBranch : nil) ?? trimmedLocalBranch
        _ = try runGit(["push", "-u", trimmedRemote, "\(trimmedLocalBranch):\(destinationBranch)"])
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

        _ = try runGit(["rev-parse", "--verify", trimmedBase])
        _ = try runGit(["rev-parse", "--verify", trimmedHead])

        let countsOutput = try runGit(["rev-list", "--left-right", "--count", "\(trimmedBase)...\(trimmedHead)"])
        let counts = countsOutput
            .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .compactMap { Int($0) }
        let behind = counts.first ?? 0
        let ahead = counts.dropFirst().first ?? 0

        let commits = try branchCompareCommits(base: trimmedBase, head: trimmedHead)
        let files = try branchCompareFiles(base: trimmedBase, head: trimmedHead)

        return GitBranchCompare(
            base: trimmedBase,
            head: trimmedHead,
            ahead: ahead,
            behind: behind,
            commits: commits,
            files: files
        )
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

    public func isRebasing() throws -> Bool {
        try rebaseStatus().isRebasing
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

        _ = try runGit(["checkout", trimmedBranch])
        _ = try runGit(["rebase", trimmedUpstream])
    }

    public func continueRebase() throws {
        _ = try runGit(
            ["-c", "core.editor=true", "rebase", "--continue"],
            environment: ["GIT_EDITOR": "true"]
        )
    }

    public func abortRebase() throws {
        _ = try runGit(["rebase", "--abort"])
    }

    public func cherryPickStatus() throws -> GitCherryPickStatus {
        guard let commitHash = try readGitPathFile("CHERRY_PICK_HEAD"), commitHash.isEmpty == false else {
            return .inactive
        }
        return GitCherryPickStatus(isCherryPicking: true, commitHash: commitHash)
    }

    public func isCherryPicking() throws -> Bool {
        try cherryPickStatus().isCherryPicking
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
            _ = try runGit(["checkout", trimmedBranch])
        }

        _ = try runGit(["cherry-pick"] + trimmedCommits)
    }

    public func continueCherryPick() throws {
        _ = try runGit(
            ["-c", "core.editor=true", "cherry-pick", "--continue"],
            environment: ["GIT_EDITOR": "true"]
        )
    }

    public func abortCherryPick() throws {
        _ = try runGit(["cherry-pick", "--abort"])
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

        _ = try runGit(["revert", "--no-edit", trimmedHash])
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

        _ = try runGit(["reset", "--\(mode.rawValue)", trimmedHash])
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

        _ = try runGit(["reset", "--soft", "HEAD~\(count)"])
        _ = try runGit(["commit", "-m", trimmedMessage])
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

        _ = try runGit(["check-ref-format", "--allow-onelevel", trimmedName])
        _ = try runGit(["tag", trimmedName, trimmedHash])
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

        _ = try runGit(["check-ref-format", "--allow-onelevel", trimmedName])
        _ = try runGit(["tag", "-a", trimmedName, trimmedHash, "-m", trimmedMessage])
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

        _ = try runGit(["tag", "-d", trimmedName])
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

        _ = try runGit(["push", trimmedRemote, trimmedName])
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

        _ = try runGit(["push", trimmedRemote, ":refs/tags/\(trimmedName)"])
    }

    public func aheadBehind() throws -> GitAheadBehind {
        let upstream = try runGit(
            ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"],
            allowNonZeroExit: true
        )

        guard upstream.isEmpty == false else {
            return .noUpstream
        }

        let output = try runGit(["rev-list", "--left-right", "--count", "HEAD...@{upstream}"])
        guard let counts = GitParsers.parseAheadBehindCounts(output) else {
            throw NSError(
                domain: "GitOK.GitCommand",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法解析 ahead/behind 状态：\(output)"]
            )
        }

        return GitAheadBehind(ahead: counts.ahead, behind: counts.behind, hasUpstream: true)
    }

    public func addFiles(_ filePaths: [String]) throws {
        guard filePaths.isEmpty == false else { return }
        _ = try runGit(["add", "--"] + filePaths)
    }

    public func fileDiff(_ filePath: String, staged: Bool, ignoreWhitespace: Bool = false) throws -> String {
        var arguments = ["diff", "--no-ext-diff", "--color=never"]
        if staged {
            arguments.append("--cached")
        }
        if ignoreWhitespace {
            arguments.append("--ignore-all-space")
        }
        arguments += ["--", filePath]
        return try runGit(arguments, trimOutput: false)
    }

    public func applyPatch(_ patch: String, mode: GitPatchApplyMode) throws {
        let normalizedPatch = patch.hasSuffix("\n") ? patch : patch + "\n"
        var arguments = ["apply", "--cached", "--whitespace=nowarn"]
        if mode == .unstage {
            arguments.append("--reverse")
        }
        _ = try runGit(arguments, standardInput: normalizedPatch)
    }

    public func unstageFiles(_ filePaths: [String]) throws {
        guard filePaths.isEmpty == false else { return }

        do {
            _ = try runGit(["restore", "--staged", "--"] + filePaths)
        } catch {
            _ = try runGit(["rm", "--cached", "-r", "--"] + filePaths)
        }
    }

    public func discardFileChanges(_ filePath: String) throws {
        let trackedInHead = try isTrackedInHead(filePath)

        if trackedInHead {
            _ = try runGit(["restore", "--staged", "--worktree", "--", filePath])
            return
        }

        _ = try runGit(["rm", "--cached", "-r", "--ignore-unmatch", "--", filePath])
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
            _ = try runGit(["restore", "--staged", "--worktree", "--"] + trackedPaths)
        }

        if newPaths.isEmpty == false {
            _ = try runGit(["rm", "--cached", "-r", "--ignore-unmatch", "--"] + newPaths)
            for path in newPaths {
                try removeWorkingTreeItem(path)
            }
        }

        _ = try runGit(["clean", "-fd", "--"])
    }

    public func isMerging() throws -> Bool {
        let mergeHead = try runGit(["rev-parse", "-q", "--verify", "MERGE_HEAD"], allowNonZeroExit: true)
        return mergeHead.isEmpty == false
    }

    public func getCurrentMergeBranchName() throws -> String? {
        guard try isMerging() else { return nil }

        if let mergeHead = try? runGit(["rev-parse", "--verify", "MERGE_HEAD"]),
           let resolvedName = try? runGit(["name-rev", "--name-only", "--exclude=tags/*", mergeHead]),
           resolvedName.isEmpty == false,
           resolvedName != "undefined" {
            return resolvedName
                .replacingOccurrences(of: "remotes/origin/", with: "")
                .replacingOccurrences(of: "heads/", with: "")
        }

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
        let output = try runGit(["diff", "--name-only", "--diff-filter=U"])
        guard output.isEmpty == false else { return [] }
        return output.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    public func statusEntries() throws -> [GitStatusEntry] {
        let output = try runGit(["status", "--porcelain=v1"], trimOutput: false)
        return GitParsers.parseStatusEntries(output)
    }

    public func mergeResolutionFiles() throws -> [GitMergeFile] {
        let unresolvedPaths = Set(try getMergeConflictFiles())
        return GitParsers.classifyMergeFiles(
            unresolvedPaths: unresolvedPaths,
            statusEntries: try statusEntries()
        )
    }

    public func mergeFileContent(path: String, version: GitMergeFileVersion) throws -> String {
        try runGit(["show", ":\(version.stageNumber):\(path)"], trimOutput: false)
    }

    public func mergeFileDiff(path: String) throws -> String {
        try runGit(["diff", "--cc", "--color=never", "--", path], allowNonZeroExit: true, trimOutput: false)
    }

    public func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion) throws {
        switch version {
        case .ours:
            _ = try runGit(["checkout", "--ours", "--", path])
        case .theirs:
            _ = try runGit(["checkout", "--theirs", "--", path])
        case .base:
            let content = try mergeFileContent(path: path, version: .base)
            let targetURL = repositoryURL.appendingPathComponent(path)
            try FileManager.default.createDirectory(
                at: targetURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try content.write(to: targetURL, atomically: true, encoding: .utf8)
        }
    }

    public func canContinueMerge() throws -> Bool {
        let files = try mergeResolutionFiles()
        return files.isEmpty == false && files.allSatisfy { $0.state == .staged }
    }

    public func abortMerge() throws {
        _ = try runGit(["merge", "--abort"])
    }

    public func continueMerge() throws {
        _ = try runGit(
            ["-c", "core.editor=true", "merge", "--continue"],
            environment: ["GIT_EDITOR": "true"]
        )
    }

    public func runGit(
        _ arguments: [String],
        allowNonZeroExit: Bool = false,
        environment: [String: String] = [:],
        trimOutput: Bool = true,
        standardInput: String? = nil
    ) throws -> String {
        let process = Process()
        process.currentDirectoryURL = repositoryURL
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments

        var processEnvironment = ProcessInfo.processInfo.environment
        environment.forEach { processEnvironment[$0.key] = $0.value }
        process.environment = processEnvironment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        if standardInput != nil {
            process.standardInput = Pipe()
        }

        try process.run()
        if let standardInput,
           let stdinPipe = process.standardInput as? Pipe,
           let inputData = standardInput.data(using: .utf8) {
            stdinPipe.fileHandleForWriting.write(inputData)
            stdinPipe.fileHandleForWriting.closeFile()
        }
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard allowNonZeroExit || process.terminationStatus == 0 else {
            let message = stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "GitOK.GitCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "Git 命令执行失败" : message]
            )
        }

        return trimOutput ? stdout.trimmingCharacters(in: .whitespacesAndNewlines) : stdout
    }

    private func readGitPathFile(_ relativeGitPath: String) throws -> String? {
        let output = try runGit(["rev-parse", "--git-path", relativeGitPath])
        let fileURL = URL(fileURLWithPath: output, relativeTo: repositoryURL).standardizedFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try String(contentsOf: fileURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func gitPath(_ relativeGitPath: String) throws -> URL {
        let output = try runGit(["rev-parse", "--git-path", relativeGitPath])
        return URL(fileURLWithPath: output, relativeTo: repositoryURL).standardizedFileURL
    }

    private func readFileIfExists(_ url: URL) throws -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isTrackedInHead(_ filePath: String) throws -> Bool {
        let output = try runGit(["ls-tree", "-r", "--name-only", "HEAD", "--", filePath], allowNonZeroExit: true)
        return output.split(separator: "\n").contains { $0 == filePath }
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
        let output = try runGit([
            "log",
            "--format=%H%x1f%an <%ae>%x1f%aI%x1f%s",
            "\(base)..\(head)",
        ])

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatter = ISO8601DateFormatter()

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                let parts = line.split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
                guard parts.count >= 4 else { return nil }
                let date = fractionalFormatter.date(from: parts[2]) ?? formatter.date(from: parts[2]) ?? Date(timeIntervalSince1970: 0)
                return GitBranchCompareCommit(
                    hash: parts[0],
                    author: parts[1],
                    date: date,
                    subject: parts[3]
                )
            }
    }

    private func branchCompareFiles(base: String, head: String) throws -> [GitBranchCompareFile] {
        let output = try runGit(["diff", "--name-status", "\(base)...\(head)"])

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                let parts = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                guard parts.count >= 2 else { return nil }

                let status = parts[0]
                if status.hasPrefix("R") || status.hasPrefix("C") {
                    guard parts.count >= 3 else { return nil }
                    return GitBranchCompareFile(status: status, path: parts[2], oldPath: parts[1])
                }

                return GitBranchCompareFile(status: status, path: parts[1])
            }
            .sorted { lhs, rhs in
                if lhs.path == rhs.path {
                    return lhs.status < rhs.status
                }
                return lhs.path < rhs.path
            }
    }

    private func trackedFilePaths() throws -> [String] {
        let output = try runGit(["ls-files", "-z"], trimOutput: false)
        return output
            .split(separator: "\0", omittingEmptySubsequences: true)
            .map(String.init)
    }

    private func fileHasLFSFilterAttribute(_ filePath: String) throws -> Bool {
        let output = try runGit(["check-attr", "filter", "--", filePath])
        return output.hasSuffix(": filter: lfs")
    }

    private func indexStoresLFSPointer(_ filePath: String) throws -> Bool {
        let blobReference = ":\(filePath)"
        let sizeOutput = try runGit(["cat-file", "-s", blobReference], allowNonZeroExit: true)
        guard let byteSize = Int64(sizeOutput), byteSize <= 1024 else { return false }

        let content = try runGit(["cat-file", "blob", blobReference], allowNonZeroExit: true, trimOutput: false)
        return Self.isLFSPointerBlob(content)
    }

    private func submoduleEnvironment(allowFileProtocol: Bool) -> [String: String] {
        guard allowFileProtocol else { return [:] }
        return ["GIT_ALLOW_PROTOCOL": "file:git:ssh:https:http"]
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

    private static func parseSubmoduleStatusLine(_ line: String) -> GitSubmodule? {
        guard line.count >= 42 else { return nil }

        let marker = line[line.startIndex]
        let hashStart = line.index(after: line.startIndex)
        let hashEnd = line.index(hashStart, offsetBy: 40)
        let commitHash = String(line[hashStart..<hashEnd])

        guard commitHash.range(of: #"^[0-9a-fA-F]{40}$"#, options: .regularExpression) != nil else {
            return nil
        }

        let details = line[hashEnd...].trimmingCharacters(in: .whitespacesAndNewlines)
        guard details.isEmpty == false else { return nil }

        let path: String
        let description: String?
        if let descriptionRange = details.range(of: #" \(.+\)$"#, options: .regularExpression) {
            path = String(details[..<descriptionRange.lowerBound])
            description = String(details[descriptionRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        } else {
            path = details
            description = nil
        }

        return GitSubmodule(
            path: path,
            commitHash: commitHash,
            status: submoduleStatus(for: marker),
            description: description
        )
    }

    private static func submoduleStatus(for marker: Character) -> GitSubmodule.Status {
        switch marker {
        case "-":
            return .uninitialized
        case "+":
            return .modified
        case "U":
            return .conflicted
        default:
            return .initialized
        }
    }

    @discardableResult
    private static func runGit(_ arguments: [String], in repositoryURL: URL, defaultErrorMessage: String) throws -> String {
        let process = Process()
        process.currentDirectoryURL = repositoryURL
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            let message = stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "GitOK.GitCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? defaultErrorMessage : message]
            )
        }

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private final class ProcessOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private var pendingText = ""
    private let progress: (@Sendable (String) -> Void)?

    init(progress: (@Sendable (String) -> Void)?) {
        self.progress = progress
    }

    var output: String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func append(_ chunk: Data) {
        guard chunk.isEmpty == false else { return }

        let text = String(data: chunk, encoding: .utf8) ?? ""
        let progressLines: [String]

        lock.lock()
        data.append(chunk)
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
