import Foundation

/// 仓库根目录下 `.gitignore` 文件的定位与读写。
///
/// View 只依赖本类型，不直接拼路径或碰 `FileManager`：
/// 路径拼接、存在性判断、读取失败兜底都是可单测的纯逻辑。
struct GitIgnoreFile: @unchecked Sendable {
    /// `.gitignore` 在仓库根目录下的文件名。
    static let fileName = ".gitignore"

    /// 所属仓库根目录；为 `nil` 表示当前没有选中项目。
    let repositoryRoot: URL?

    private let fileManager: FileManager

    init(repositoryRoot: URL?, fileManager: FileManager = .default) {
        self.repositoryRoot = repositoryRoot
        self.fileManager = fileManager
    }

    /// `.gitignore` 的完整路径；没有仓库根目录时为 `nil`。
    var url: URL? {
        repositoryRoot?.appendingPathComponent(Self.fileName)
    }

    /// 是否存在可查看的 `.gitignore`。
    ///
    /// 没有选中项目、或文件缺失时为 `false`，与状态栏图标「不显示提示文案」的分支一致。
    var exists: Bool {
        guard let url else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    /// 读取 `.gitignore` 的 UTF-8 内容。
    ///
    /// - Returns: 文件内容；无仓库根目录、文件缺失或读取失败时返回空字符串，
    ///   保证查看器总能渲染出一个确定的（空）内容态。
    func read() -> String {
        guard let url else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}
