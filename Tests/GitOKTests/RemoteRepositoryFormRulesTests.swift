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
}
