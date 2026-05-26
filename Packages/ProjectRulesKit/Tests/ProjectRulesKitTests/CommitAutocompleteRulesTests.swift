import ProjectRulesKit
import Testing

@Suite("CommitAutocompleteRulesTests")
struct CommitAutocompleteRulesTests {
    @Test("Issue references are extracted from common branch names")
    func issueReferencesAreExtractedFromCommonBranchNames() {
        let references = CommitAutocompleteRules.issueReferences(from: [
            "feature/123-add-login",
            "bugfix/issue-45-crash",
            "refs/remotes/origin/fix/GH-8",
            "release/no-ticket",
            "feature/#123-duplicate",
        ])

        #expect(references == ["#8", "#45", "#123"])
    }

    @Test("User mention candidates use names and email local parts")
    func userMentionCandidatesUseNamesAndEmailLocalParts() {
        let mentions = CommitAutocompleteRules.userMentionCandidates(namesAndEmails: [
            (name: "Ada Lovelace", email: "ada@example.com"),
            (name: "Grace_Hopper", email: "grace.hopper@example.com"),
        ])

        #expect(mentions.contains("@ada"))
        #expect(mentions.contains("@ada-lovelace"))
        #expect(mentions.contains("@grace-hopper"))
        #expect(mentions.contains("@grace_hopper"))
    }

    @Test("Completions match active issue user and emoji tokens")
    func completionsMatchActiveTokens() {
        let issues = ["#8", "#45", "#123"]
        let users = ["@ada", "@grace-hopper"]

        #expect(CommitAutocompleteRules.completions(for: "Fix #4", issueReferences: issues, userMentions: users).map(\.insertion) == ["#45"])
        #expect(CommitAutocompleteRules.completions(for: "Pair with @gra", issueReferences: issues, userMentions: users).map(\.insertion) == ["@grace-hopper"])
        #expect(CommitAutocompleteRules.completions(for: "Ship :spa", issueReferences: issues, userMentions: users).map(\.insertion) == [":sparkles:"])
        #expect(CommitAutocompleteRules.completions(for: "No active token", issueReferences: issues, userMentions: users).isEmpty)
    }

    @Test("Applying completion replaces the active token and appends a space")
    func applyingCompletionReplacesActiveToken() {
        let completion = CommitAutocompleteRules.Completion(
            kind: .issue,
            title: "#123",
            detail: "Issue 引用",
            insertion: "#123"
        )

        #expect(CommitAutocompleteRules.text("Fix #1", applying: completion) == "Fix #123 ")
    }
}
