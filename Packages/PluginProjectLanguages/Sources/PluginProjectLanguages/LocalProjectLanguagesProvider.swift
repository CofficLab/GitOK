import Foundation
import KitGit
import os
import ProviderProjectLanguages

/// Concrete provider that publishes local Git language statistics.
@MainActor
final class LocalProjectLanguagesProvider: ProjectLanguagesProviding {
    private nonisolated static let logger = Logger(
        subsystem: "com.coffic.gitok.plugin.project-languages",
        category: "LocalProjectLanguagesProvider"
    )

    private let analyzer: any RepositoryLanguageAnalyzing
    private let cache: ProjectLanguagesCache
    private var refreshToken = 0
    private var analysisTask: Task<Void, Never>?
    private var observers: [WeakObserver] = []

    private(set) var currentSnapshot: ProjectLanguagesSnapshot?
    private(set) var isLoading = false

    init(
        analyzer: any RepositoryLanguageAnalyzing = RepositoryLanguageAnalyzer(),
        cache: ProjectLanguagesCache = ProjectLanguagesCache()
    ) {
        self.analyzer = analyzer
        self.cache = cache
    }

    func refresh(for repository: URL?) {
        analysisTask?.cancel()
        analysisTask = nil
        refreshToken &+= 1
        let token = refreshToken
        let repository = repository?.standardizedFileURL

        guard let repository else {
            setSnapshot(nil)
            setLoading(false)
            return
        }

        // 项目目录被移动或删除时立即结束刷新，避免把失效路径交给 Git
        // 并在切换项目后继续打印失败日志。
        guard FileManager.default.fileExists(atPath: repository.path) else {
            setSnapshot(nil)
            setLoading(false)
            return
        }

        setSnapshot(nil)
        setLoading(true)
        let analyzer = self.analyzer
        let cache = self.cache
        analysisTask = Task.detached(priority: .utility) { [weak self] in
            if !Task.isCancelled {
                do {
                    let context = try analyzer.context(for: repository)
                    // 工作区是否有未提交变更不影响语言统计：有变更时同样分析。
                    guard !Task.isCancelled else {
                        await self?.finishLoading(token: token)
                        return
                    }

                    if let snapshot = cache.load(for: context.cacheKey) {
                        await self?.apply(snapshot, token: token)
                        return
                    }

                    let snapshot = try analyzer.analyze(repository: repository)
                    cache.store(snapshot, for: context.cacheKey)
                    if !Task.isCancelled {
                        await self?.apply(snapshot, token: token)
                    }
                } catch is CancellationError {
                    // Cancellation is expected when switching projects or refreshing.
                } catch {
                    Self.logger.error(
                        "Language analysis failed for \(repository.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                    if !Task.isCancelled {
                        await self?.finishLoading(token: token)
                    }
                }
            }
            await self?.clearAnalysisTask(token: token)
        }
    }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectLanguagesEvent) -> Void
    ) -> any ProjectLanguagesObserverHandle {
        let handle = ObserverHandle(owner: self, callback: callback)
        observers.append(WeakObserver(handle))
        return handle
    }

    private func apply(_ snapshot: ProjectLanguagesSnapshot, token: Int) {
        guard token == refreshToken else { return }
        setSnapshot(snapshot)
        setLoading(false)
    }

    private func finishLoading(token: Int) {
        guard token == refreshToken else { return }
        setLoading(false)
    }

    private func clearAnalysisTask(token: Int) {
        guard token == refreshToken else { return }
        analysisTask = nil
    }

    private func setSnapshot(_ snapshot: ProjectLanguagesSnapshot?) {
        guard currentSnapshot != snapshot else { return }
        currentSnapshot = snapshot
        notify(.snapshotChanged)
    }

    private func setLoading(_ isLoading: Bool) {
        guard self.isLoading != isLoading else { return }
        self.isLoading = isLoading
        notify(.loadingChanged)
    }

    private func notify(_ event: ProjectLanguagesEvent) {
        observers.removeAll { $0.handle == nil }
        for observer in observers {
            observer.handle?.invoke(event)
        }
    }

    private func removeObserver(_ handle: ObserverHandle) {
        observers.removeAll { $0.handle === handle }
    }

    @MainActor
    private final class ObserverHandle: ProjectLanguagesObserverHandle {
        private weak var owner: LocalProjectLanguagesProvider?
        private let callback: (ProjectLanguagesEvent) -> Void
        private var isCancelled = false

        init(
            owner: LocalProjectLanguagesProvider,
            callback: @escaping (ProjectLanguagesEvent) -> Void
        ) {
            self.owner = owner
            self.callback = callback
        }

        func cancel() {
            guard !isCancelled else { return }
            isCancelled = true
            owner?.removeObserver(self)
        }

        func invoke(_ event: ProjectLanguagesEvent) {
            guard !isCancelled else { return }
            callback(event)
        }
    }

    @MainActor
    private final class WeakObserver {
        weak var handle: ObserverHandle?

        init(_ handle: ObserverHandle) {
            self.handle = handle
        }
    }
}
