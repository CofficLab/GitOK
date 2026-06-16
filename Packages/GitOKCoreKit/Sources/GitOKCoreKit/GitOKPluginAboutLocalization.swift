import Foundation

public enum GitOKPluginAboutLocalization {
    static let table = "Localizable"
    static let bundle = Bundle.module

    public static func string(_ key: String, locale: Locale = .current) -> String {
        String(localized: String.LocalizationValue(key), bundle: bundle, locale: locale, comment: "")
    }

    public static func format(_ key: String, locale: Locale = .current, _ arguments: CVarArg...) -> String {
        let template = string(key, locale: locale)
        return String(format: template, locale: locale, arguments: arguments)
    }
}
