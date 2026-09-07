import Foundation
import KitGit
import ProviderGit
import SwiftUI

/// Commit Detail 的有界分页缓存。
///
/// 列表只保留当前滚动位置附近的少量页面；跳转到远处时按需读取对应页，
/// 被淘汰的页面之后仍可重新加载。这样即使 commit 涉及数万文件，也不会在
/// SwiftUI 或 ProjectProviding 中常驻完整 `[GitFileChange]`。
@MainActor
final class CommitFilePageStore: ObservableObject {
    nonisolated static let pageSize = 100
    nonisolated static let maxResidentPages = 5

    @Published private(set) var totalCount: Int?
    @Published private(set) var pages: [Int: [GitFileChange]] = [:]
    @Published private(set) var loadingPages: Set<Int> = []
    @Published private(set) var pageErrors: [Int: String] = [:]
    @Published private(set) var isLoadingCount = false

    private var commitHash: String?
    private var repositoryURL: URL?
    private var git: (any GitProviding)?
    private var generation = 0
    private var pageTasks: [Int: Task<Void, Never>] = [:]
    private var countTask: Task<Void, Never>?
    private var lruPages: [Int] = []

    var isLoading: Bool {
        isLoadingCount || !loadingPages.isEmpty
    }

    var firstError: String? {
        if let countError = pageErrors[-1] { return countError }
        return pageErrors
            .filter { $0.key >= 0 }
            .sorted { $0.key < $1.key }
            .first?.value
    }

    var firstFailedPageIndex: Int? {
        pageErrors.keys.filter { $0 >= 0 }.min()
    }

    var loadedChangeCount: Int {
        pages.values.reduce(0) { $0 + $1.count }
    }

    func reset(commitHash: String?, repositoryURL: URL?, git: (any GitProviding)?) {
        generation &+= 1
        countTask?.cancel()
        countTask = nil
        pageTasks.values.forEach { $0.cancel() }
        pageTasks.removeAll()

        self.commitHash = commitHash
        self.repositoryURL = repositoryURL
        self.git = git
        totalCount = nil
        pages = [:]
        loadingPages = []
        pageErrors = [:]
        isLoadingCount = false
        lruPages = []

        guard commitHash != nil, repositoryURL != nil, git != nil else { return }
        loadCount()
        requestPage(at: 0)
    }

    func change(at index: Int) -> GitFileChange? {
        guard index >= 0 else { return nil }
        let pageIndex = index / Self.pageSize
        let itemIndex = index % Self.pageSize
        guard let page = pages[pageIndex], page.indices.contains(itemIndex) else { return nil }
        touch(pageIndex)
        return page[itemIndex]
    }

    func requestPage(at pageIndex: Int) {
        guard pageIndex >= 0,
              let commitHash,
              let repositoryURL,
              let git,
              let totalCount,
              pageIndex * Self.pageSize < totalCount
        else { return }

        if pages[pageIndex] != nil {
            touch(pageIndex)
            return
        }
        guard !loadingPages.contains(pageIndex) else { return }

        let currentGeneration = generation
        loadingPages.insert(pageIndex)
        pageErrors[pageIndex] = nil
        let offset = pageIndex * Self.pageSize
        pageTasks[pageIndex] = Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    try git.loadCommitChangesPage(
                        commit: commitHash,
                        limit: Self.pageSize,
                        offset: offset,
                        in: repositoryURL
                    )
                }
            }.value

            guard let self, !Task.isCancelled else { return }
            self.pageTasks[pageIndex] = nil
            guard self.generation == currentGeneration else { return }

            self.loadingPages.remove(pageIndex)
            switch result {
            case .success(let page):
                self.pages[pageIndex] = page.changes
                self.touch(pageIndex)
                self.trimCache(keeping: pageIndex)
            case .failure(let error):
                self.pageErrors[pageIndex] = error.localizedDescription
            }
        }
    }

    func retry(pageIndex: Int) {
        guard pageIndex >= 0 else {
            loadCount()
            return
        }
        pageErrors[pageIndex] = nil
        requestPage(at: pageIndex)
    }

    private func loadCount() {
        guard let commitHash, let repositoryURL, let git else { return }
        countTask?.cancel()
        let currentGeneration = generation
        isLoadingCount = true
        pageErrors[-1] = nil

        countTask = Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                Result { try git.countCommitChanges(commit: commitHash, in: repositoryURL) }
            }.value

            guard let self, !Task.isCancelled else { return }
            self.countTask = nil
            guard self.generation == currentGeneration else { return }

            self.isLoadingCount = false
            switch result {
            case .success(let count):
                self.totalCount = max(count, 0)
                if count == 0 {
                    self.pages = [:]
                } else {
                    self.requestPage(at: 0)
                }
            case .failure(let error):
                self.pageErrors[-1] = error.localizedDescription
            }
        }
    }

    private func touch(_ pageIndex: Int) {
        lruPages.removeAll { $0 == pageIndex }
        lruPages.append(pageIndex)
    }

    private func trimCache(keeping pageIndex: Int) {
        while pages.count > Self.maxResidentPages, let oldest = lruPages.first {
            lruPages.removeFirst()
            guard oldest != pageIndex else { continue }
            pages.removeValue(forKey: oldest)
            pageErrors.removeValue(forKey: oldest)
        }
    }
}
