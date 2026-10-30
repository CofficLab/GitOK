import Foundation

/// 大小写冲突（case-conflict）条目识别。
///
/// ## 背景
///
/// 当仓库的 index / HEAD 中同时存在**仅大小写不同**的同名条目
/// （例如 `BANGCHONG.php` 与 `BangChong.php`）时，磁盘上只能存在一份文件
/// （macOS APFS 默认不区分大小写）。此时：
///
/// - `git status`（CLI）认为工作区干净；
/// - libgit2 会把其中一个变体报成「工作区已删除」（`[ D]`）。
///
/// libgit2 在做 index ↔ 工作区比对时，按 index 条目逐个去磁盘查找，
/// 但在大小写不敏感的文件系统上，第二个变体命中的是第一个变体对应的文件，
/// 于是必然有一个条目失配被判为删除。
///
/// 该工具让上层在**不依赖具体后端**的前提下识别并修正这类假删除。
public enum GitCaseConflictResolver {
    /// 单条状态条目（已暂存 / 未暂存状态码）。
    public struct Entry: Equatable, Sendable {
        public let path: String
        public let stagedStatus: Character
        public let worktreeStatus: Character

        public init(path: String, stagedStatus: Character, worktreeStatus: Character) {
            self.path = path
            self.stagedStatus = stagedStatus
            self.worktreeStatus = worktreeStatus
        }

        /// 是否为「工作区已删除」状态（未暂存删除）。
        public var isWorktreeDeleted: Bool { worktreeStatus == "D" }

        /// 是否为「已暂存删除」状态。
        public var isStagedDeleted: Bool { stagedStatus == "D" }
    }

    /// 判断一组路径中是否存在仅大小写不同的重复项。
    ///
    /// - Returns: 小写归一化后的路径 → 该分组内所有原始路径。
    public static func caseInsensitiveGroups(in paths: [String]) -> [String: [String]] {
        var groups: [String: [String]] = [:]
        for path in paths {
            groups[path.lowercased(), default: []].append(path)
        }
        return groups.filter { $0.value.count > 1 }
    }

    /// 判断路径集合中是否存在大小写冲突。
    public static func hasCaseConflict(in paths: [String]) -> Bool {
        !caseInsensitiveGroups(in: paths).isEmpty
    }

    /// 过滤掉由大小写冲突导致的**假删除**条目。
    ///
    /// 判定依据：条目被报成「工作区已删除」，但它指向的路径在磁盘上**实际存在**
    /// （只是文件名大小写与 index 中的另一个变体不同）。这类条目不是真实删除，
    /// 应当从变更列表中剔除，避免 UI 展示并不存在的「未暂存」改动。
    ///
    /// - Parameters:
    ///   - entries: 后端返回的状态条目。
    ///   - indexPaths: 仓库 index 中的全部路径（用于判定是否存在大小写冲突）。
    ///   - worktreeRoot: 仓库工作区根目录，用于检查文件是否真实存在。
    /// - Returns: 修正后的条目列表。
    public static func removingFalseDeletions(
        entries: [Entry],
        indexPaths: [String],
        worktreeRoot: URL
    ) -> [Entry] {
        // 没有大小写冲突时不做任何处理：真实删除必须原样保留。
        guard hasCaseConflict(in: indexPaths) else { return entries }

        return entries.filter { entry in
            guard entry.isWorktreeDeleted else { return true }
            // 报成删除、但磁盘上实际存在 → 大小写冲突造成的假删除。
            let absolute = worktreeRoot.appendingPathComponent(entry.path)
            return !FileManager.default.fileExists(atPath: absolute.path)
        }
    }
}
