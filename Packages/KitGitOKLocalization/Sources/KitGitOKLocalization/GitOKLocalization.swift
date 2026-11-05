import Foundation

/// GitOK 的运行时本地化解析器。
///
/// 与上游 `LumiLocalization` 的差异：
///
/// 1. **不设语言白名单**：catalog 中出现的任意语言都会被读取并参与回退，
///    而不是被硬编码的语言数组丢弃。解析候选语言时以「实际可用的语言」
///    （bundle 的 `.lproj` 目录 ∪ catalog 中出现过的语言）为准。
/// 2. **区域 / 书写系统回退**：同一语言的不同区域与书写系统变体
///    （`zh-Hant-TW` / `zh-Hant-HK` / `zh-MO` / `zh-SG` 等）按语义回退，
///    而不是只认几种固定写法。
/// 3. **支持应用内语言覆盖**：用户可在设置中显式选择界面语言，
///    覆盖值见 `GitOKLanguageOverride`。
///
/// 查找顺序（对每个候选语言）：
/// 1. bundle 的 `<lang>.lproj/<table>.strings`
/// 2. bundle 内的 `<table>.xcstrings` catalog
/// 3. 均未命中时返回原始 key，保证 UI 不会空白
public enum GitOKLocalization {
    /// 默认字符串表名。
    public static let defaultTable = "Localizable"

    /// 源语言（catalog 的 `sourceLanguage`）。所有解析链最终回落到它。
    public static let sourceLanguage = "en"

    /// 解析一个本地化字符串。
    ///
    /// - Parameters:
    ///   - key: catalog 中的 key。
    ///   - bundle: 资源所在的 bundle（插件一般传 `.module`）。
    ///   - table: 字符串表名。
    ///   - locale: 参与解析的 locale；默认取当前 locale。
    public static func string(
        _ key: String,
        bundle: Bundle,
        table: String = defaultTable,
        locale: Locale = .current
    ) -> String {
        let cacheKey = ResultCacheKey(
            bundlePath: bundle.bundlePath,
            table: table,
            key: key,
            localeID: locale.identifier,
            overrideToken: GitOKLanguageOverride.shared.generation
        )
        if let cached = resultCache.value(forKey: cacheKey) {
            return cached
        }

        let resolved = resolve(key, bundle: bundle, table: table, locale: locale)
        resultCache.setValue(resolved, forKey: cacheKey)
        return resolved
    }

    /// 与解析回退链一致的首选 locale。
    public static func preferredLocale(_ locale: Locale = .current) -> Locale {
        let chain = preferenceChain(locale: locale)
        return Locale(identifier: chain.first ?? sourceLanguage)
    }

    /// 当前生效的界面语言标识（已应用应用内覆盖）。
    ///
    /// 未设置覆盖时返回系统偏好解析出的首选语言。
    public static var effectiveLanguageCode: String {
        preferenceChain(locale: .current).first ?? sourceLanguage
    }

    // MARK: - Resolution

    private static func resolve(
        _ key: String,
        bundle: Bundle,
        table: String,
        locale: Locale
    ) -> String {
        let catalog = catalog(for: bundle, table: table)
        let available = availableLanguages(bundle: bundle, catalog: catalog)

        for preference in preferenceChain(locale: locale) {
            for language in languageMatches(for: preference, available: available) {
                if let value = localizedStringFromLproj(key, language: language, bundle: bundle, table: table) {
                    return value
                }
                if let value = catalog[language]?[key] {
                    return value
                }
            }
        }

        return key
    }

    /// 候选偏好链：应用内覆盖优先，其次系统偏好，最后源语言。
    ///
    /// 设置了应用内覆盖时，链条被收敛为「覆盖语言 + 源语言」——
    /// 用户显式选择了某种语言，未翻译的部分应回落到源语言，
    /// 而不是悄悄换成系统语言。
    private static func preferenceChain(locale: Locale) -> [String] {
        if let override = GitOKLanguageOverride.shared.languageCode {
            return deduplicated([override, sourceLanguage])
        }

        var chain: [String] = []
        chain.append(contentsOf: Locale.preferredLanguages)
        chain.append(locale.identifier)
        chain.append(sourceLanguage)
        return deduplicated(chain)
    }

    private static func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !value.isEmpty {
            let normalized = value.replacingOccurrences(of: "_", with: "-")
            guard seen.insert(normalized).inserted else { continue }
            result.append(normalized)
        }
        return result
    }

    /// bundle 实际可用的语言集合。
    ///
    /// 取 bundle 的 `.lproj` 目录与 catalog 中出现过的语言的并集——
    /// 打包后 `.xcstrings` 会被编译进 `.lproj`，开发态则只有 `.xcstrings`，
    /// 两者都要纳入候选。
    private static func availableLanguages(
        bundle: Bundle,
        catalog: [String: [String: String]]
    ) -> [String] {
        var result = Set(bundle.localizations)
        result.formUnion(catalog.keys)
        return result.sorted()
    }

    /// 把一条语言偏好映射到可用语言列表中的等价项。
    ///
    /// 依次尝试：精确匹配 → 逐级剥离子标签 → 书写系统同族回退。
    ///
    /// 例（可用语言含 `zh-Hant` / `zh-TW` / `zh-HK`）：
    /// - `zh-Hant-TW` → `zh-Hant`, `zh-TW`, `zh-HK`
    /// - `zh-MO` → `zh-Hant`, `zh-TW`, `zh-HK`
    /// - `zh-SG` → `zh-Hans`
    /// - `fr-FR` → `fr`（若可用），否则为空
    static func languageMatches(for preference: String, available: [String]) -> [String] {
        var result: [String] = []

        func append(_ language: String) {
            guard available.contains(language), !result.contains(language) else { return }
            result.append(language)
        }

        let normalized = preference.replacingOccurrences(of: "_", with: "-")
        append(normalized)

        // 逐级剥离子标签：`zh-Hant-TW` → `zh-Hant` → `zh`
        var components = normalized.split(separator: "-").map(String.init)
        while components.count > 1 {
            components.removeLast()
            append(components.joined(separator: "-"))
        }

        // 书写系统同族回退。
        for sibling in scriptSiblings(for: normalized) {
            append(sibling)
        }

        return result
    }

    /// 同一书写系统内的等价语言。
    ///
    /// 繁体（`zh-Hant`）与简体（`zh-Hans`）是两个书写系统，不互为同族；
    /// `zh-TW` / `zh-HK` / `zh-MO` 同属繁体。
    static func scriptSiblings(for languageID: String) -> [String] {
        let id = languageID.replacingOccurrences(of: "_", with: "-")

        if id.hasPrefix("zh-Hant") {
            return ["zh-Hant", "zh-TW", "zh-HK", "zh-MO"]
        }
        if id.hasPrefix("zh-Hans") || id.hasPrefix("zh-CN") || id.hasPrefix("zh-SG") {
            return ["zh-Hans", "zh-CN", "zh-SG"]
        }
        if id.hasPrefix("zh-TW") {
            return ["zh-TW", "zh-Hant", "zh-HK"]
        }
        if id.hasPrefix("zh-HK") || id.hasPrefix("zh-MO") {
            return ["zh-HK", "zh-Hant", "zh-TW"]
        }
        if id == "zh" {
            return ["zh-Hans", "zh-Hant"]
        }
        return []
    }

    private static func localizedStringFromLproj(
        _ key: String,
        language: String,
        bundle: Bundle,
        table: String
    ) -> String? {
        guard let lprojPath = bundle.path(forResource: language, ofType: "lproj"),
              let languageBundle = Bundle(path: lprojPath) else {
            return nil
        }

        let value = languageBundle.localizedString(forKey: key, value: missingMarker, table: table)
        guard value != missingMarker else { return nil }
        return value
    }

    // MARK: - Catalog

    private static func catalog(for bundle: Bundle, table: String) -> [String: [String: String]] {
        let cacheKey = CatalogCacheKey(bundlePath: bundle.bundlePath, table: table)

        let cache = CatalogCache.shared
        if let cached = cache.value(forKey: cacheKey) {
            return cached
        }

        let loaded = loadCatalog(bundle: bundle, table: table)
        cache.setValue(loaded, forKey: cacheKey)
        return loaded
    }

    /// 读取并解析 catalog。
    ///
    /// 语言集合由 catalog 内容决定——**不设白名单**，
    /// 任何在 `localizations` 中出现过的语言都会被索引。
    private static func loadCatalog(bundle: Bundle, table: String) -> [String: [String: String]] {
        let catalogURLs = [
            bundle.url(forResource: table, withExtension: "xcstrings"),
            bundle.url(forResource: table, withExtension: "xcstrings", subdirectory: "Resources"),
        ].compactMap { $0 }

        guard let catalogURL = catalogURLs.first,
              let data = try? Data(contentsOf: catalogURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: Any] else {
            return [:]
        }

        var tables: [String: [String: String]] = [:]

        for (key, value) in strings {
            guard let entry = value as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else {
                continue
            }

            for (language, localization) in localizations {
                guard let localization = localization as? [String: Any],
                      let unit = localization["stringUnit"] as? [String: Any],
                      let text = unit["value"] as? String else {
                    continue
                }
                tables[language, default: [:]][key] = text
            }
        }

        return tables
    }

    // MARK: - Cache

    private static let missingMarker = "\u{FFFF}"
    private static let resultCache = LocalizationResultCache.shared
}

// MARK: - Cache Storage

private struct CatalogCacheKey: Hashable {
    let bundlePath: String
    let table: String
}

private struct ResultCacheKey: Hashable {
    let bundlePath: String
    let table: String
    let key: String
    let localeID: String
    /// 应用内语言覆盖的版本号。覆盖变化后旧缓存自动失效。
    let overrideToken: UInt64
}

/// 单条字符串解析结果的记忆化缓存（有界 FIFO）。
private final class LocalizationResultCache: @unchecked Sendable {
    static let shared = LocalizationResultCache()

    private let limit = 8192
    private let lock = NSLock()
    private var storage: [ResultCacheKey: String] = [:]
    private var insertionOrder: [ResultCacheKey] = []

    func value(forKey key: ResultCacheKey) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func setValue(_ value: String, forKey key: ResultCacheKey) {
        lock.lock()
        defer { lock.unlock() }
        guard storage[key] == nil else { return }
        storage[key] = value
        insertionOrder.append(key)
        if insertionOrder.count > limit {
            let overflow = insertionOrder.count - limit
            for evicted in insertionOrder.prefix(overflow) {
                storage.removeValue(forKey: evicted)
            }
            insertionOrder.removeFirst(overflow)
        }
    }
}

private final class CatalogCache: @unchecked Sendable {
    static let shared = CatalogCache()

    private let lock = NSLock()
    private var storage: [CatalogCacheKey: [String: [String: String]]] = [:]

    func value(forKey key: CatalogCacheKey) -> [String: [String: String]]? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func setValue(_ value: [String: [String: String]], forKey key: CatalogCacheKey) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}

