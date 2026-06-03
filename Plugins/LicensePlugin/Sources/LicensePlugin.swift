import Foundation
import GitOKCoreKit
import SwiftUI

public struct LicensePlugin: GitOKPlugin {
    public static let shared = LicensePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "LicensePlugin",
        displayName: LicensePluginLocalization.string("License"),
        description: LicensePluginLocalization.string("LICENSE entry in status bar"),
        iconName: "doc.on.doc",
        order: 9999,
        policy: .optIn,
        tableName: LicensePluginLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(LicenseStatusIcon(projectURL: projectURL))
    }
}

public enum LicensePluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}
