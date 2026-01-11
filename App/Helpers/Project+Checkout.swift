import Foundation
import LibGit2Swift

// This file only imports LibGit2Swift to avoid ambiguity
// We use a struct to pass the branch data instead of using MagicKit types directly

public struct MagicKitBranchData {
    public let id: String
    public let name: String
    public let isCurrent: Bool
    public let upstream: String?
    public let latestCommitHash: String
    public let latestCommitMessage: String

    public init(id: String, name: String, isCurrent: Bool, upstream: String?, latestCommitHash: String, latestCommitMessage: String) {
        self.id = id
        self.name = name
        self.isCurrent = isCurrent
        self.upstream = upstream
        self.latestCommitHash = latestCommitHash
        self.latestCommitMessage = latestCommitMessage
    }
}

extension Project {
    func checkout(magicKitBranchData: MagicKitBranchData) throws {
        let lgBranch = GitBranch(
            id: magicKitBranchData.id,
            name: magicKitBranchData.name,
            isCurrent: magicKitBranchData.isCurrent,
            upstream: magicKitBranchData.upstream,
            latestCommitHash: magicKitBranchData.latestCommitHash,
            latestCommitMessage: magicKitBranchData.latestCommitMessage
        )
        try checkout(branch: lgBranch)
    }
}
