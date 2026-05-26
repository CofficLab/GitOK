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

public enum GitMergeFileVersion: String, CaseIterable, Equatable, Sendable {
    case base
    case ours
    case theirs

    public var stageNumber: Int {
        switch self {
        case .base:
            return 1
        case .ours:
            return 2
        case .theirs:
            return 3
        }
    }
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

public enum GitPatchApplyMode: Equatable, Sendable {
    case stage
    case unstage
}

public enum GitResetMode: String, CaseIterable, Equatable, Sendable {
    case soft
    case mixed
    case hard
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

public struct GitBranchCompareCommit: Identifiable, Equatable, Sendable {
    public let hash: String
    public let author: String
    public let date: Date
    public let subject: String

    public init(hash: String, author: String, date: Date, subject: String) {
        self.hash = hash
        self.author = author
        self.date = date
        self.subject = subject
    }

    public var id: String { hash }
}

public struct GitBranchCompareFile: Identifiable, Equatable, Sendable {
    public let status: String
    public let path: String
    public let oldPath: String?

    public init(status: String, path: String, oldPath: String? = nil) {
        self.status = status
        self.path = path
        self.oldPath = oldPath
    }

    public var id: String {
        if let oldPath {
            return "\(status):\(oldPath)->\(path)"
        }
        return "\(status):\(path)"
    }
}

public struct GitBranchCompare: Equatable, Sendable {
    public let base: String
    public let head: String
    public let ahead: Int
    public let behind: Int
    public let commits: [GitBranchCompareCommit]
    public let files: [GitBranchCompareFile]

    public init(
        base: String,
        head: String,
        ahead: Int,
        behind: Int,
        commits: [GitBranchCompareCommit],
        files: [GitBranchCompareFile]
    ) {
        self.base = base
        self.head = head
        self.ahead = ahead
        self.behind = behind
        self.commits = commits
        self.files = files
    }
}

public struct GitRebaseStatus: Equatable, Sendable {
    public let isRebasing: Bool
    public let branchName: String?
    public let onto: String?
    public let currentStep: Int?
    public let totalSteps: Int?

    public init(
        isRebasing: Bool,
        branchName: String? = nil,
        onto: String? = nil,
        currentStep: Int? = nil,
        totalSteps: Int? = nil
    ) {
        self.isRebasing = isRebasing
        self.branchName = branchName
        self.onto = onto
        self.currentStep = currentStep
        self.totalSteps = totalSteps
    }

    public static let inactive = GitRebaseStatus(isRebasing: false)
}

public struct GitCherryPickStatus: Equatable, Sendable {
    public let isCherryPicking: Bool
    public let commitHash: String?

    public init(isCherryPicking: Bool, commitHash: String? = nil) {
        self.isCherryPicking = isCherryPicking
        self.commitHash = commitHash
    }

    public static let inactive = GitCherryPickStatus(isCherryPicking: false)
}
