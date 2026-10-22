import Foundation
import Testing
@testable import ProviderConversation

/// 展示映射（displayName / iconName / description / levelCode）的覆盖。
@Suite("Conversation 枚举展示映射")
struct ConversationEnumDisplayMappingTests {

    // MARK: - ReasoningEffort

    @Test("ReasoningEffort 的档位编码覆盖全部 case")
    func reasoningEffortLevelCodes() {
        #expect(ReasoningEffort.low.levelCode == "LOW")
        #expect(ReasoningEffort.medium.levelCode == "MED")
        #expect(ReasoningEffort.high.levelCode == "HIGH")
        #expect(ReasoningEffort.xhigh.levelCode == "XHIGH")
        #expect(ReasoningEffort.max.levelCode == "MAX")
    }

    @Test("ReasoningEffort 的 id 与 rawValue 一致")
    func reasoningEffortIdentifiers() {
        for effort in ReasoningEffort.allCases {
            #expect(effort.id == effort.rawValue)
        }
    }

    @Test("ReasoningEffort 每个档位都有独立的名称、图标与说明")
    func reasoningEffortDisplayMapping() {
        var names: Set<String> = []
        var icons: Set<String> = []
        var descriptions: Set<String> = []
        for effort in ReasoningEffort.allCases {
            #expect(effort.displayName.isEmpty == false)
            #expect(effort.iconName.isEmpty == false)
            #expect(effort.description.isEmpty == false)
            names.insert(effort.displayName)
            icons.insert(effort.iconName)
            descriptions.insert(effort.description)
        }
        #expect(names.count == ReasoningEffort.allCases.count)
        #expect(icons.count == ReasoningEffort.allCases.count)
        #expect(descriptions.count == ReasoningEffort.allCases.count)
    }

    @Test("ReasoningEffort 的 rawValue 解析忽略大小写")
    func reasoningEffortRawValueIsCaseInsensitive() {
        #expect(ReasoningEffort(rawValue: "LOW") == .low)
        #expect(ReasoningEffort(rawValue: "Medium") == .medium)
        #expect(ReasoningEffort(rawValue: "HIGH") == .high)
        #expect(ReasoningEffort(rawValue: "XHigh") == .xhigh)
        #expect(ReasoningEffort(rawValue: "MAX") == .max)
    }

    // MARK: - AutomationLevel

    @Test("AutomationLevel 的档位编码覆盖全部 case")
    func automationLevelCodes() {
        #expect(AutomationLevel.chat.levelCode == "A1")
        #expect(AutomationLevel.build.levelCode == "A2")
        #expect(AutomationLevel.autonomous.levelCode == "A3")
    }

    @Test("AutomationLevel 的 id 与 rawValue 一致")
    func automationLevelIdentifiers() {
        for level in AutomationLevel.allCases {
            #expect(level.id == level.rawValue)
        }
    }

    @Test("AutomationLevel 每个等级都有独立的名称、图标与说明")
    func automationLevelDisplayMapping() {
        var names: Set<String> = []
        var icons: Set<String> = []
        var descriptions: Set<String> = []
        for level in AutomationLevel.allCases {
            #expect(level.displayName.isEmpty == false)
            #expect(level.iconName.isEmpty == false)
            #expect(level.description.isEmpty == false)
            names.insert(level.displayName)
            icons.insert(level.iconName)
            descriptions.insert(level.description)
        }
        #expect(names.count == AutomationLevel.allCases.count)
        #expect(icons.count == AutomationLevel.allCases.count)
        #expect(descriptions.count == AutomationLevel.allCases.count)
    }

    @Test("AutomationLevel 的 rawValue 解析支持别名且忽略大小写")
    func automationLevelRawValueAliases() {
        #expect(AutomationLevel(rawValue: "CHAT") == .chat)
        #expect(AutomationLevel(rawValue: "Build") == .build)
        #expect(AutomationLevel(rawValue: "a3") == .autonomous)
        #expect(AutomationLevel(rawValue: "autonomous") == .autonomous)
    }

    // MARK: - ResponseVerbosity

    @Test("ResponseVerbosity 的档位编码覆盖全部 case")
    func responseVerbosityCodes() {
        #expect(ResponseVerbosity.brief.levelCode == "V1")
        #expect(ResponseVerbosity.standard.levelCode == "V2")
        #expect(ResponseVerbosity.detailed.levelCode == "V3")
    }

    @Test("ResponseVerbosity 的 id 与 rawValue 一致")
    func responseVerbosityIdentifiers() {
        for verbosity in ResponseVerbosity.allCases {
            #expect(verbosity.id == verbosity.rawValue)
        }
    }

    @Test("ResponseVerbosity 每个级别都有独立的名称、图标与说明")
    func responseVerbosityDisplayMapping() {
        var names: Set<String> = []
        var icons: Set<String> = []
        var descriptions: Set<String> = []
        for verbosity in ResponseVerbosity.allCases {
            #expect(verbosity.displayName.isEmpty == false)
            #expect(verbosity.iconName.isEmpty == false)
            #expect(verbosity.description.isEmpty == false)
            names.insert(verbosity.displayName)
            icons.insert(verbosity.iconName)
            descriptions.insert(verbosity.description)
        }
        #expect(names.count == ResponseVerbosity.allCases.count)
        #expect(icons.count == ResponseVerbosity.allCases.count)
        #expect(descriptions.count == ResponseVerbosity.allCases.count)
    }

    @Test("ResponseVerbosity 的 rawValue 解析忽略大小写")
    func responseVerbosityRawValueIsCaseInsensitive() {
        #expect(ResponseVerbosity(rawValue: "V1") == .brief)
        #expect(ResponseVerbosity(rawValue: "Standard") == .standard)
        #expect(ResponseVerbosity(rawValue: "DETAILED") == .detailed)
    }

    // MARK: - ConversationLanguage

    @Test("ConversationLanguage 的 id 与 rawValue 一致")
    func conversationLanguageIdentifiers() {
        for language in ConversationLanguage.allCases {
            #expect(language.id == language.rawValue)
        }
    }

    @Test("ConversationLanguage 的短码、名称与图标")
    func conversationLanguageDisplayMapping() {
        #expect(ConversationLanguage.chinese.shortCode.isEmpty == false)
        #expect(ConversationLanguage.english.shortCode.isEmpty == false)
        #expect(ConversationLanguage.chinese.shortCode != ConversationLanguage.english.shortCode)

        for language in ConversationLanguage.allCases {
            #expect(language.displayName.isEmpty == false)
            #expect(language.iconName.isEmpty == false)
        }
        #expect(ConversationLanguage.chinese.iconName == ConversationLanguage.english.iconName)
    }

    @Test("ConversationLanguage 的 rawValue 解析支持别名且忽略大小写")
    func conversationLanguageRawValueAliases() {
        #expect(ConversationLanguage(rawValue: "ZH") == .chinese)
        #expect(ConversationLanguage(rawValue: "cn") == .chinese)
        #expect(ConversationLanguage(rawValue: "Chinese") == .chinese)
        #expect(ConversationLanguage(rawValue: "EN") == .english)
        #expect(ConversationLanguage(rawValue: "English") == .english)
        #expect(ConversationLanguage(rawValue: "jp") == nil)
    }
}
