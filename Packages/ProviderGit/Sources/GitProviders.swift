import Foundation

/// Repository operations exposed to plugins and host commands.
@MainActor
public protocol GitOKRepositoryServicing: AnyObject {
    func projectExists(at url: URL) -> Bool
    func importRepository(at url: URL) -> Bool
}

/// Activity state shared by long-running Git operations.
@MainActor
public protocol GitOKActivityServicing: AnyObject {
    var activityStatus: String? { get }
    func setActivityStatus(_ status: String?)
}

public enum GitOKGitCommand: Sendable {
    case refresh
    case fetch
    case pull
    case push
}

/// Git commands exposed by the app shell.
@MainActor
public protocol GitOKGitCommandServicing: AnyObject {
    func performGitCommand(_ command: GitOKGitCommand)
}
