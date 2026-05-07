import Foundation

enum AutoPushCheckDecision: Equatable {
    case skip(AutoPushSkipReason)
    case shouldPush(branchName: String)
}

enum AutoPushSkipReason: Equatable {
    case missingBranch
    case disabled
    case notGitRepository
    case missingRemote
}

enum AutoPushExecutionDecision: Equatable {
    case skipAlreadyPushing
    case markIdle
    case push
}

enum AutoPushDecision {
    static func check(
        currentBranchName: String?,
        isEnabled: Bool,
        isGitRepo: Bool,
        hasRemote: Bool
    ) -> AutoPushCheckDecision {
        guard let currentBranchName, !currentBranchName.isEmpty else {
            return .skip(.missingBranch)
        }

        guard isEnabled else {
            return .skip(.disabled)
        }

        guard isGitRepo else {
            return .skip(.notGitRepository)
        }

        guard hasRemote else {
            return .skip(.missingRemote)
        }

        return .shouldPush(branchName: currentBranchName)
    }

    static func execution(
        isAlreadyPushing: Bool,
        unpushedCommitCount: Int
    ) -> AutoPushExecutionDecision {
        if isAlreadyPushing {
            return .skipAlreadyPushing
        }

        if unpushedCommitCount <= 0 {
            return .markIdle
        }

        return .push
    }
}
