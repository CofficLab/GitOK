import Foundation

struct GitRepositoryCLI {
    let repositoryURL: URL

    init(repositoryURL: URL) {
        self.repositoryURL = repositoryURL
    }

    func stashSave(message: String? = nil) throws {
        var arguments = ["stash", "push", "--include-untracked"]
        if let message, message.isEmpty == false {
            arguments += ["-m", message]
        }
        _ = try runGit(arguments)
    }

    func stashList() throws -> [GitStashEntry] {
        let output = try runGit(["stash", "list", "--format=%gd%x1f%s"])
        return GitParsers.parseStashList(output)
    }

    func stashApply(index: Int) throws {
        _ = try runGit(["stash", "apply", "stash@{\(index)}"])
    }

    func stashPop(index: Int) throws {
        _ = try runGit(["stash", "pop", "stash@{\(index)}"])
    }

    func stashDrop(index: Int) throws {
        _ = try runGit(["stash", "drop", "stash@{\(index)}"])
    }

    func addFiles(_ filePaths: [String]) throws {
        guard filePaths.isEmpty == false else { return }
        _ = try runGit(["add", "--"] + filePaths)
    }

    func isMerging() throws -> Bool {
        let mergeHead = try runGit(["rev-parse", "-q", "--verify", "MERGE_HEAD"], allowNonZeroExit: true)
        return mergeHead.isEmpty == false
    }

    func getCurrentMergeBranchName() throws -> String? {
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

    func getMergeConflictFiles() throws -> [String] {
        let output = try runGit(["diff", "--name-only", "--diff-filter=U"])
        guard output.isEmpty == false else { return [] }
        return output.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    func statusEntries() throws -> [GitStatusEntry] {
        let output = try runGit(["status", "--porcelain=v1"])
        return GitParsers.parseStatusEntries(output)
    }

    func mergeResolutionFiles() throws -> [GitMergeFile] {
        let unresolvedPaths = Set(try getMergeConflictFiles())
        return GitParsers.classifyMergeFiles(
            unresolvedPaths: unresolvedPaths,
            statusEntries: try statusEntries()
        )
    }

    func canContinueMerge() throws -> Bool {
        let files = try mergeResolutionFiles()
        return files.isEmpty == false && files.allSatisfy { $0.state == .staged }
    }

    func abortMerge() throws {
        _ = try runGit(["merge", "--abort"])
    }

    func continueMerge() throws {
        _ = try runGit(
            ["-c", "core.editor=true", "merge", "--continue"],
            environment: ["GIT_EDITOR": "true"]
        )
    }

    func runGit(_ arguments: [String], allowNonZeroExit: Bool = false, environment: [String: String] = [:]) throws -> String {
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

        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func readGitPathFile(_ relativeGitPath: String) throws -> String? {
        let output = try runGit(["rev-parse", "--git-path", relativeGitPath])
        let fileURL = URL(fileURLWithPath: output, relativeTo: repositoryURL).standardizedFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try String(contentsOf: fileURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
