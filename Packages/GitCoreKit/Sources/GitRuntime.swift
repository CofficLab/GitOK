import Foundation
@_exported import LibGit2Swift

public enum GitRuntime {
    private nonisolated(unsafe) static let initializeLock = NSLock()
    private nonisolated(unsafe) static var didInitialize = false

    public static func initialize() {
        initializeLock.lock()
        defer { initializeLock.unlock() }

        guard didInitialize == false else {
            return
        }

        LibGit2.initialize()
        didInitialize = true
    }

    public static func versionString() -> String {
        LibGit2.versionString()
    }
}
