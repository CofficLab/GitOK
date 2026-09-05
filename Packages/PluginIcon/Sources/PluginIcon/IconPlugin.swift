import Foundation
import KernelCore
import ProviderContentView
import ProviderProjects
import SwiftUI

/// Icon generation plugin. Its content contribution is visible only in the Icon scene.
@MainActor
public final class IconPlugin: SuperPlugin {
    public let id = "com.coffic.gitok.plugin.icon"
    public let order = 31
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.icon",
        name: "Icon",
        description: "Create project icons and export Xcode AppIcon sets",
        category: .project,
        stage: .stable,
        policy: .required
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self),
              let contentView = kernel.resolveProvider((any ContentViewProviding).self) else {
            return
        }

        contentView.addContentView(
            AnyView(IconWorkspaceView(projects: projects)),
            id: "\(id).content",
            order: 10,
            sceneScope: .icon
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}
