import Foundation
import GitOKAppCore
import GitOKCoreKit
import SwiftUI

public enum ProjectsPlugin: GitOKPlugin {

    public static let metadata = GitOKPluginMetadata(
        id: "ProjectsPlugin",
        displayName: ProjectsPluginLocalization.string("ProjectsPlugin"),
        description: ProjectsPluginLocalization.string("Project sidebar and repository sheets"),
        iconName: "folder",
        order: 1,
        policy: .alwaysOn,
        tableName: ProjectsPluginLocalization.table
    )

    @MainActor
    public static func sidebarPaneItems(context: GitOKPluginContext) -> [GitOKPluginViewContribution] {
        [GitOKPluginViewContribution(id: metadata.id, view: AnyView(ProjectsSidebarView()))]
    }
}

public enum ProjectsPluginLocalization {
    public static let table = "Localizable"
    public static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module, comment: "")
    }
}

/// Sidebar project list (formerly `Projects`).
public struct ProjectsSidebarView: View {
    public init() {}

    public var body: some View {
        Projects()
    }
}
