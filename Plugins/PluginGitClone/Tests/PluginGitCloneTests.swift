import Testing
import GitOKCoreKit
@testable import PluginGitClone

@Suite("PluginGitClone")
struct PluginGitCloneTests {
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
        #expect(GitClonePlugin.metadata.allowUserToggle == false)
        #expect(GitClonePlugin.metadata.defaultEnabled == false)
        #expect(GitClonePlugin.metadata.tableName == "Git-Clone")

        #expect(GitClonePlugin.shared.toolBarLeadingView(context: GitOKPluginContext()) == nil)

        let context = GitOKPluginContext(canCloneRepository: true)
        #expect(GitClonePlugin.shared.toolBarLeadingView(context: context) != nil)
        _ = CloneRepositorySheet(context: context)
    }

    @Test("bridge reason stays compatible with App project selection")
    func bridgeReason() {
        #expect(GitCloneBridgeRules.projectSelectionReason == "GitClone")
        #expect(GitCloneBridgeRules.projectExists(urlPath: "/repo") { path in
            path == "/repo"
        })
        struct URLFixture {
            let path: String
        }
        #expect(GitCloneBridgeRules.projectExists(
            url: URLFixture(path: "/repo"),
            path: \.path,
            exists: { $0 == "/repo" }
        ))

        var selections: [String] = []
        #expect(GitCloneBridgeRules.performCloneCompletion(
            addProject: { "repo" },
            selectProject: { selections.append("\($0):\($1)") }
        ))
        #expect(selections == ["repo:\(GitCloneBridgeRules.projectSelectionReason)"])

        #expect(GitCloneBridgeRules.performCloneCompletion(
            addProject: { nil as String? },
            selectProject: { selections.append("\($0):\($1)") }
        ) == false)
        #expect(selections == ["repo:\(GitCloneBridgeRules.projectSelectionReason)"])

        var infoMessages: [String] = []
        GitCloneBridgeRules.performCloneSuccessMessage("clone completed") {
            infoMessages.append($0)
        }
        #expect(infoMessages == ["clone completed"])
    }
}
