import Foundation

/// Stash 条目（对齐旧版 GitStashEntry）。
public struct GitStashEntry: Equatable, Sendable, Identifiable {
    public let index: Int
    public let message: String

    public init(index: Int, message: String) {
        self.index = index
        self.message = message
    }

    public var id: Int { index }
    public var stashRef: String { "stash@{\(index)}" }
}

/// Stash 操作：列表、保存、应用、弹出、删除（对齐旧版 stash 能力）。
public enum GitStashOperation {
    /// 列出 stash（`git stash list`）。
    public static func list(in repository: URL) -> [GitStashEntry] {
        guard let out = try? GitProcessRunner.run(["stash", "list"], in: repository) else { return [] }
        var result: [GitStashEntry] = []
        for line in out.split(separator: "\n") {
            let raw = String(line)
            guard let open = raw.firstIndex(of: "{"),
                  let close = raw.firstIndex(of: "}"),
                  open < close,
                  let index = Int(raw[raw.index(after: open)..<close]) else { continue }
            let colon = raw.firstIndex(of: ":")
            let messagePart = colon.map { raw[raw.index(after: $0)...] } ?? Substring(raw)
            var message = messagePart.trimmingCharacters(in: .whitespacesAndNewlines)
            // 去掉 "WIP on branch:" / "On branch:" 前缀，保留用户消息或 WIP 描述。
            for prefix in ["WIP on ", "On branch ", "On "] {
                if message.hasPrefix(prefix) {
                    message = String(message.dropFirst(prefix.count))
                    break
                }
            }
            result.append(GitStashEntry(index: index, message: message))
        }
        return result
    }

    /// 保存 stash（`git stash push -m`）。
    public static func save(message: String?, in repository: URL) throws {
        if let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _ = try GitProcessRunner.run(["stash", "push", "-m", message], in: repository)
        } else {
            _ = try GitProcessRunner.run(["stash", "push"], in: repository)
        }
    }

    /// 应用 stash（不清除）。
    public static func apply(_ entry: GitStashEntry, in repository: URL) throws {
        _ = try GitProcessRunner.run(["stash", "apply", entry.stashRef], in: repository)
    }

    /// 弹出 stash（应用并清除）。
    public static func pop(_ entry: GitStashEntry, in repository: URL) throws {
        _ = try GitProcessRunner.run(["stash", "pop", entry.stashRef], in: repository)
    }

    /// 删除 stash。
    public static func drop(_ entry: GitStashEntry, in repository: URL) throws {
        _ = try GitProcessRunner.run(["stash", "drop", entry.stashRef], in: repository)
    }

    /// 是否还有工作区改动（用于禁用空的 stash 保存）。
    public static func hasChanges(in repository: URL) -> Bool {
        guard let out = try? GitProcessRunner.run(
            ["status", "--porcelain"],
            in: repository
        ) else { return false }
        return !out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
