import Foundation
import KitGit
import ProviderGit
import Testing
@testable import ProviderCommitForm

// MARK: - 纯映射覆盖

/// `CommitCategory` 的 emoji / 标题 / 默认信息映射覆盖。
@Suite("CommitCategory 映射")
struct CommitCategoryMappingTests {

    @Test("每个类别都有独立的 emoji、标题与默认信息")
    func everyCategoryHasDistinctMappings() {
        var emojis: Set<String> = []
        var titles: Set<String> = []
        var messages: Set<String> = []
        for category in CommitCategory.allCases {
            #expect(category.emoji.isEmpty == false)
            #expect(category.title.isEmpty == false)
            #expect(category.defaultMessage.isEmpty == false)
            emojis.insert(category.emoji)
            titles.insert(category.title)
            messages.insert(category.defaultMessage)
        }
        #expect(emojis.count == CommitCategory.allCases.count)
        #expect(titles.count == CommitCategory.allCases.count)
        #expect(messages.count == CommitCategory.allCases.count)
    }

    @Test("label 由 emoji 与标题组成")
    func labelCombinesEmojiAndTitle() {
        for category in CommitCategory.allCases {
            #expect(category.label == "\(category.emoji) \(category.title)")
        }
    }

    @Test("text 带 emoji 前缀，text(includeEmoji:) 可省略 emoji")
    func textVariants() {
        let category = CommitCategory.Bugfix

        #expect(category.text == "\(category.emoji) \(category.title): ")
        #expect(category.text(includeEmoji: true) == "\(category.emoji) \(category.title): ")
        #expect(category.text(includeEmoji: false) == "\(category.title): ")
    }

    @Test("text(style:) 按风格决定前缀")
    func textPerStyle() {
        let category = CommitCategory.Feature

        #expect(category.text(style: .emoji) == "\(category.emoji) \(category.title): ")
        #expect(category.text(style: .plain) == "\(category.title): ")
        #expect(category.text(style: .lowercase) == "\(category.title.lowercased()): ")
    }

    @Test("auto 与 merge 预置文案由类别派生")
    func prebuiltMessages() {
        #expect(CommitCategory.auto == "\(CommitCategory.Chore.text) Auto Committed by GitOK")
        #expect(CommitCategory.merge == "\(CommitCategory.CI.text) Merged by GitOK")
    }
}

/// `CommitStyle` 的映射覆盖。
@Suite("CommitStyle 映射")
struct CommitStyleMappingTests {

    @Test("label 等于 rawValue")
    func labelEqualsRawValue() {
        for style in CommitStyle.allCases {
            #expect(style.label == style.rawValue)
        }
    }

    @Test("只有 emoji 风格包含 emoji")
    func onlyEmojiStyleIncludesEmoji() {
        #expect(CommitStyle.emoji.includeEmoji)
        #expect(!CommitStyle.plain.includeEmoji)
        #expect(!CommitStyle.lowercase.includeEmoji)
    }

    @Test("只有 lowercase 风格是小写格式")
    func onlyLowercaseStyleIsLowercase() {
        #expect(CommitStyle.lowercase.isLowercase)
        #expect(!CommitStyle.emoji.isLowercase)
        #expect(!CommitStyle.plain.isLowercase)
    }
}

/// `CommitStyleStore` 的全局默认风格读写。
///
/// 该 store 固定使用 `UserDefaults.standard` 的同一个 key，
/// 因此相关用例必须串行执行，避免并行用例互相覆盖。
@Suite("CommitStyleStore", .serialized)
struct CommitStyleStoreTests {

    private func withRestoredGlobalStyle(_ body: () -> Void) {
        let key = "GitOK_GlobalCommitStyle"
        let original = UserDefaults.standard.string(forKey: key)
        defer {
            if let original {
                UserDefaults.standard.set(original, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        body()
    }

    @Test("未设置过时回退 emoji 风格")
    func defaultsToEmoji() {
        withRestoredGlobalStyle {
            UserDefaults.standard.removeObject(forKey: "GitOK_GlobalCommitStyle")
            #expect(CommitStyleStore.current == .emoji)
        }
    }

    @Test("写入后能读回")
    func setAndReadRoundTrip() {
        withRestoredGlobalStyle {
            CommitStyleStore.set(.plain)
            #expect(CommitStyleStore.current == .plain)

            CommitStyleStore.set(.lowercase)
            #expect(CommitStyleStore.current == .lowercase)
        }
    }

    @Test("非法存储值回退到 emoji 风格")
    func invalidStoredValueFallsBackToEmoji() {
        withRestoredGlobalStyle {
            UserDefaults.standard.set("not-a-style", forKey: "GitOK_GlobalCommitStyle")
            #expect(CommitStyleStore.current == .emoji)
        }
    }
}

/// `CommitMessageRules` 的组装规则覆盖。
@Suite("CommitMessageRules")
struct CommitMessageRulesTests {

    @Test("defaultMessage 按风格决定首字母大小写")
    func defaultMessageRespectsStyle() {
        #expect(
            CommitMessageRules.defaultMessage(for: .Feature, style: .emoji)
                == CommitCategory.Feature.defaultMessage
        )
        #expect(
            CommitMessageRules.defaultMessage(for: .Feature, style: .plain)
                == CommitCategory.Feature.defaultMessage
        )
        #expect(
            CommitMessageRules.defaultMessage(for: .Feature, style: .lowercase)
                == "implement a new feature"
        )
    }

    @Test("类别变化与风格变化后的 subject 都来自默认信息")
    func subjectAfterChange() {
        #expect(
            CommitMessageRules.subjectAfterCategoryChange(category: .Bugfix, style: .emoji)
                == CommitCategory.Bugfix.defaultMessage
        )
        #expect(
            CommitMessageRules.subjectAfterStyleChange(category: .Bugfix, style: .lowercase)
                == "fix a bug"
        )
    }

    @Test("空 subject 会回退到兜底文案")
    func emptySubjectFallsBack() {
        let message = CommitMessageRules.formattedMessage(
            subject: "",
            category: .Chore,
            style: .emoji,
            coAuthors: []
        )

        #expect(message.hasSuffix(CommitMessageRules.fallbackSubject))
        #expect(message.hasPrefix("\(CommitCategory.Chore.text)"))
    }

    @Test("多个共同作者按行拼接")
    func multipleCoAuthorsAreJoined() {
        let message = CommitMessageRules.formattedMessage(
            subject: "Subject",
            category: .Chore,
            style: .emoji,
            coAuthors: [
                CoAuthor(name: "Jane", email: "jane@t.com"),
                CoAuthor(name: "Bob", email: "bob@t.com"),
            ]
        )

        #expect(message.contains("Co-authored-by: Jane <jane@t.com>"))
        #expect(message.contains("Co-authored-by: Bob <bob@t.com>"))
    }

    @Test("提交计划默认 add 全部，commitOnly 决定是否推送")
    func submitPlan() {
        let commitOnly = CommitMessageRules.submitPlan(message: "m", commitOnly: true)
        #expect(commitOnly.message == "m")
        #expect(commitOnly.addsAllFiles)
        #expect(!commitOnly.pushesAfterCommit)

        let commitAndPush = CommitMessageRules.submitPlan(message: "m", commitOnly: false)
        #expect(commitAndPush.pushesAfterCommit)
    }

    @Test("lowercasedFirst 只改首字符，空串原样返回")
    func lowercasedFirst() {
        #expect(CommitMessageRules.lowercasedFirst("Implement") == "implement")
        #expect(CommitMessageRules.lowercasedFirst("") == "")
    }
}
