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
    /// 工作区同步过程中失败的步骤。
    public enum SyncStep: Sendable {
        case fetch
        case merge
        case push
    }

    /// 智能同步失败；保留失败步骤和 Git 原始错误，交给 UI 决定展示方式。
    public struct SyncError: Swift.Error, LocalizedError, Sendable {
        public let step: SyncStep
        public let message: String

        public init(step: SyncStep, message: String) {
            self.step = step
            self.message = message
        }

        public var errorDescription: String? { message }
    }

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
            // git remote -v 的输出为 "(fetch)" / "(push)"，归一化去括号。
            let kind = rest.count > 1
                ? rest[1].trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                : "fetch"
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
        try pull(in: repository, strategy: .merge)
    }

    /// 拉取并整合当前 upstream。
    ///
    /// `.fastForwardOnly` 只允许远程领先的安全快进；`.merge` 显式关闭
    /// rebase 选择并接受默认合并消息，避免新版 Git 因未配置策略而拒绝执行。
    public enum PullStrategy: Sendable {
        case fastForwardOnly
        case merge
    }

    public static func pull(in repository: URL, strategy: PullStrategy) throws {
        switch strategy {
        case .fastForwardOnly:
            _ = try GitProcessRunner.run(["pull", "--ff-only"], in: repository)
        case .merge:
            _ = try GitProcessRunner.run(["pull", "--no-rebase", "--no-edit"], in: repository)
        }
    }

    /// 推送到远程（`git push`）。
    public static func push(in repository: URL) throws {
        _ = try GitProcessRunner.run(["push"], in: repository)
    }

    /// Fetch 后根据本地与 upstream 的真实关系自动同步。
    ///
    /// 远程引用已经由 Fetch 更新，因此整合阶段直接使用 `@{u}`，不重复发起
    /// 网络请求。双方分叉时采用保留双方历史的 Merge；Merge 成功后才 Push。
    @discardableResult
    public static func synchronize(in repository: URL) throws -> GitRefReader.RemoteTrackingStatus {
        do {
            try fetch(in: repository)
        } catch {
            throw SyncError(step: .fetch, message: error.localizedDescription)
        }

        let status = GitRefReader.remoteTrackingStatus(in: repository)
        guard status.hasUpstream else { return status }

        if status.behind > 0 {
            do {
                let strategy: PullStrategy = status.ahead > 0 ? .merge : .fastForwardOnly
                try mergeFetchedRemote(in: repository, strategy: strategy)
            } catch {
                throw SyncError(step: .merge, message: error.localizedDescription)
            }
        }

        if status.ahead > 0 {
            do {
                try push(in: repository)
            } catch {
                throw SyncError(step: .push, message: error.localizedDescription)
            }
        }

        return GitRefReader.remoteTrackingStatus(in: repository)
    }

    /// 将最近一次 Fetch 更新的 upstream 引用整合进当前分支。
    private static func mergeFetchedRemote(in repository: URL, strategy: PullStrategy) throws {
        switch strategy {
        case .fastForwardOnly:
            _ = try GitProcessRunner.run(["merge", "--ff-only", "@{u}"], in: repository)
        case .merge:
            _ = try GitProcessRunner.run(["merge", "--no-edit", "@{u}"], in: repository)
        }
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
