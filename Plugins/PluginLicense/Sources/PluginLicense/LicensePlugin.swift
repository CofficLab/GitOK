import Foundation
import GitOKCoreKit
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
    public func statusBarTrailingView(context: GitOKPluginContext) -> AnyView? {
        guard let projectURL = context.projectURL else { return nil }
        return AnyView(LicenseStatusIcon(projectURL: projectURL))
    }
}

public enum PluginLicenseLocalization {
    public static let table = "License"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
    }
}
