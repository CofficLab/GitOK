import GitCoreKit
import ProjectRulesKit

// MARK: - Branch Logic (pure, no Git calls)

enum BranchLogic {

    // MARK: Filtering

    static func filter(branches: [GitBranchSummary], query: String) -> [GitBranchSummary] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.isEmpty == false else { return branches }
        return branches.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    static func filter(remoteBranches: [String], query: String) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.isEmpty == false else { return remoteBranches }
        return remoteBranches.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    // MARK: Selection

    static func selectCurrentBranch(in branches: [GitBranchSummary]) -> GitBranchSummary? {
        branches.first(where: \.isCurrent)
    }

    static func selectBranch(named name: String?, in branches: [GitBranchSummary]) -> GitBranchSummary? {
        guard let name else { return nil }
        return branches.first(where: { $0.name == name })
    }

    // MARK: Compare Selection

    static func updateCompareSelection(
        branches: [GitBranchSummary],
        currentBranch: GitBranchSummary?,
        existingBase: GitBranchSummary?,
        existingHead: GitBranchSummary?
    ) -> (base: GitBranchSummary?, head: GitBranchSummary?) {
        guard branches.count >= 2 else { return (nil, nil) }

        let base: GitBranchSummary?
        if let existingBase, branches.contains(where: { $0.id == existingBase.id }) {
            base = existingBase
        } else {
            base = currentBranch ?? branches.first
        }

        let head: GitBranchSummary?
        if let existingHead,
           branches.contains(where: { $0.id == existingHead.id }),
           existingHead.id != base?.id {
            head = existingHead
        } else {
            head = branches.first(where: { $0.id != base?.id })
        }

        return (base, head)
    }

    // MARK: Remote Branch Name Parsing

    /// Parses "origin/feat" into ("origin", "feat"). Returns nil if format is invalid.
    static func parseRemoteBranch(_ name: String) -> (remote: String, branch: String)? {
        let parts = name.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }

    // MARK: Preferred Remote URL

    static func preferredRemoteURL(from remotes: [GitRemoteSummary]) -> String? {
        let preferred = remotes.first(where: { $0.name == "origin" }) ?? remotes.first
        let url = preferred?.url
        if let url, url.isEmpty == false { return url }
        let fetchURL = preferred?.fetchURL
        if let fetchURL, fetchURL.isEmpty == false { return fetchURL }
        let pushURL = preferred?.pushURL
        if let pushURL, pushURL.isEmpty == false { return pushURL }
        return nil
    }

    // MARK: PR Links

    static func pullRequestLinks(
        remoteURL: String?,
        baseBranch: String?,
        headBranch: String?
    ) -> RemoteRepositoryFormRules.PullRequestWebLinks? {
        guard let remoteURL, let baseBranch, let headBranch else { return nil }
        return RemoteRepositoryFormRules.pullRequestWebLinks(
            remoteURL: remoteURL,
            baseBranch: baseBranch,
            headBranch: headBranch
        )
    }
}
