import Foundation
import KernelCore
import ProviderContentView
import ProviderProjects
import SwiftUI

/// Banner generation plugin. Its content contribution is visible only in the Banner scene.
@MainActor
public final class BannerPlugin: SuperPlugin {
    public let id = "com.coffic.gitok.plugin.banner"
    public let order = 30
    public let dependencies = ["com.coffic.lumi.plugin.projects"]
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.banner",
        name: "Banner",
        description: "Create and edit project banners",
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
            AnyView(BannerWorkspaceView(projects: projects)),
            id: "\(id).content",
            order: 10,
            sceneScope: .banner
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}
