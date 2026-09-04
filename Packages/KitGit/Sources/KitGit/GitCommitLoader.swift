import Foundation

/// 通过 git CLI 读取仓库提交历史的轻量加载器。
///
/// 执行 `git -C <目录> log` 并用 `\x1f` 分隔字段解析，避免 subject 中的
/// 空格 / 特殊字符影响解析。输出格式：
/// `%H\x1f%h\x1f%s\x1f%an\x1f%aI`（完整哈希 / 短哈希 / 主题 / 作者 / ISO 时间）。
///
/// 说明：当前阶段使用系统自带 git（macOS 预装）以零第三方依赖读取提交；
/// 后续若迁移到 LibGit2（旧版方案），只需替换本加载器的实现。
///
/// 本类型为无状态纯逻辑，可在任意线程调用（含后台线程），
/// 视图侧通过 `Task.detached` 使用，避免阻塞主线程。
public enum GitCommitLoader {

    /// 读取仓库最新 `limit` 条提交（按提交时间倒序）。
    /// - Throws: `GitCommitLoaderError`（非 git 仓库 / 命令失败 / 输出不可解析）。
    public static func loadCommits(in repository: URL, limit: Int = 50) throws -> [GitCommit] {
        let command = try buildCommand(in: repository, limit: limit)
        let output = try runGit(command, in: repository)
        // 显式按提交日期倒序：不依赖 git log 的默认输出顺序
        // （不同 git 配置 / 沙盒环境下默认顺序可能不一致）。
        return parse(output).sorted { $0.date > $1.date }
    }

    // MARK: - Command

    private static func buildCommand(in repository: URL, limit: Int) throws -> [String] {
        guard repository.hasDirectoryPath || FileManager.default.fileExists(atPath: repository.path) else {
            throw GitCommitLoaderError.notARepository(repository)
        }
        // 快速判定是否为 git 仓库：目录下存在 `.git` 或本身是 bare 仓库。
        let gitDir = repository.appendingPathComponent(".git")
        let isBare = FileManager.default.fileExists(atPath: repository.appendingPathComponent("HEAD").path)
        guard FileManager.default.fileExists(atPath: gitDir.path) || isBare else {
            throw GitCommitLoaderError.notARepository(repository)
        }
        return [
            "/usr/bin/git", "-C", repository.path,
            "log",
            "--format=\(format)",
            "-n", "\(limit)",
        ]
    }

    /// 字段分隔：`%H \x1f %h \x1f %s \x1f %an \x1f %aI \x1f %P \x1f %D`
    /// （完整哈希 / 短哈希 / 主题 / 作者 / ISO 时间 / 父哈希 / ref 名）。
    private static let format = "%H%x1f%h%x1f%s%x1f%an%x1f%aI%x1f%P%x1f%D"

    // MARK: - Process

    private static func runGit(_ command: [String], in repository: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command[0])
        process.arguments = Array(command.dropFirst())
        process.currentDirectoryURL = repository

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw GitCommitLoaderError.gitUnavailable(error.localizedDescription)
        }
        process.waitUntilExit()

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8) ?? "unknown error"
            throw GitCommitLoaderError.gitFailed(message)
        }
        return String(data: outputData, encoding: .utf8) ?? ""
    }

    // MARK: - Parse

    /// 解析 git log 输出为提交数组（按行拆分，`\x1f` 分隔字段）。
    static func parse(_ output: String) -> [GitCommit] {
        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        return lines.compactMap { line -> GitCommit? in
            let fields = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 5 else { return nil }
            let hash = fields[0]
            guard !hash.isEmpty, let date = ISO8601DateFormatter().date(from: fields[4]) else { return nil }
            let parents = fields.count > 5
                ? fields[5].split(separator: " ").map(String.init)
                : []
            let tags = fields.count > 6
                ? parseTags(from: fields[6])
                : []
            return GitCommit(
                hash: hash,
                shortHash: fields[1],
                message: fields[2],
                author: fields[3],
                date: date,
                parentHashes: parents,
                tags: tags
            )
        }
    }

    /// 从 git log `%D` 输出解析 tag 名。`%D` 形如 `HEAD -> main, tag: v1.0, origin/main`，
    /// 只提取 `tag: <name>` 部分，剔除 `<name>^{}` 的 peeled 标记。
    static func parseTags(from refNames: String) -> [String] {
        guard !refNames.isEmpty else { return [] }
        return refNames
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { ref -> String? in
                guard ref.hasPrefix("tag:") else { return nil }
                var name = ref.dropFirst(4).trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return nil }
                if name.hasSuffix("^{}") {
                    name.removeLast(3)
                }
                return name
            }
    }
}

/// Git 提交加载错误。
public enum GitCommitLoaderError: Error, Equatable, LocalizedError {
    case notARepository(URL)
    case gitUnavailable(String)
    case gitFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notARepository(let url):
            "该目录不是 Git 仓库：\(url.lastPathComponent)"
        case .gitUnavailable:
            "未找到 git 命令，请确认系统已安装 git"
        case .gitFailed(let message):
            message
        }
    }
}
