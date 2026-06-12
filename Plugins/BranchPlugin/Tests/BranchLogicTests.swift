@testable import BranchPlugin
import GitCoreKit
import Testing

@Suite("BranchLogic Tests")
struct BranchLogicTests {

    // MARK: - Filter Branches

    @Test("filter returns all branches with empty query")
    func filterEmptyQuery() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
        ])
        let result = BranchLogic.filter(branches: branches, query: "")
        #expect(result.count == 2)
    }

    @Test("filter returns all branches with whitespace-only query")
    func filterWhitespaceQuery() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
        ])
        let result = BranchLogic.filter(branches: branches, query: "  ")
        #expect(result.count == 2)
    }

    @Test("filter matches case-insensitively")
    func filterCaseInsensitive() {
        let branches = Self.makeBranches([
            ("feature/login", false, false),
            ("bugfix/crash", false, false),
            ("main", false, true),
        ])
        let result = BranchLogic.filter(branches: branches, query: "FEATURE")
        #expect(result.count == 1)
        #expect(result[0].name == "feature/login")
    }

    @Test("filter returns empty when no match")
    func filterNoMatch() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
        ])
        let result = BranchLogic.filter(branches: branches, query: "nonexistent")
        #expect(result.isEmpty)
    }

    @Test("filter matches partial string")
    func filterPartial() {
        let branches = Self.makeBranches([
            ("feature/login", false, false),
            ("feature/signup", false, false),
            ("bugfix/crash", false, false),
        ])
        let result = BranchLogic.filter(branches: branches, query: "feature")
        #expect(result.count == 2)
    }

    // MARK: - Filter Remote Branches

    @Test("filter remote branches with empty query returns all")
    func filterRemoteEmptyQuery() {
        let remotes = ["origin/main", "origin/develop"]
        let result = BranchLogic.filter(remoteBranches: remotes, query: "")
        #expect(result.count == 2)
    }

    @Test("filter remote branches matches substring")
    func filterRemoteSubstring() {
        let remotes = ["origin/main", "origin/develop", "upstream/main"]
        let result = BranchLogic.filter(remoteBranches: remotes, query: "upstream")
        #expect(result.count == 1)
        #expect(result[0] == "upstream/main")
    }

    // MARK: - Select Current Branch

    @Test("selectCurrentBranch returns current branch")
    func selectCurrent() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
        ])
        let result = BranchLogic.selectCurrentBranch(in: branches)
        #expect(result?.name == "main")
    }

    @Test("selectCurrentBranch returns nil when no current branch")
    func selectCurrentNone() {
        let branches = Self.makeBranches([
            ("main", false, false),
            ("develop", false, false),
        ])
        let result = BranchLogic.selectCurrentBranch(in: branches)
        #expect(result == nil)
    }

    @Test("selectCurrentBranch returns nil for empty list")
    func selectCurrentEmpty() {
        let result = BranchLogic.selectCurrentBranch(in: [])
        #expect(result == nil)
    }

    // MARK: - Select Branch by Name

    @Test("selectBranch returns matching branch")
    func selectBranchByName() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
        ])
        let result = BranchLogic.selectBranch(named: "develop", in: branches)
        #expect(result?.name == "develop")
    }

    @Test("selectBranch returns nil for nil name")
    func selectBranchNilName() {
        let branches = Self.makeBranches([
            ("main", false, true),
        ])
        let result = BranchLogic.selectBranch(named: nil, in: branches)
        #expect(result == nil)
    }

    @Test("selectBranch returns nil for missing name")
    func selectBranchMissing() {
        let branches = Self.makeBranches([
            ("main", false, true),
        ])
        let result = BranchLogic.selectBranch(named: "nonexistent", in: branches)
        #expect(result == nil)
    }

    // MARK: - Update Compare Selection

    @Test("updateCompareSelection returns nil for less than 2 branches")
    func compareSelectionLessThanTwo() {
        let branches = Self.makeBranches([("main", false, true)])
        let (base, head) = BranchLogic.updateCompareSelection(
            branches: branches, currentBranch: nil, existingBase: nil, existingHead: nil)
        #expect(base == nil)
        #expect(head == nil)
    }

    @Test("updateCompareSelection returns nil for empty list")
    func compareSelectionEmpty() {
        let (base, head) = BranchLogic.updateCompareSelection(
            branches: [], currentBranch: nil, existingBase: nil, existingHead: nil)
        #expect(base == nil)
        #expect(head == nil)
    }

    @Test("updateCompareSelection defaults to current branch as base")
    func compareSelectionDefaultsCurrentAsBase() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
        ])
        let current = branches[0]
        let (base, head) = BranchLogic.updateCompareSelection(
            branches: branches, currentBranch: current, existingBase: nil, existingHead: nil)
        #expect(base?.name == "main")
        #expect(head?.name == "develop")
    }

    @Test("updateCompareSelection falls back to first branch as base when no current")
    func compareSelectionFallsBackFirstAsBase() {
        let branches = Self.makeBranches([
            ("main", false, false),
            ("develop", false, false),
        ])
        let (base, head) = BranchLogic.updateCompareSelection(
            branches: branches, currentBranch: nil, existingBase: nil, existingHead: nil)
        #expect(base?.name == "main")
        #expect(head?.name == "develop")
    }

    @Test("updateCompareSelection keeps existing valid selection")
    func compareSelectionKeepsExisting() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
            ("feature", false, false),
        ])
        let existingBase = branches[1] // develop
        let existingHead = branches[2] // feature
        let (base, head) = BranchLogic.updateCompareSelection(
            branches: branches, currentBranch: branches[0], existingBase: existingBase, existingHead: existingHead)
        #expect(base?.name == "develop")
        #expect(head?.name == "feature")
    }

    @Test("updateCompareSelection resets when existing base is gone")
    func compareSelectionResetsWhenBaseGone() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
        ])
        let goneBase = GitBranchSummary(name: "deleted", isRemote: false, isCurrent: false)
        let existingHead = branches[1]
        let (base, head) = BranchLogic.updateCompareSelection(
            branches: branches, currentBranch: branches[0], existingBase: goneBase, existingHead: existingHead)
        #expect(base?.name == "main") // Falls back to current
        #expect(head?.name == "develop")
    }

    @Test("updateCompareSelection picks different head when existing matches base")
    func compareSelectionPicksDifferentHead() {
        let branches = Self.makeBranches([
            ("main", false, true),
            ("develop", false, false),
            ("feature", false, false),
        ])
        let sameBranch = branches[0]
        let (base, head) = BranchLogic.updateCompareSelection(
            branches: branches, currentBranch: sameBranch, existingBase: sameBranch, existingHead: sameBranch)
        #expect(base?.name == "main")
        #expect(head?.name == "develop") // Picks first non-matching
    }

    // MARK: - Parse Remote Branch

    @Test("parseRemoteBranch parses origin/feat correctly")
    func parseRemoteBranchValid() {
        let result = BranchLogic.parseRemoteBranch("origin/feat")
        #expect(result?.remote == "origin")
        #expect(result?.branch == "feat")
    }

    @Test("parseRemoteBranch parses upstream/feature/login")
    func parseRemoteBranchWithSlash() {
        let result = BranchLogic.parseRemoteBranch("upstream/feature/login")
        #expect(result?.remote == "upstream")
        #expect(result?.branch == "feature/login")
    }

    @Test("parseRemoteBranch returns nil for no slash")
    func parseRemoteBranchNoSlash() {
        let result = BranchLogic.parseRemoteBranch("main")
        #expect(result == nil)
    }

    @Test("parseRemoteBranch returns nil for empty string")
    func parseRemoteBranchEmpty() {
        let result = BranchLogic.parseRemoteBranch("")
        #expect(result == nil)
    }

    @Test("parseRemoteBranch returns nil for just slash")
    func parseRemoteBranchJustSlash() {
        let result = BranchLogic.parseRemoteBranch("/")
        // "/" splits into empty parts → count < 2 → nil
        #expect(result == nil)
    }

    // MARK: - Preferred Remote URL

    @Test("preferredRemoteURL picks origin")
    func preferredRemoteURLOrigin() {
        let remotes = [
            GitRemoteSummary(id: "1", name: "upstream", url: "https://upstream.com/repo.git", fetchURL: nil, pushURL: nil, isDefault: false),
            GitRemoteSummary(id: "2", name: "origin", url: "https://origin.com/repo.git", fetchURL: nil, pushURL: nil, isDefault: false),
        ]
        let result = BranchLogic.preferredRemoteURL(from: remotes)
        #expect(result == "https://origin.com/repo.git")
    }

    @Test("preferredRemoteURL falls back to first when no origin")
    func preferredRemoteURLFallback() {
        let remotes = [
            GitRemoteSummary(id: "1", name: "upstream", url: "https://upstream.com/repo.git", fetchURL: nil, pushURL: nil, isDefault: false),
        ]
        let result = BranchLogic.preferredRemoteURL(from: remotes)
        #expect(result == "https://upstream.com/repo.git")
    }

    @Test("preferredRemoteURL uses fetchURL when url is nil")
    func preferredRemoteURLFetchFallback() {
        let remotes = [
            GitRemoteSummary(id: "1", name: "origin", url: "", fetchURL: "https://fetch.com/repo.git", pushURL: nil, isDefault: false),
        ]
        let result = BranchLogic.preferredRemoteURL(from: remotes)
        #expect(result == "https://fetch.com/repo.git")
    }

    @Test("preferredRemoteURL uses pushURL when url and fetchURL are nil")
    func preferredRemoteURLPushFallback() {
        let remotes = [
            GitRemoteSummary(id: "1", name: "origin", url: "", fetchURL: nil, pushURL: "https://push.com/repo.git", isDefault: false),
        ]
        let result = BranchLogic.preferredRemoteURL(from: remotes)
        #expect(result == "https://push.com/repo.git")
    }

    @Test("preferredRemoteURL returns nil for empty list")
    func preferredRemoteURLEmpty() {
        let result = BranchLogic.preferredRemoteURL(from: [])
        #expect(result == nil)
    }

    // MARK: - Pull Request Links

    @Test("pullRequestLinks returns nil when remoteURL is nil")
    func prLinksNilRemote() {
        let result = BranchLogic.pullRequestLinks(remoteURL: nil, baseBranch: "main", headBranch: "feature")
        #expect(result == nil)
    }

    @Test("pullRequestLinks returns nil when baseBranch is nil")
    func prLinksNilBase() {
        let result = BranchLogic.pullRequestLinks(remoteURL: "https://github.com/a/b.git", baseBranch: nil, headBranch: "feature")
        #expect(result == nil)
    }

    @Test("pullRequestLinks returns nil when headBranch is nil")
    func prLinksNilHead() {
        let result = BranchLogic.pullRequestLinks(remoteURL: "https://github.com/a/b.git", baseBranch: "main", headBranch: nil)
        #expect(result == nil)
    }

    @Test("pullRequestLinks returns links for valid GitHub URL")
    func prLinksGitHub() {
        let result = BranchLogic.pullRequestLinks(
            remoteURL: "https://github.com/owner/repo.git",
            baseBranch: "main",
            headBranch: "feature"
        )
        #expect(result != nil)
        #expect(result?.createURL.absoluteString.contains("compare") == true)
    }

    // MARK: - Helper

    private static func makeBranches(_ names: [(name: String, isRemote: Bool, isCurrent: Bool)]) -> [GitBranchSummary] {
        names.map { GitBranchSummary(name: $0.name, isRemote: $0.isRemote, isCurrent: $0.isCurrent) }
    }
}
