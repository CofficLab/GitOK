import Foundation
import KernelCore
import ProviderProjects

/// 打开外部传入的目录：加入项目列表并切换为当前项目。
///
/// CLI 脚本 `gitok <path>` / Finder「在 GitOK 中打开」都走这条路径。
/// `ProjectProviding.openProject(at:)` 的语义已覆盖需求：目录不在列表中
/// 时会插入列表，已存在时只更新最近打开时间，两者都会把该目录设为
/// 当前项目。
@MainActor
enum GitOKExternalOpen {
    /// - Parameters:
    ///   - path: 目录路径（可含 `~`）。
    ///   - kernel: 已装配的内核。
    /// - Returns: 目录有效且已成功切换当前项目时为 `true`。
    @discardableResult
    static func open(_ path: String, kernel: KernelCoreContainer) -> Bool {
        let normalizedPath = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
        guard !normalizedPath.isEmpty,
              FileManager.default.fileExists(atPath: normalizedPath) else {
            return false
        }

        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: normalizedPath, isDirectory: &isDirectory)
        guard isDirectory.boolValue else { return false }

        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            return false
        }
        projects.openProject(at: URL(fileURLWithPath: normalizedPath))
        return true
    }
}