import Foundation

public enum GitDetailLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }

    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: .current, arguments: arguments)
    }
}
