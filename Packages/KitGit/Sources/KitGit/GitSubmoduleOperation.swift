import Foundation

/// 子模块查询与更新（对齐旧版 GitRepositoryCLI 子模块能力）。
public enum GitSubmoduleOperation {
    /// 列出子模块（`git submodule status` / `.gitmodules` 解析）。
    public static func list(in repository: URL) -> [GitSubmoduleSummary] {
        list(in: repository, cancellation: nil)
    }

    /// 可取消的子模块列表读取，供项目切换敏感的工具栏状态使用。
    public static func list(
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) -> [GitSubmoduleSummary] {
        guard cancellation?.isCancelled != true,
              let out = try? GitProcessRunner.run(
                ["submodule", "status"],
                in: repository,
                cancellation: cancellation
              ),
              cancellation?.isCancelled != true else {
            return []
        }
        var result: [GitSubmoduleSummary] = []
        for line in out.split(separator: "\n") {
            guard cancellation?.isCancelled != true else { return [] }
            // 格式: <status><sha> <path> (rev)
            // 状态字符可能是空格 / '+' / '-' / 'U'，不能先 trim，否则固定偏移
            // 会把路径首字符一起吃掉。先去掉 1 个状态字符，再按 SHA 长度切分。
            let rest = line.dropFirst()
            guard rest.count >= 41 else { continue }
            let sha = String(rest.prefix(40))
            let afterSHA = rest.dropFirst(40)
            guard afterSHA.first == " " else { continue }
            var pathAndDescription = afterSHA.dropFirst()
            // 末尾可选描述形如 " (heads/main)"；从后往前截断，保留路径内的空格。
            if let descriptionStart = pathAndDescription.range(of: " (", options: .backwards) {
                pathAndDescription = pathAndDescription[..<descriptionStart.lowerBound]
            }
            let path = String(pathAndDescription)
            guard !path.isEmpty else { continue }
            result.append(GitSubmoduleSummary(
                path: path,
                commit: sha,
                url: remoteURL(for: path, in: repository, cancellation: cancellation)
            ))
        }
        return cancellation?.isCancelled == true ? [] : result
    }

    /// 更新全部子模块（`git submodule update --init --recursive`）。
    public static func updateAll(in repository: URL) {
        _ = try? GitProcessRunner.run(
            ["submodule", "update", "--init", "--recursive"],
            in: repository
        )
    }

    private static func remoteURL(
        for path: String,
        in repository: URL,
        cancellation: GitProcessCancellation?
    ) -> String {
        let gitmodules = repository.appendingPathComponent(".gitmodules")
        guard cancellation?.isCancelled != true else { return "" }
        guard let data = try? String(contentsOf: gitmodules, encoding: .utf8) else { return "" }
        var currentPath: String?
        var url = ""
        for line in data.split(separator: "\n") {
            guard cancellation?.isCancelled != true else { return "" }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[submodule") {
                currentPath = nil
                continue
            }
            guard let separator = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[..<separator].trimmingCharacters(in: .whitespaces)
            var value = trimmed[trimmed.index(after: separator)...]
                .trimmingCharacters(in: .whitespaces)
            // git config 仅对含特殊字符的值加引号；普通路径/URL 是裸值。
            if value.count >= 2, value.hasPrefix("\""), value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            }
            if key == "path" {
                currentPath = value
            } else if key == "url", currentPath == path {
                url = value
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

    public init(path: String, commit: String, url: String) {
        self.path = path
        self.commit = commit
        self.url = url
    }

    public var id: String { path }
}
