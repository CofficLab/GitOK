import Foundation

public enum GitDetailLocalization {
    public static let table = "GitDetail"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, value: key, comment: "")
    }
}
