import Foundation

/// Git 仓库克隆操作。
public enum GitCloneOperation {
    /// 克隆远程仓库到本地目录。
    ///
    /// - Parameters:
    ///   - remoteURL: 远程仓库地址（https / ssh / git 协议）。
    ///   - destination: 目标目录（已存在的空目录或尚不存在的路径）。
    /// - Returns: 克隆完成后的本地仓库路径。
    public static func clone(remoteURL: String, destination: URL) throws -> URL {
        try validateDestination(destination)
        _ = try GitProcessRunner.run(
            ["clone", remoteURL, destination.path],
            in: FileManager.default.homeDirectoryForCurrentUser
        )
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
