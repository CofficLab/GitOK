import Foundation

public enum CommitLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, value: key, comment: "")
    }
}
