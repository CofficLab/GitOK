import Foundation

/// Git 克隆过程中的进度快照。
public struct GitCloneProgress: Equatable, Sendable {
    public enum Phase: String, Equatable, Sendable {
        case preparing
        case receivingObjects
        case resolvingDeltas
        case checkingOut
        case completed
    }

    public let phase: Phase
    /// 整个克隆流程的 0...1 进度；Git 尚未报告可计算进度时为 nil。
    public let fractionCompleted: Double?
    /// Git 输出中的当前阶段描述，可能为空。
    public let detail: String?

    public init(
        phase: Phase,
        fractionCompleted: Double? = nil,
        detail: String? = nil
    ) {
        self.phase = phase
        self.fractionCompleted = fractionCompleted
        self.detail = detail
    }
}

/// Git 仓库克隆操作。
public enum GitCloneOperation {
    /// 克隆远程仓库到本地目录。
    ///
    /// - Parameters:
    ///   - remoteURL: 远程仓库地址（https / ssh / git 协议）。
    ///   - destination: 目标目录（已存在的空目录或尚不存在的路径）。
    /// - Returns: 克隆完成后的本地仓库路径。
    public static func clone(
        remoteURL: String,
        destination: URL,
        onProgress: (@Sendable (GitCloneProgress) -> Void)? = nil,
        cancellation: GitProcessCancellation? = nil
    ) throws -> URL {
        try validateDestination(destination)
        // Git 在远程枚举/压缩以及首个大对象下载期间没有可靠的整体
        // 百分比；此时必须显示不确定进度，不能把“已开始”误报成 0%。
        onProgress?(.init(phase: .preparing))

        let parser = GitCloneProgressParser(onProgress: onProgress)
        try GitProcessRunner.stream(
            ["clone", "--progress", remoteURL, destination.path],
            in: FileManager.default.homeDirectoryForCurrentUser,
            cancellation: cancellation
        ) { _ in
            true
        } onErrorOutput: { data in
            parser.append(data)
        }
        parser.finish()
        onProgress?(.init(phase: .completed, fractionCompleted: 1))
        return destination
    }

    /// 校验克隆目标目录是否可用。
    public static func validateDestination(_ destination: URL) throws {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDirectory)
        if exists {
            guard isDirectory.boolValue else {
                throw GitCloneError.destinationNotDirectory
            }
            let isGitRepo = FileManager.default.fileExists(
                atPath: destination.appendingPathComponent(".git").path
            )
            guard !isGitRepo else {
                throw GitCloneError.destinationIsGitRepository
            }
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: destination.path)) ?? []
            guard contents.isEmpty else {
                throw GitCloneError.destinationNotEmpty
            }
        }
    }

    /// 从远程 URL 推断默认仓库名（去掉 .git 后缀的末段）。
    public static func defaultRepositoryName(from remoteURL: String) -> String? {
        let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // 支持 git@host:owner/repo.git 与 https://host/owner/repo.git
        let pathPart: String
        if let schemeRange = trimmed.range(of: "://") {
            pathPart = String(trimmed[schemeRange.upperBound...])
                .split(separator: "/")
                .dropFirst()
                .joined(separator: "/")
        } else if let colon = trimmed.firstIndex(of: ":") {
            pathPart = String(trimmed[trimmed.index(after: colon)...])
        } else {
            pathPart = trimmed
        }
        let name = pathPart
            .split(separator: "/")
            .last
            .map(String.init)?
            .replacingOccurrences(of: ".git", with: "")
        guard let name, !name.isEmpty else { return nil }
        return name
    }
}

/// 解析 Git 克隆过程中写入 stderr 的进度行。
private final class GitCloneProgressParser: @unchecked Sendable {
    private let onProgress: (@Sendable (GitCloneProgress) -> Void)?
    private let lock = NSLock()
    private var buffer = ""

    init(onProgress: (@Sendable (GitCloneProgress) -> Void)?) {
        self.onProgress = onProgress
    }

    func append(_ data: Data) {
        lock.lock()
        buffer.append(String(decoding: data, as: UTF8.self))
        let lines = consumeLines()
        lock.unlock()

        for line in lines {
            emit(line)
        }
    }

    func finish() {
        lock.lock()
        let line = buffer
        buffer.removeAll(keepingCapacity: false)
        lock.unlock()

        if !line.isEmpty {
            emit(line)
        }
    }

    private func consumeLines() -> [String] {
        var lines: [String] = []
        while let separator = buffer.firstIndex(where: { $0 == "\r" || $0 == "\n" }) {
            lines.append(String(buffer[..<separator]))
            buffer.removeSubrange(...separator)
            while let first = buffer.first, first == "\r" || first == "\n" {
                buffer.removeFirst()
            }
        }
        return lines
    }

    private func emit(_ rawLine: String) {
        let line = rawLine
            .replacingOccurrences(of: "\u{1B}[K", with: "")
            .replacingOccurrences(of: "\u{1B}[2K", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }

        let phase: GitCloneProgress.Phase
        if line.localizedCaseInsensitiveContains("receiving objects:") {
            phase = .receivingObjects
        } else if line.localizedCaseInsensitiveContains("resolving deltas:") {
            phase = .resolvingDeltas
        } else if line.localizedCaseInsensitiveContains("checking out files:") {
            phase = .checkingOut
        } else if line.localizedCaseInsensitiveContains("enumerating objects")
                    || line.localizedCaseInsensitiveContains("counting objects")
                    || line.localizedCaseInsensitiveContains("compressing objects")
                    || line.localizedCaseInsensitiveContains("remote:") {
            phase = .preparing
        } else {
            return
        }

        onProgress?(
            .init(
                phase: phase,
                fractionCompleted: overallFraction(for: phase, stageFraction: percentage(in: line)),
                detail: line
            )
        )
    }

    private func percentage(in line: String) -> Double? {
        guard let range = line.range(of: #"\d{1,3}%"#, options: .regularExpression) else {
            return nil
        }
        let value = line[range].dropLast()
        guard let percentage = Double(value) else { return nil }
        return min(max(percentage / 100, 0), 1)
    }

    private func overallFraction(
        for phase: GitCloneProgress.Phase,
        stageFraction: Double?
    ) -> Double? {
        guard let stageFraction else { return nil }
        switch phase {
        case .preparing:
            // Counting/compressing/remote progress is not comparable to the
            // local receive/resolve/checkout stages, so keep the indicator
            // indeterminate until one of those stages starts.
            return nil
        case .receivingObjects:
            guard stageFraction > 0 else { return nil }
            return 0.05 + stageFraction * 0.65
        case .resolvingDeltas:
            guard stageFraction > 0 else { return nil }
            return 0.70 + stageFraction * 0.20
        case .checkingOut:
            guard stageFraction > 0 else { return nil }
            return 0.90 + stageFraction * 0.10
        case .completed:
            return 1
        }
    }
}

/// 克隆错误。
public enum GitCloneError: LocalizedError {
    case destinationNotDirectory
    case destinationIsGitRepository
    case destinationNotEmpty

    public var errorDescription: String? {
        switch self {
        case .destinationNotDirectory:
            "Destination is not a directory."
        case .destinationIsGitRepository:
            "Destination is already a git repository."
        case .destinationNotEmpty:
            "Destination directory is not empty."
        }
    }
}
