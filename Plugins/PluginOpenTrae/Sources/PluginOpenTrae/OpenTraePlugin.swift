import Foundation
import GitOKPluginKit
import SwiftUI

public struct OpenTraePlugin: GitOKPackagedPlugin {
    public static let shared = OpenTraePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "OpenTrae",
        displayName: PluginOpenTraeLocalization.string("Open Trae"),
        description: PluginOpenTraeLocalization.string("Open the current project folder in Trae."),
        iconName: "brain",
        order: 8404,
        allowUserToggle: true,
        defaultEnabled: false,
        tableName: PluginOpenTraeLocalization.table
    )

    private init() {}

    public func toolBarTrailingView() -> AnyView? {
        AnyView(OpenTraeButton())
    }
}

public enum PluginOpenTraeLocalization {
    public static let table = "OpenTrae"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
