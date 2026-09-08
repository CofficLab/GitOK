import Foundation

/// 本地化 helper：按当前系统语言从本插件 catalog 取文案（默认英语）。
enum CoAuthorSettingsLocalization {
    static func string(_ key: String, bundle: Bundle) -> String {
        guard let path = bundle.path(forResource: "Localizable", ofType: "xcstrings"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: Any],
              let entry = strings[key] as? [String: Any],
              let localizations = entry["localizations"] as? [String: Any] else {
            return key
        }

        // Prefer zh-Hans, then zh, then en
        if let zhHans = localizations["zh-Hans"] as? [String: Any],
           let value = zhHans["stringUnit"] as? [String: Any],
           let text = value["value"] as? String, !text.isEmpty {
            return text
        }
        if let zh = localizations["zh"] as? [String: Any],
           let value = zh["stringUnit"] as? [String: Any],
           let text = value["value"] as? String, !text.isEmpty {
            return text
        }
        if let en = localizations["en"] as? [String: Any],
           let value = en["stringUnit"] as? [String: Any],
           let text = value["value"] as? String, !text.isEmpty {
            return text
        }
        return key
    }
}
