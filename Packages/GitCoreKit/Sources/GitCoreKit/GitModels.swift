import Foundation

public struct GitStashEntry: Equatable, Sendable {
    public let index: Int
    public let message: String
    public let branchName: String?
    public let relativeDate: String?
    public let changedFileCount: Int
    public let diffPreview: String

    public init(
        index: Int,
        message: String,
        branchName: String? = nil,
        relativeDate: String? = nil,
        changedFileCount: Int = 0,
        diffPreview: String = ""
    ) {
        self.index = index
        self.message = message
        self.branchName = branchName
        self.relativeDate = relativeDate
        self.changedFileCount = changedFileCount
        self.diffPreview = diffPreview
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

public struct GitAheadBehind: Equatable, Sendable {
    public let ahead: Int
    public let behind: Int
    public let hasUpstream: Bool

    public init(ahead: Int, behind: Int, hasUpstream: Bool) {
        self.ahead = ahead
        self.behind = behind
        self.hasUpstream = hasUpstream
    }

    public static let noUpstream = GitAheadBehind(ahead: 0, behind: 0, hasUpstream: false)
}
