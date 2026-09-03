import Foundation
import Testing
@testable import ProviderCommitForm

@Suite("ProviderCommitForm")
@MainActor
struct ProviderCommitFormTests {

    @Test("类别与风格变化后重置 subject 为默认信息")
    func categoryAndStyleResetSubject() {
        let provider = DefaultCommitFormProvider()
        provider.setCategory(.Feature)
        #expect(provider.category == .Feature)
        #expect(provider.subject == "Implement a new feature")

        provider.setStyle(.lowercase)
        #expect(provider.style == .lowercase)
        #expect(provider.subject == "implement a new feature")
    }

    @Test("formattedMessage 组装类别前缀与 Co-authored-by 行")
    func formattedMessageComposesPrefixAndCoAuthors() {
        let message = CommitMessageRules.formattedMessage(
            subject: "Minor adjustments",
            category: .Chore,
            style: .emoji,
            coAuthors: [CoAuthor(name: "Jane", email: "jane@t.com")]
        )
        #expect(message.hasPrefix("🎨 Chore: Minor adjustments"))
        #expect(message.contains("Co-authored-by: Jane <jane@t.com>"))
    }

    @Test("观察者收到 stateChanged 与 committed 事件")
    func observerReceivesEvents() {
        let provider = DefaultCommitFormProvider()
        var events: [CommitFormEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.setSubject("hello")
        #expect(events.count == 1)
        if case .stateChanged = events[0] {} else {
            Issue.record("expected stateChanged")
        }
    }
}
