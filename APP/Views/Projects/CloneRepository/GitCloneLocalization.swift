import Foundation

enum GitCloneLocalization {
    static let table = "GitCloneLocalizable"
    static let bundle = Bundle.main

    static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
