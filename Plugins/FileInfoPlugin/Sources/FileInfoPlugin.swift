import Foundation
import GitOKCoreKit
import SwiftUI

public struct FileInfoPlugin: GitOKPlugin {
    public static let shared = FileInfoPlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "SmartFilePlugin",
        displayName: FileInfoPluginLocalization.string("FileInfo"),
        description: FileInfoPluginLocalization.string("Show selected file information in the status bar."),
        iconName: "doc.text",
        policy: .optIn,
        tableName: FileInfoPluginLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarLeadingView(context: GitOKPluginContext) -> AnyView? {
        guard let selectedFilePath = context.selectedFilePath, !selectedFilePath.isEmpty else { return nil }
        return AnyView(FileInfoTile(selectedFilePath: selectedFilePath, projectPath: context.projectPath))
    }
}

public enum FileInfoPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
