import Foundation
import GitOKCoreKit
import SwiftUI

public enum FileInfoPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "SmartFilePlugin",
        displayName: FileInfoPluginLocalization.string("FileInfo"),
        description: FileInfoPluginLocalization.string("Show selected file information in the status bar."),
        iconName: "doc.text",
        policy: .optIn,
        tableName: FileInfoPluginLocalization.table
    )

    public static var introductionContentKind: GitOKPluginAboutContentKind { .statusBar }


    @MainActor
    public static func statusBarLeadingItems(context: GitOKPluginContext) -> [GitOKStatusBarItem] {
        guard let selectedFilePath = context.selectedFilePath, !selectedFilePath.isEmpty else { return [] }
        return [GitOKStatusBarItem(id: metadata.id, view: AnyView(FileInfoTile(selectedFilePath: selectedFilePath, projectPath: context.projectPath)))]
    }
}

public enum FileInfoPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
