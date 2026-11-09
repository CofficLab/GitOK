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

/// `GlobalCommitStyleStore` 的全局默认风格读写。
///
/// 该 store 固定落盘到注入的插件数据目录，相关用例必须串行执行，
/// 避免并行用例互相覆盖磁盘状态。
@Suite("GlobalCommitStyleStore", .serialized)
struct GlobalCommitStyleStoreTests {

    private func makeStore() -> (GlobalCommitStyleStore, URL, UserDefaults) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalCommitStyleStoreTests-\(UUID().uuidString)", isDirectory: true)
        let defaults = UserDefaults(suiteName: "GlobalCommitStyleStoreTests-\(UUID().uuidString)")!
        let store = GlobalCommitStyleStore(legacyDefaults: defaults)
        store.configure(directory: directory)
        return (store, directory, defaults)
    }

    @Test("未设置过时回退 emoji 风格")
    func defaultsToEmoji() {
        let (store, directory, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(store.current == .emoji)
    }

    @Test("写入后能读回")
    func setAndReadRoundTrip() {
        let (store, directory, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        store.set(.plain)
        #expect(store.current == .plain)

        store.set(.lowercase)
        #expect(store.current == .lowercase)
    }

    @Test("风格落盘到插件数据目录下的 settings.plist")
    func persistsToSettingsPlist() {
        let (store, directory, _) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        store.set(.lowercase)

        let fileURL = directory.appendingPathComponent("settings.plist")
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        let data = try? Data(contentsOf: fileURL)
        let plist = data.flatMap {
            try? PropertyListSerialization.propertyList(from: $0, options: [], format: nil)
        }
        let dict = plist as? [String: Any]
        #expect(dict?[GlobalCommitStyleStore.styleKey] as? String == CommitStyle.lowercase.rawValue)
    }

    @Test("重建 store 后仍能读到磁盘上的风格")
    func valueSurvivesReconfiguration() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalCommitStyleStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = UserDefaults(suiteName: "GlobalCommitStyleStoreTests-\(UUID().uuidString)")!

        let first = GlobalCommitStyleStore(legacyDefaults: defaults)
        first.configure(directory: directory)
        first.set(.plain)

        let second = GlobalCommitStyleStore(legacyDefaults: defaults)
        second.configure(directory: directory)

        #expect(second.current == .plain)
    }

    @Test("非法存储值回退到 emoji 风格")
    func invalidStoredValueFallsBackToEmoji() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalCommitStyleStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = UserDefaults(suiteName: "GlobalCommitStyleStoreTests-\(UUID().uuidString)")!

        // 手工写入一个无法识别的值，模拟存档损坏 / 版本演进。
        let fileURL = directory.appendingPathComponent("settings.plist")
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try? PropertyListSerialization.data(
            fromPropertyList: [GlobalCommitStyleStore.styleKey: "not-a-style"],
            format: .binary,
            options: 0
        )
        try? data?.write(to: fileURL, options: .atomic)

        let store = GlobalCommitStyleStore(legacyDefaults: defaults)
        store.configure(directory: directory)

        #expect(store.current == .emoji)
    }

    // MARK: - Legacy Import

    @Test("旧 UserDefaults 值被一次性导入")
    func importsLegacyUserDefaultsValue() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalCommitStyleStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = UserDefaults(suiteName: "GlobalCommitStyleStoreTests-\(UUID().uuidString)")!
        defaults.set(CommitStyle.plain.rawValue, forKey: GlobalCommitStyleStore.legacyDefaultsKey)

        let store = GlobalCommitStyleStore(legacyDefaults: defaults)
        store.configure(directory: directory)

        #expect(store.current == .plain)
    }

    @Test("导入后移除旧 UserDefaults key")
    func legacyImportRemovesOldDefaultsKey() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalCommitStyleStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = UserDefaults(suiteName: "GlobalCommitStyleStoreTests-\(UUID().uuidString)")!
        defaults.set(CommitStyle.plain.rawValue, forKey: GlobalCommitStyleStore.legacyDefaultsKey)

        let store = GlobalCommitStyleStore(legacyDefaults: defaults)
        store.configure(directory: directory)

        #expect(defaults.object(forKey: GlobalCommitStyleStore.legacyDefaultsKey) == nil)
    }

    @Test("磁盘已有记录时不被旧值覆盖")
    func legacyImportDoesNotOverwriteExistingDiskValue() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalCommitStyleStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = UserDefaults(suiteName: "GlobalCommitStyleStoreTests-\(UUID().uuidString)")!

        let first = GlobalCommitStyleStore(legacyDefaults: defaults)
        first.configure(directory: directory)
        first.set(.lowercase)

        defaults.set(CommitStyle.plain.rawValue, forKey: GlobalCommitStyleStore.legacyDefaultsKey)
        let second = GlobalCommitStyleStore(legacyDefaults: defaults)
        second.configure(directory: directory)

        #expect(second.current == .lowercase)
    }

    @Test("非法的旧值被丢弃")
    func legacyImportDiscardsInvalidValue() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GlobalCommitStyleStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let defaults = UserDefaults(suiteName: "GlobalCommitStyleStoreTests-\(UUID().uuidString)")!
        defaults.set("not-a-style", forKey: GlobalCommitStyleStore.legacyDefaultsKey)

        let store = GlobalCommitStyleStore(legacyDefaults: defaults)
        store.configure(directory: directory)

        #expect(store.current == .emoji)
        #expect(defaults.object(forKey: GlobalCommitStyleStore.legacyDefaultsKey) == nil)
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
