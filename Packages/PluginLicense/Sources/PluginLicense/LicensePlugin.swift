import Foundation
import GitOKPluginKit
import SwiftUI

public struct LicensePlugin: GitOKPackagedPlugin {
    public static let shared = LicensePlugin()

    public static let metadata = GitOKPluginMetadata(
        id: "LicensePlugin",
        displayName: PluginLicenseLocalization.string("License"),
        description: PluginLicenseLocalization.string("LICENSE entry in status bar"),
        iconName: "doc.on.doc",
        order: 9999,
        allowUserToggle: true,
        defaultEnabled: true,
        tableName: PluginLicenseLocalization.table
    )

    private init() {}

    @MainActor
    public func statusBarTrailingView() -> AnyView? {
        AnyView(LicenseStatusIcon())
    }
}

public enum PluginLicenseLocalization {
    public static let table = "License"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
