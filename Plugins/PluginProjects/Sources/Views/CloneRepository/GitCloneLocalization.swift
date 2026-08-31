import GitOKAppCore
import Foundation

public enum GitCloneLocalization {
    public static let table = "GitCloneLocalizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), table: table, bundle: bundle)
    }
}
