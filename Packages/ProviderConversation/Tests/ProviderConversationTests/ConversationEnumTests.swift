import Foundation
import Testing
@testable import ProviderConversation

@Suite("Conversation enums")
struct ConversationEnumTests {

    @Test("ResponseVerbosity raw values and init round-trip")
    func responseVerbosity() {
        #expect(ResponseVerbosity.brief.rawValue == "v1")
        #expect(ResponseVerbosity.standard.rawValue == "v2")
        #expect(ResponseVerbosity.detailed.rawValue == "v3")
        #expect(ResponseVerbosity(rawValue: "brief") == .brief)
        #expect(ResponseVerbosity(rawValue: "v1") == .brief)
        #expect(ResponseVerbosity(rawValue: "normal") == .standard)
        #expect(ResponseVerbosity(rawValue: "v3") == .detailed)
        #expect(ResponseVerbosity(rawValue: "unknown") == nil)
        #expect(ResponseVerbosity.defaultVerbosity == .standard)
    }

    @Test("AutomationLevel raw values and allowsTools")
    func automationLevel() {
        #expect(AutomationLevel.chat.rawValue == "a1")
        #expect(AutomationLevel.build.rawValue == "a2")
        #expect(AutomationLevel.autonomous.rawValue == "a3")
        #expect(AutomationLevel(rawValue: "chat") == .chat)
        #expect(AutomationLevel(rawValue: "a2") == .build)
        #expect(AutomationLevel(rawValue: "unknown") == nil)
        #expect(!AutomationLevel.chat.allowsTools)
        #expect(AutomationLevel.build.allowsTools)
        #expect(AutomationLevel.autonomous.allowsTools)
    }

    @Test("ReasoningEffort raw values and init")
    func reasoningEffort() {
        #expect(ReasoningEffort.low.rawValue == "low")
        #expect(ReasoningEffort.max.rawValue == "max")
        #expect(ReasoningEffort(rawValue: "high") == .high)
        #expect(ReasoningEffort(rawValue: "xhigh") == .xhigh)
        #expect(ReasoningEffort(rawValue: "nope") == nil)
        #expect(ReasoningEffort.defaultEffort == .high)
    }
}
