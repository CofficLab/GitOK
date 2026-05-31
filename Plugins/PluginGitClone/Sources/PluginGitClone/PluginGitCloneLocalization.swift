import Foundation

public enum PluginGitCloneLocalization {
    public static let table = "Git-Clone"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
