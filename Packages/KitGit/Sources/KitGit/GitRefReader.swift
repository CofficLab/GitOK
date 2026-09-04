import Foundation

/// 读取 git 引用 / 分支状态（供状态栏、工作区状态等消费方使用）。
public enum GitRefReader {
    /// 当前分支名（`git branch --show-current`）；detached HEAD 时返回 nil。
    public static func currentBranch(in repository: URL) -> String? {
        let out = try? GitProcessRunner.run(["branch", "--show-current"], in: repository)
        let value = out?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    /// 当前分支相对上游未推送的提交数（`git rev-list --count @{u}..HEAD`）。
    ///
    /// 没有上游分支（未 push 过）时返回 nil，调用方应隐藏未推送提示。
    public static func unpushedCount(in repository: URL) -> Int? {
        guard let out = try? GitProcessRunner.run(
            ["rev-list", "--count", "@{u}..HEAD"],
            in: repository
        ) else {
            return nil
        }
        let value = out.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let count = Int(value) else { return nil }
        return count
    }

    /// 是否有已配置的远程（`git remote` 非空）。
    public static func hasRemotes(in repository: URL) -> Bool {
        guard let out = try? GitProcessRunner.run(["remote"], in: repository) else { return false }
        return !out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 当前分支相对上游未拉取的提交数（`git rev-list --count HEAD..@{u}`）。
    ///
    /// 没有上游分支时返回 nil。
    public static func unpulledCount(in repository: URL) -> Int? {
        guard let out = try? GitProcessRunner.run(
            ["rev-list", "--count", "HEAD..@{u}"],
            in: repository
        ) else {
            return nil
        }
        let value = out.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let count = Int(value) else { return nil }
        return count
    }

    /// 远程跟踪状态：ahead（本地领先上游的提交数）、behind（上游领先本地的提交数）、hasUpstream。
    ///
    /// 使用 `git rev-list --left-right --count HEAD...@{u}`。
    /// 没有上游分支时返回 hasUpstream=false。
    public struct RemoteTrackingStatus: Equatable, Sendable {
        public let ahead: Int
        public let behind: Int
        public let hasUpstream: Bool

        public init(ahead: Int, behind: Int, hasUpstream: Bool) {
            self.ahead = ahead
            self.behind = behind
            self.hasUpstream = hasUpstream
        }
    }

    public static func remoteTrackingStatus(in repository: URL) -> RemoteTrackingStatus {
        guard let out = try? GitProcessRunner.run(
            ["rev-list", "--left-right", "--count", "HEAD...@{u}"],
            in: repository
        ) else {
            return RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
        }
        let parts = out.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t")
        guard parts.count == 2,
              let ahead = Int(parts[0]),
              let behind = Int(parts[1]) else {
            return RemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
        }
        return RemoteTrackingStatus(ahead: ahead, behind: behind, hasUpstream: true)
    }
}
