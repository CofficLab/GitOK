import Foundation
import KitGit

/// 按仓库缓存上一次成功读取的分支列表（本地 + 远程）。
///
/// 分支读取要排在 libgit2 的仓库串行队列里，队列被工作区扫描、提交分页等
/// 任务占住时会有秒级等待。缓存让弹层先用上次结果立即渲染，再在后台刷新；
/// 读取失败时保留缓存，避免把可用列表清空。
final class BranchListCacheStore {
    private struct CachedBranch: Codable, Equatable {
        let name: String
        let isRemote: Bool
        let isCurrent: Bool
    }

    private let fileURL: URL

    init(storageDirectory: URL? = nil) {
        let directory = storageDirectory ?? BranchListStorageLocation.defaultDirectory()
        fileURL = directory.appendingPathComponent("branch-cache.json", isDirectory: false)
    }

    func branches(for repository: URL) -> [GitBranchSummary] {
        let key = BranchListStorageLocation.repositoryKey(for: repository)
        guard let cached = loadAll()[key] else { return [] }
        return cached.map {
            GitBranchSummary(name: $0.name, isRemote: $0.isRemote, isCurrent: $0.isCurrent)
        }
    }

    func save(_ branches: [GitBranchSummary], for repository: URL) {
        let key = BranchListStorageLocation.repositoryKey(for: repository)
        var all = loadAll()
        if branches.isEmpty {
            guard all.removeValue(forKey: key) != nil else { return }
        } else {
            all[key] = branches.map {
                CachedBranch(name: $0.name, isRemote: $0.isRemote, isCurrent: $0.isCurrent)
            }
        }

        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(all)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 缓存只是体验增强；损坏或不可写不能阻止用户切换分支。
        }
    }

    private func loadAll() -> [String: [CachedBranch]] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: [CachedBranch]].self, from: data) else {
            return [:]
        }
        return decoded
    }
}