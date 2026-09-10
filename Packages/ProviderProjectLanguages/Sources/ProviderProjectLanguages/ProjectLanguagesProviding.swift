import Foundation

/// A language detected in a repository, weighted by the bytes it occupies.
public struct ProjectLanguage: Codable, Equatable, Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let byteCount: Int64

    public init(id: String, name: String, byteCount: Int64) {
        self.id = id
        self.name = name
        self.byteCount = max(0, byteCount)
    }
}

/// A repository language snapshot produced by a language analysis plugin.
public struct ProjectLanguagesSnapshot: Codable, Equatable, Sendable {
    public let repositoryPath: String
    public let generatedAt: Date
    public let languages: [ProjectLanguage]

    public init(
        repositoryPath: String,
        generatedAt: Date = Date(),
        languages: [ProjectLanguage]
    ) {
        self.repositoryPath = repositoryPath
        self.generatedAt = generatedAt
        self.languages = languages
            .filter { $0.byteCount > 0 }
            .sorted {
                if $0.byteCount != $1.byteCount {
                    return $0.byteCount > $1.byteCount
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    public var totalByteCount: Int64 {
        languages.reduce(0) { $0 + $1.byteCount }
    }

    public func percentage(for language: ProjectLanguage) -> Double {
        guard totalByteCount > 0 else { return 0 }
        return Double(language.byteCount) / Double(totalByteCount)
    }
}

@MainActor
public enum ProjectLanguagesEvent {
    case snapshotChanged
    case loadingChanged
}

@MainActor
public protocol ProjectLanguagesObserverHandle: AnyObject {
    func cancel()
}

/// Data contract for repository language statistics.
///
/// The provider does not know how languages are detected. A plugin may use
/// local Git metadata, a Linguist-compatible analyzer, or another source.
@MainActor
public protocol ProjectLanguagesProviding: AnyObject {
    var currentSnapshot: ProjectLanguagesSnapshot? { get }
    var isLoading: Bool { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectLanguagesEvent) -> Void
    ) -> any ProjectLanguagesObserverHandle

    func refresh(for repository: URL?)
}

/// In-memory implementation used by hosts and tests.
@MainActor
public final class DefaultProjectLanguagesProvider: ProjectLanguagesProviding {
    public private(set) var currentSnapshot: ProjectLanguagesSnapshot?
    public private(set) var isLoading = false
    private var observers: [WeakObserver] = []

    public init(snapshot: ProjectLanguagesSnapshot? = nil) {
        self.currentSnapshot = snapshot
    }

    public func refresh(for repository: URL?) {}

    public func setSnapshot(_ snapshot: ProjectLanguagesSnapshot?) {
        guard currentSnapshot != snapshot else { return }
        currentSnapshot = snapshot
        notify(.snapshotChanged)
    }

    public func setLoading(_ isLoading: Bool) {
        guard self.isLoading != isLoading else { return }
        self.isLoading = isLoading
        notify(.loadingChanged)
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (ProjectLanguagesEvent) -> Void
    ) -> any ProjectLanguagesObserverHandle {
        let handle = ObserverHandle(owner: self, callback: callback)
        observers.append(WeakObserver(handle))
        return handle
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
        private weak var owner: DefaultProjectLanguagesProvider?
        private let callback: (ProjectLanguagesEvent) -> Void
        private var isCancelled = false

        init(
            owner: DefaultProjectLanguagesProvider,
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
