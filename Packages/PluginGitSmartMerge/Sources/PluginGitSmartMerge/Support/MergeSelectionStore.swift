import Foundation

/// Smart Merge 表单上次选择的源分支与目标分支。
struct MergeSelection: Codable, Equatable, Sendable {
    let sourceBranchName: String?
    let targetBranchName: String?
}

/// 按仓库保存 Smart Merge 的分支选择。
///
/// 偏好文件由插件自己拥有，位于 `StorageProviding` 注入的插件数据目录中。
/// 读取或写入失败时静默回退，不应阻塞实际的 Git 合并操作。
final class MergeSelectionStore {
    private let fileURL: URL

    init(storageDirectory: URL? = nil) {
        let directory = storageDirectory ?? Self.defaultStorageDirectory
        fileURL = directory.appendingPathComponent("merge-selection.json", isDirectory: false)
    }

    func selection(for repository: URL) -> MergeSelection? {
        loadAll()[repositoryKey(for: repository)]
    }

    func save(_ selection: MergeSelection, for repository: URL) {
        var selections = loadAll()
        selections[repositoryKey(for: repository)] = selection

        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(selections)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 持久化只是体验增强；损坏或不可写的偏好不能阻止用户合并。
        }
    }

    private func loadAll() -> [String: MergeSelection] {
        guard let data = try? Data(contentsOf: fileURL),
              let selections = try? JSONDecoder().decode([String: MergeSelection].self, from: data) else {
            return [:]
        }
        return selections
    }

    private func repositoryKey(for repository: URL) -> String {
        repository
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
    }

    private static var defaultStorageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let bundleID = Bundle.main.bundleIdentifier ?? "com.coffic.gitok"
        return appSupport
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("com.coffic.gitok.plugin.git-smart-merge", isDirectory: true)
    }
}
