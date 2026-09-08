import Foundation

/// A single calendar day's local Git activity.
public struct ActivityHeatmapDay: Codable, Equatable, Hashable, Sendable, Identifiable {
    public let date: Date
    public let commitCount: Int

    public var id: Date { date }

    public init(date: Date, commitCount: Int) {
        self.date = date
        self.commitCount = max(0, commitCount)
    }
}

/// A repository's activity data for the currently available history window.
public struct ActivityHeatmapSnapshot: Codable, Equatable, Sendable {
    public let repositoryPath: String
    public let generatedAt: Date
    public let days: [ActivityHeatmapDay]

    public init(
        repositoryPath: String,
        generatedAt: Date = Date(),
        days: [ActivityHeatmapDay]
    ) {
        self.repositoryPath = repositoryPath
        self.generatedAt = generatedAt
        self.days = days.sorted { $0.date < $1.date }
    }

    public var totalCommitCount: Int {
        days.reduce(0) { $0 + $1.commitCount }
    }
}

@MainActor
public enum ActivityHeatmapEvent {
    case snapshotChanged
    case loadingChanged
}

@MainActor
public protocol ActivityHeatmapObserverHandle: AnyObject {
    func cancel()
}

/// Data contract for a Git-style activity heatmap.
///
/// The provider deliberately does not know how data is collected or persisted.
/// A plugin may replace the current snapshot after reading local Git history,
/// a remote API, or its own cache.
@MainActor
public protocol ActivityHeatmapProviding: AnyObject {
    var currentSnapshot: ActivityHeatmapSnapshot? { get }
    var isLoading: Bool { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ActivityHeatmapEvent) -> Void
    ) -> any ActivityHeatmapObserverHandle

    func setSnapshot(_ snapshot: ActivityHeatmapSnapshot?)
    func setLoading(_ isLoading: Bool)
}

/// In-memory reference implementation used by hosts and tests.
@MainActor
public final class DefaultActivityHeatmapProvider: ActivityHeatmapProviding {
    public private(set) var currentSnapshot: ActivityHeatmapSnapshot?
    public private(set) var isLoading = false
    private var observers: [WeakObserver] = []

    public init(snapshot: ActivityHeatmapSnapshot? = nil) {
        self.currentSnapshot = snapshot
    }

    public func setSnapshot(_ snapshot: ActivityHeatmapSnapshot?) {
        guard currentSnapshot != snapshot else { return }
        currentSnapshot = snapshot
        observers.removeAll { $0.handle == nil }
        for observer in observers {
            observer.handle?.invoke(.snapshotChanged)
        }
    }

    public func setLoading(_ isLoading: Bool) {
        guard self.isLoading != isLoading else { return }
        self.isLoading = isLoading
        observers.removeAll { $0.handle == nil }
        for observer in observers {
            observer.handle?.invoke(.loadingChanged)
        }
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (ActivityHeatmapEvent) -> Void
    ) -> any ActivityHeatmapObserverHandle {
        let handle = ObserverHandle(owner: self, callback: callback)
        observers.append(WeakObserver(handle))
        return handle
    }

    private func removeObserver(_ handle: ObserverHandle) {
        observers.removeAll { $0.handle === handle }
    }

    @MainActor
    private final class ObserverHandle: ActivityHeatmapObserverHandle {
        private weak var owner: DefaultActivityHeatmapProvider?
        private let callback: (ActivityHeatmapEvent) -> Void
        private var isCancelled = false

        init(
            owner: DefaultActivityHeatmapProvider,
            callback: @escaping (ActivityHeatmapEvent) -> Void
        ) {
            self.owner = owner
            self.callback = callback
        }

        func cancel() {
            guard !isCancelled else { return }
            isCancelled = true
            owner?.removeObserver(self)
        }

        func invoke(_ event: ActivityHeatmapEvent) {
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
