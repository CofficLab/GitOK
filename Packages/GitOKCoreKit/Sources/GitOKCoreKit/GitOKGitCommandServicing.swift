import Foundation

public enum GitOKGitCommand: Sendable {
    case refresh
    case fetch
    case pull
    case push
}

@MainActor
public protocol GitOKGitCommandServicing: AnyObject {
    func performGitCommand(_ command: GitOKGitCommand)
}
