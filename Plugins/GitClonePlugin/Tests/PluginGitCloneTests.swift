import Testing
import GitOKCoreKit
@testable import GitClonePlugin

@Suite("GitClonePlugin")
struct GitClonePluginTests {
    @Test("localized strings resolve from package bundle")
    func localizedStringsResolve() {
        #expect(GitCloneLocalization.string("Clone Repository").isEmpty == false)
        #expect(GitCloneLocalization.string("GitHub API URL is invalid").isEmpty == false)
    }

    @Test("GitHub host normalizes URL input")
    func normalizesGitHubHost() {
        #expect(CloneRepositorySheet.normalizedGitHubHost("https://github.example.com/team") == "github.example.com")
        #expect(CloneRepositorySheet.normalizedGitHubHost(" github.com ") == "github.com")
    }

    @MainActor
    @Test("plugin metadata and toolbar contribution use CoreKit context")
    func pluginMetadataAndToolbarContribution() {
        #expect(GitClonePlugin.metadata.id == "GitClonePlugin")
        #expect(GitClonePlugin.metadata.iconName == "square.and.arrow.down")
        #expect(GitClonePlugin.metadata.tableName == "Localizable")

        #expect(GitClonePlugin.shared.toolBarLeadingView(context: GitOKPluginContext()) == nil)

        let context = GitOKPluginContext(canImportRepository: true)
        #expect(GitClonePlugin.shared.toolBarLeadingView(context: context) != nil)
        _ = CloneRepositorySheet(context: context)
    }

    @Test("repository bridge stays compatible with App project selection")
    func bridgeReason() {
        #expect(GitRepositoryBridgeRules.projectSelectionReason == "RepositoryImport")
        #expect(GitRepositoryBridgeRules.projectExists(urlPath: "/repo") { path in
            path == "/repo"
        })
        struct URLFixture {
            let path: String
        }
        #expect(GitRepositoryBridgeRules.projectExists(
            url: URLFixture(path: "/repo"),
            path: \.path,
            exists: { $0 == "/repo" }
        ))

        var selections: [String] = []
        #expect(GitRepositoryBridgeRules.performRepositoryImportCompletion(
            addProject: { "repo" },
            selectProject: { selections.append("\($0):\($1)") }
        ))
        #expect(selections == ["repo:\(GitRepositoryBridgeRules.projectSelectionReason)"])

        #expect(GitRepositoryBridgeRules.performRepositoryImportCompletion(
            addProject: { nil as String? },
            selectProject: { selections.append("\($0):\($1)") }
        ) == false)
        #expect(selections == ["repo:\(GitRepositoryBridgeRules.projectSelectionReason)"])

        var infoMessages: [String] = []
        GitRepositoryBridgeRules.performRepositoryImportSuccessMessage("clone completed") {
            infoMessages.append($0)
        }
        #expect(infoMessages == ["clone completed"])
    }
}
