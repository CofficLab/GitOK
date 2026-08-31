import Foundation

public extension URL {
    /// 删除指定 URL 对应的文件或目录。
    func delete() throws {
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        try FileManager.default.removeItem(at: self)
    }
}
