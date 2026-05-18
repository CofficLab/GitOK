import Foundation

public enum CloneRepositoryValidation {
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

    private static func looksLikeGitHubShortcut(_ value: String) -> Bool {
        guard value.contains("://") == false else { return false }
        guard value.hasPrefix("git@") == false else { return false }
        let parts = value.split(separator: "/")
        return parts.count == 2 && parts.allSatisfy { $0.isEmpty == false }
    }
}

public struct GitRepositoryCLI {
    public let repositoryURL: URL

    public init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
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

    public static func clone(remoteURL: String, destinationURL: URL) throws {
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
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            if destinationExistsBeforeClone == false {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            let message = stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                : stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "GitOK.GitCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "Git clone 执行失败" : message]
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

    public func stashSave(message: String? = nil) throws {
        var arguments = ["stash", "push", "--include-untracked"]
        if let message, message.isEmpty == false {
            arguments += ["-m", message]
        }
        _ = try runGit(arguments)
    }

    public func stashList() throws -> [GitStashEntry] {
        let output = try runGit(["stash", "list", "--format=%gd%x1f%s"])
        return GitParsers.parseStashList(output)
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

    public func fetch(remote: String = "origin") throws {
        _ = try runGit(["fetch", "--prune", remote])
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
        trimOutput: Bool = true
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
