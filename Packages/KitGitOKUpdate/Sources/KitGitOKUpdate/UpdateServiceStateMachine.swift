import Foundation

public enum UpdateLifecycleState: String, Sendable {
    case idle
    case checking
    case downloading
    case readyToInstall
    case installing
    case error
}

/// 记录更新生命周期，避免把 Sparkle 的状态直接暴露给设置或菜单层。
public actor UpdateServiceStateMachine {
    public private(set) var state: UpdateLifecycleState = .idle
    public private(set) var latestVersion: String?

    public init() {}

    public func beginChecking() {
        state = .checking
    }

    public func beginDownloading() {
        state = .downloading
    }

    public func markReadyToInstall(version: String) {
        state = .readyToInstall
        latestVersion = version
    }

    public func beginInstalling() {
        state = .installing
    }

    public func markError() {
        state = .error
    }

    public func reset() {
        state = .idle
        latestVersion = nil
    }
}
