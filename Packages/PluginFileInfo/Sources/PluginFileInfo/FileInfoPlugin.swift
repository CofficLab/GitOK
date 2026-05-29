import Foundation
import GitOKPluginKit
import SwiftUI

public struct FileInfoPlugin: GitOKPackagedPlugin {
    public static let shared = FileInfoPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SmartFilePlugin",
        displayName: PluginFileInfoLocalization.string("FileInfo"),
        description: PluginFileInfoLocalization.string("Show selected file information in the status bar."),
        iconName: "doc.text",
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginFileInfoLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarLeadingView() -> AnyView? {
        AnyView(FileInfoTile())
    }
}

public enum PluginFileInfoLocalization {
    public static let table = "FileInfo"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
