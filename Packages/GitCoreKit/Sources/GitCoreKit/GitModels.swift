import Foundation

public struct GitStashEntry: Equatable, Sendable {
    public let index: Int
    public let message: String

    public init(index: Int, message: String) {
        self.index = index
        self.message = message
    }
}

public enum GitMergeFileState: String, Equatable, Sendable {
    case unresolved
    case pendingStage
    case staged
}

public struct GitMergeFile: Identifiable, Equatable, Sendable {
    public let path: String
    public let state: GitMergeFileState

    public init(path: String, state: GitMergeFileState) {
        self.path = path
        self.state = state
    }

    public var id: String { path }
}

public struct GitStatusEntry: Equatable, Sendable {
    public let path: String
    public let indexStatus: Character
    public let workTreeStatus: Character

    public init(path: String, indexStatus: Character, workTreeStatus: Character) {
        self.path = path
        self.indexStatus = indexStatus
        self.workTreeStatus = workTreeStatus
    }
}
