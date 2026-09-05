import Foundation

/// 远程仓库摘要（对齐旧版 GitRemoteSummary）。
public struct GitRemoteSummary: Identifiable, Equatable, Hashable, Sendable {
    public let name: String
    public let url: String
    public let fetchURL: String?
    public let pushURL: String?

    public init(name: String, url: String, fetchURL: String? = nil, pushURL: String? = nil) {
        self.name = name
        self.url = url
        self.fetchURL = fetchURL
        self.pushURL = pushURL
    }

    public var id: String { name }
}

/// 远程仓库操作：列表、添加、删除（对齐旧版远程仓库能力）。
public enum GitRemoteOperation {
    /// 列出远程仓库（`git remote -v` 解析）。
    public static func listRemotes(in repository: URL) -> [GitRemoteSummary] {
        guard let out = try? GitProcessRunner.run(["remote", "-v"], in: repository) else { return [] }
        var result: [GitRemoteSummary] = []
        for line in out.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 2).map(String.init)
            guard parts.count >= 2 else { continue }
            let name = parts[0]
            let rest = parts[1].split(separator: " ").map(String.init)
            let url = rest.first ?? ""
            let kind = rest.count > 1 ? rest[1] : "fetch"
            if let index = result.firstIndex(where: { $0.name == name }) {
                var existing = result[index]
                if kind == "push" {
                    existing = GitRemoteSummary(
                        name: existing.name,
                        url: existing.url,
                        fetchURL: existing.fetchURL,
                        pushURL: url
                    )
                }
                result[index] = existing
            } else {
                result.append(GitRemoteSummary(
                    name: name,
                    url: url,
                    fetchURL: kind == "fetch" ? url : nil,
                    pushURL: kind == "push" ? url : nil
                ))
            }
        }
        return result
    }

    /// 添加远程仓库。
    public static func addRemote(name: String, url: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["remote", "add", name, url], in: repository)
    }

    /// 删除远程仓库。
    public static func removeRemote(name: String, in repository: URL) throws {
        _ = try GitProcessRunner.run(["remote", "remove", name], in: repository)
    }

    /// 从远程获取引用（`git fetch`）。
    public static func fetch(in repository: URL) throws {
        _ = try GitProcessRunner.run(["fetch"], in: repository)
    }

    /// 从上游拉取并合并（`git pull`）。
    public static func pull(in repository: URL) throws {
        _ = try GitProcessRunner.run(["pull"], in: repository)
    }

    /// 推送到远程（`git push`）。
    public static func push(in repository: URL) throws {
        _ = try GitProcessRunner.run(["push"], in: repository)
    }

    /// 从远程 URL 生成 Web 链接（HTTPS 或 SSH 地址转 https:// 形式）。
    public static func webLink(for url: String) -> URL? {
        if url.hasPrefix("https://") || url.hasPrefix("http://") {
            return URL(string: url)
        }
        // git@host:owner/repo.git
        if url.hasPrefix("git@"), url.contains(":") {
            let rest = url.dropFirst(4)
            let parts = rest.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            var path = parts[1]
            if path.hasSuffix(".git") {
                path = String(path.dropLast(4))
            }
            return URL(string: "https://\(parts[0])/\(path)")
        }
        // ssh://git@host/owner/repo.git
        if url.hasPrefix("ssh://"), let parsed = URL(string: url) {
            var path = parsed.path
            if path.hasSuffix(".git") {
                path = String(path.dropLast(4))
            }
            return URL(string: "https://\(parsed.host ?? "")\(path)")
        }
        return nil
    }
}
