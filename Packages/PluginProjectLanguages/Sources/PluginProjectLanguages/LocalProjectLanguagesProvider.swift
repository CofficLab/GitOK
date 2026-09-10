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

    private let analyzer: RepositoryLanguageAnalyzer
    private var refreshToken = 0
    private var observers: [WeakObserver] = []

    private(set) var currentSnapshot: ProjectLanguagesSnapshot?
    private(set) var isLoading = false

    init(analyzer: RepositoryLanguageAnalyzer = RepositoryLanguageAnalyzer()) {
        self.analyzer = analyzer
    }

    func refresh(for repository: URL?) {
        refreshToken &+= 1
        let token = refreshToken
        let repository = repository?.standardizedFileURL

        guard let repository else {
            setSnapshot(nil)
            setLoading(false)
            return
        }

        setSnapshot(nil)
        setLoading(true)
        let analyzer = self.analyzer
        Task.detached(priority: .utility) {
            do {
                let snapshot = try analyzer.analyze(repository: repository)
                await self.apply(snapshot, token: token)
            } catch {
                Self.logger.error(
                    "Language analysis failed for \(repository.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
                await self.finishLoading(token: token)
            }
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
