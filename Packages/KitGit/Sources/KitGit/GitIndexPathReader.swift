import Foundation

/// 读取仓库 index 中登记的全部路径。
///
/// 用于大小写冲突检测：index 中若同时存在仅大小写不同的同名条目
/// （如 `BANGCHONG.php` 与 `BangChong.php`），说明仓库在大小写不敏感的文件系统上
/// 必然出现「一个变体在磁盘上找不到」的失配。
public enum GitIndexPathReader {
    /// 读取 index 中的全部路径（相对仓库根，Git 正斜杠分隔）。
    ///
    /// 使用 `git ls-files`（读取 index，不受工作区状态影响）。
    /// 读取失败时返回空数组：调用方据此跳过冲突检测，退回原始行为。
    public static func allPaths(in repository: URL) -> [String] {
        guard let output = try? GitProcessRunner.run(["ls-files"], in: repository) else {
            return []
        }
        return output
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}
