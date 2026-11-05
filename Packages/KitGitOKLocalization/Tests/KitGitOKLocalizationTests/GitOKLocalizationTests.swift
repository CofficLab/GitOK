import Foundation
import Testing
@testable import KitGitOKLocalization

@Suite("GitOKLocalization 语言无关解析")
struct GitOKLocalizationTests {
    // MARK: - 语言匹配

    @Test("非中文语言做区域回退，不被丢弃")
    func nonChineseRegionFallback() {
        let available = ["en", "fr", "pt-BR", "ja"]
        #expect(GitOKLocalization.languageMatches(for: "fr-FR", available: available) == ["fr"])
        #expect(GitOKLocalization.languageMatches(for: "pt-BR", available: available) == ["pt-BR"])
        #expect(GitOKLocalization.languageMatches(for: "ja-JP", available: available) == ["ja"])
    }

    @Test("未收录的语言返回空匹配，交由上层回退到源语言")
    func unknownLanguageHasNoMatch() {
        let available = ["en", "zh-Hans"]
        #expect(GitOKLocalization.languageMatches(for: "ko-KR", available: available).isEmpty)
    }

    @Test("繁体变体按书写系统同族回退")
    func traditionalVariantsFallback() {
        let available = ["en", "zh-Hant", "zh-TW", "zh-HK"]
        let matches = GitOKLocalization.languageMatches(for: "zh-Hant-TW", available: available)
        #expect(matches.first == "zh-Hant")
        #expect(matches.contains("zh-TW"))
        #expect(matches.contains("zh-HK"))

        #expect(GitOKLocalization.languageMatches(for: "zh-MO", available: available).contains("zh-Hant"))
        #expect(GitOKLocalization.languageMatches(for: "zh-HK", available: available).first == "zh-HK")
    }

    @Test("简体变体回退到 zh-Hans，不混入繁体")
    func simplifiedVariantsFallback() {
        let available = ["en", "zh-Hans", "zh-Hant"]
        let matches = GitOKLocalization.languageMatches(for: "zh-SG", available: available)
        #expect(matches.contains("zh-Hans"))
        #expect(!matches.contains("zh-Hant"))

        #expect(GitOKLocalization.languageMatches(for: "zh-CN", available: available).first == "zh-Hans")
    }

    @Test("繁体与简体互不为同族回退")
    func traditionalAndSimplifiedAreSeparate() {
        #expect(GitOKLocalization.scriptSiblings(for: "zh-Hant").contains("zh-Hant"))
        #expect(!GitOKLocalization.scriptSiblings(for: "zh-Hant").contains("zh-Hans"))
        #expect(GitOKLocalization.scriptSiblings(for: "zh-Hans").contains("zh-Hans"))
        #expect(!GitOKLocalization.scriptSiblings(for: "zh-Hans").contains("zh-Hant"))
    }

    @Test("精确匹配优先于同族回退")
    func exactMatchWins() {
        let available = ["en", "zh-Hant", "zh-TW"]
        let matches = GitOKLocalization.languageMatches(for: "zh-TW", available: available)
        #expect(matches.first == "zh-TW")
    }
}

@Suite("GitOKLanguageOverride 应用内语言覆盖")
struct GitOKLanguageOverrideTests {
    @Test("默认跟随系统语言，无覆盖")
    func defaultsToSystemLanguage() {
        let suite = "GitOKLanguageOverrideTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let override = GitOKLanguageOverride(defaults: defaults)
        #expect(override.languageCode == nil)
        #expect(!override.isOverridden)
    }

    @Test("设置覆盖后可读回，并持久化")
    func overrideRoundTrips() {
        let suite = "GitOKLanguageOverrideTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let override = GitOKLanguageOverride(defaults: defaults)
        override.setLanguageCode("zh-Hant")
        #expect(override.languageCode == "zh-Hant")
        #expect(override.isOverridden)
        #expect(defaults.string(forKey: GitOKLanguageOverride.storageKey) == "zh-Hant")

        // 新实例应从持久化存储中恢复。
        let restored = GitOKLanguageOverride(defaults: defaults)
        #expect(restored.languageCode == "zh-Hant")
    }

    @Test("传 nil 清除覆盖")
    func clearingOverride() {
        let suite = "GitOKLanguageOverrideTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let override = GitOKLanguageOverride(defaults: defaults)
        override.setLanguageCode("ja")
        override.setLanguageCode(nil)
        #expect(override.languageCode == nil)
        #expect(defaults.string(forKey: GitOKLanguageOverride.storageKey) == nil)
    }

    @Test("语言变更时版本号递增，用于作废字符串缓存")
    func generationIncrementsOnChange() {
        let suite = "GitOKLanguageOverrideTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let override = GitOKLanguageOverride(defaults: defaults)
        let before = override.generation
        override.setLanguageCode("ja")
        #expect(override.generation > before)

        // 相同值重复设置不递增。
        let after = override.generation
        override.setLanguageCode("ja")
        #expect(override.generation == after)
    }

    @Test("语言变更时发出通知")
    func postsNotificationOnChange() async throws {
        let suite = "GitOKLanguageOverrideTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let override = GitOKLanguageOverride(defaults: defaults)

        await confirmation("语言变更时发出通知", expectedCount: 1) { confirmed in
            // 只接收本实例发出的通知：并行测试中其他实例的变更不应干扰本用例。
            let token = NotificationCenter.default.addObserver(
                forName: GitOKLanguageOverride.didChangeNotification,
                object: override,
                queue: nil
            ) { _ in
                confirmed()
            }
            defer { NotificationCenter.default.removeObserver(token) }

            override.setLanguageCode("zh-Hant")
        }
    }
}
