import Foundation

/// 子模块查询与更新（对齐旧版 GitRepositoryCLI 子模块能力）。
public enum GitSubmoduleOperation {
    /// 列出子模块（`git submodule status` / `.gitmodules` 解析）。
    public static func list(in repository: URL) -> [GitSubmoduleSummary] {
        guard let out = try? GitProcessRunner.run(["submodule", "status"], in: repository) else {
            return []
        }
        var result: [GitSubmoduleSummary] = []
        for line in out.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count > 42 else { continue }
            // 格式: <status> <sha> <path> (rev)
            let sha = String(trimmed.prefix(40))
            let rest = trimmed.dropFirst(42)
            let path = rest
                .split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                .first
                .map(String.init) ?? ""
            result.append(GitSubmoduleSummary(
                path: path,
                commit: sha,
                url: remoteURL(for: path, in: repository)
            ))
        }
        return result
    }

    /// 更新全部子模块（`git submodule update --init --recursive`）。
    public static func updateAll(in repository: URL) {
        _ = try? GitProcessRunner.run(
            ["submodule", "update", "--init", "--recursive"],
            in: repository
        )
    }

    private static func remoteURL(for path: String, in repository: URL) -> String {
        let gitmodules = repository.appendingPathComponent(".gitmodules")
        guard let data = try? String(contentsOf: gitmodules, encoding: .utf8) else { return "" }
        var currentPath: String?
        var url = ""
        for line in data.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[submodule") {
                // 提取 path = "xxx"
                if let range = trimmed.range(of: #"path\s*=\s*"([^"]+)""#, options: .regularExpression) {
                    let capture = trimmed[range]
                    currentPath = capture
                        .replacingOccurrences(of: #"path\s*=\s*""#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: "\"", with: "")
                }
            } else if currentPath == path, trimmed.hasPrefix("url = ") {
                url = String(trimmed.dropFirst(6))
                break
            }
        }
        return url
    }
}

/// 子模块摘要。
public struct GitSubmoduleSummary: Identifiable, Sendable {
    public let path: String
    public let commit: String
    public let url: String

    public var id: String { path }
}
