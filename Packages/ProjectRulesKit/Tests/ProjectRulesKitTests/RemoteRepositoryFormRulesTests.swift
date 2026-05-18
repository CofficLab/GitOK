import Foundation
import ProjectRulesKit
import Testing

@Suite("RemoteRepositoryFormRulesTests")
struct RemoteRepositoryFormRulesTests {
    @Test("Normalization trims whitespace from both fields")
    func normalizationTrimsWhitespaceFromBothFields() {
        let input = RemoteRepositoryFormRules.normalizedInput(
            name: "  origin \n",
            url: "  https://github.com/a/b.git \t"
        )

        #expect(input.name == "origin")
        #expect(input.url == "https://github.com/a/b.git")
    }

    @Test("Form validity requires both normalized fields")
    func formValidityRequiresBothNormalizedFields() {
        #expect(RemoteRepositoryFormRules.isFormValid(name: "origin", url: "https://github.com/a/b.git"))
        #expect(!RemoteRepositoryFormRules.isFormValid(name: "   ", url: "https://github.com/a/b.git"))
        #expect(!RemoteRepositoryFormRules.isFormValid(name: "origin", url: " \n "))
    }

    @Test("Change detection compares normalized edits against stored values")
    func changeDetectionComparesNormalizedEditsAgainstStoredValues() {
        #expect(!RemoteRepositoryFormRules.hasChanges(
            originalName: "origin",
            originalURL: "https://github.com/a/b.git",
            editedName: " origin ",
            editedURL: "https://github.com/a/b.git\n"
        ))
        #expect(RemoteRepositoryFormRules.hasChanges(
            originalName: "origin",
            originalURL: "https://github.com/a/b.git",
            editedName: "upstream",
            editedURL: "https://github.com/a/b.git"
        ))
        #expect(RemoteRepositoryFormRules.hasChanges(
            originalName: "origin",
            originalURL: "https://github.com/a/b.git",
            editedName: "origin",
            editedURL: "https://github.com/c/d.git"
        ))
    }

    @Test("Delete warning explains upstream impact")
    func deleteWarningExplainsUpstreamImpact() {
        #expect(RemoteRepositoryFormRules.deleteWarning(remoteName: "origin", isCurrentUpstreamRemote: true).contains("无 upstream"))
        #expect(RemoteRepositoryFormRules.deleteWarning(remoteName: "mirror", isCurrentUpstreamRemote: false).contains("Fetch/Pull"))
    }

    @Test("Remote web link recognizes common hosting providers")
    func remoteWebLinkRecognizesCommonHostingProviders() {
        let cases: [(String, RemoteRepositoryFormRules.HostingProvider, String)] = [
            ("git@github.com:owner/repo.git", .github, "https://github.com/owner/repo"),
            ("ssh://git@gitlab.com/group/repo.git", .gitlab, "https://gitlab.com/group/repo"),
            ("git://bitbucket.org/team/repo.git", .bitbucket, "https://bitbucket.org/team/repo"),
            ("https://dev.azure.com/org/project/_git/repo", .azureDevOps, "https://dev.azure.com/org/project/_git/repo"),
            ("git@ssh.dev.azure.com:v3/org/project/repo", .azureDevOps, "https://ssh.dev.azure.com/v3/org/project/repo"),
        ]

        for (remoteURL, provider, webURL) in cases {
            let link = RemoteRepositoryFormRules.remoteWebLink(for: remoteURL)
            #expect(link?.provider == provider)
            #expect(link?.url.absoluteString == webURL)
            #expect(link?.authenticationNote.isEmpty == false)
        }
    }

    @Test("Remote web link rejects unsupported local paths")
    func remoteWebLinkRejectsUnsupportedLocalPaths() {
        #expect(RemoteRepositoryFormRules.remoteWebLink(for: "/tmp/repo.git") == nil)
        #expect(RemoteRepositoryFormRules.remoteWebLink(for: "file:///tmp/repo.git") == nil)
        #expect(RemoteRepositoryFormRules.remoteWebLink(for: "   ") == nil)
    }

    @Test("Pull request web links map common hosting providers")
    func pullRequestWebLinksMapCommonHostingProviders() {
        let github = RemoteRepositoryFormRules.pullRequestWebLinks(
            remoteURL: "git@github.com:owner/repo.git",
            baseBranch: "main",
            headBranch: "feature/pr"
        )
        #expect(github?.provider == .github)
        #expect(github?.listURL.absoluteString == "https://github.com/owner/repo/pulls")
        #expect(github?.createURL.absoluteString == "https://github.com/owner/repo/compare/main...feature/pr")
        #expect(github?.branchURL.absoluteString.contains("head:feature/pr") == true)
        #expect(github?.reviewRequestsURL.absoluteString.contains("review-requested:@me") == true)
        #expect(github?.commentsURL.absoluteString.contains("commenter:@me") == true)
        #expect(github?.notificationsURL.absoluteString.contains("github.com/notifications") == true)

        let gitlab = RemoteRepositoryFormRules.pullRequestWebLinks(
            remoteURL: "https://gitlab.com/group/repo.git",
            baseBranch: "main",
            headBranch: "feature/pr"
        )
        #expect(gitlab?.provider == .gitlab)
        #expect(gitlab?.listURL.absoluteString == "https://gitlab.com/group/repo/-/merge_requests")
        #expect(gitlab?.createURL.absoluteString.contains("merge_request%5Bsource_branch%5D=feature/pr") == true)
        #expect(gitlab?.createURL.absoluteString.contains("merge_request%5Btarget_branch%5D=main") == true)
        #expect(gitlab?.reviewRequestsURL.absoluteString.contains("reviewer_username=@me") == true)
        #expect(gitlab?.commentsURL.absoluteString.contains("state=opened") == true)
        #expect(gitlab?.notificationsURL.absoluteString == "https://gitlab.com/group/repo/-/activity")

        let bitbucket = RemoteRepositoryFormRules.pullRequestWebLinks(
            remoteURL: "git://bitbucket.org/team/repo.git",
            baseBranch: "main",
            headBranch: "feature/pr"
        )
        #expect(bitbucket?.provider == .bitbucket)
        #expect(bitbucket?.listURL.absoluteString == "https://bitbucket.org/team/repo/pull-requests")
        #expect(bitbucket?.createURL.absoluteString.contains("source=feature/pr") == true)
        #expect(bitbucket?.reviewRequestsURL.absoluteString.contains("state=OPEN") == true)
        #expect(bitbucket?.commentsURL.absoluteString.contains("state=OPEN") == true)

        let azure = RemoteRepositoryFormRules.pullRequestWebLinks(
            remoteURL: "https://dev.azure.com/org/project/_git/repo",
            baseBranch: "main",
            headBranch: "feature/pr"
        )
        #expect(azure?.provider == .azureDevOps)
        #expect(azure?.listURL.absoluteString == "https://dev.azure.com/org/project/_git/repo/pullrequests")
        #expect(azure?.createURL.absoluteString.contains("sourceRef=refs/heads/feature/pr") == true)
        #expect(azure?.reviewRequestsURL.absoluteString.contains("reviewer=@me") == true)
        #expect(azure?.notificationsURL.absoluteString.contains("status=active") == true)
    }

    @Test("Pull request web links require recognized remote and branches")
    func pullRequestWebLinksRequireRecognizedRemoteAndBranches() {
        #expect(RemoteRepositoryFormRules.pullRequestWebLinks(remoteURL: "/tmp/repo.git", baseBranch: "main", headBranch: "feature") == nil)
        #expect(RemoteRepositoryFormRules.pullRequestWebLinks(remoteURL: "https://github.com/owner/repo.git", baseBranch: " ", headBranch: "feature") == nil)
        #expect(RemoteRepositoryFormRules.pullRequestWebLinks(remoteURL: "https://github.com/owner/repo.git", baseBranch: "main", headBranch: " ") == nil)
    }

    @Test("CI web links map common hosting providers")
    func ciWebLinksMapCommonHostingProviders() {
        let github = RemoteRepositoryFormRules.ciWebLinks(
            remoteURL: "git@github.com:owner/repo.git",
            commitHash: "abc123"
        )
        #expect(github?.provider == .github)
        #expect(github?.checksURL.absoluteString == "https://github.com/owner/repo/commit/abc123/checks")
        #expect(github?.runsURL.absoluteString.contains("actions") == true)
        #expect(github?.runsURL.absoluteString.contains("abc123") == true)
        #expect(github?.statusNote.contains("API") == true)

        let gitlab = RemoteRepositoryFormRules.ciWebLinks(
            remoteURL: "https://gitlab.com/group/repo.git",
            commitHash: "abc123"
        )
        #expect(gitlab?.provider == .gitlab)
        #expect(gitlab?.checksURL.absoluteString == "https://gitlab.com/group/repo/-/commit/abc123/pipelines")
        #expect(gitlab?.runsURL.absoluteString.contains("-/pipelines") == true)
        #expect(gitlab?.runsURL.absoluteString.contains("sha=abc123") == true)

        let bitbucket = RemoteRepositoryFormRules.ciWebLinks(
            remoteURL: "git://bitbucket.org/team/repo.git",
            commitHash: "abc123"
        )
        #expect(bitbucket?.provider == .bitbucket)
        #expect(bitbucket?.checksURL.absoluteString == "https://bitbucket.org/team/repo/commits/abc123")
        #expect(bitbucket?.runsURL.absoluteString.contains("pipelines/results") == true)

        let azure = RemoteRepositoryFormRules.ciWebLinks(
            remoteURL: "https://dev.azure.com/org/project/_git/repo",
            commitHash: "abc123"
        )
        #expect(azure?.provider == .azureDevOps)
        #expect(azure?.checksURL.absoluteString == "https://dev.azure.com/org/project/_git/repo/commit/abc123")
        #expect(azure?.runsURL.absoluteString.contains("https://dev.azure.com/org/project/_build") == true)
        #expect(azure?.runsURL.absoluteString.contains("sourceVersion=abc123") == true)
    }

    @Test("CI web links require recognized remote and commit")
    func ciWebLinksRequireRecognizedRemoteAndCommit() {
        #expect(RemoteRepositoryFormRules.ciWebLinks(remoteURL: "/tmp/repo.git", commitHash: "abc123") == nil)
        #expect(RemoteRepositoryFormRules.ciWebLinks(remoteURL: "https://github.com/owner/repo.git", commitHash: " ") == nil)
    }
}
