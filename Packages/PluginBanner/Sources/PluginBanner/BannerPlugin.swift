import Foundation
import KernelCore
import ProviderContentView
import ProviderProjects
import ProviderWorkspaceScene
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

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: BannerSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self),
              let contentView = kernel.resolveProvider((any ContentViewProviding).self) else {
            return
        }

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            return
        }

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .banner)
        self.sceneViewModel = sceneViewModel
        self.sceneObserver = BannerSceneObserver(scene: scene, viewModel: sceneViewModel)

        contentView.addContentView(
            AnyView(
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    BannerWorkspaceView(projects: projects)
                }
                    // Debug 构建下左下角叠加插件名 badge，便于识别内容区来源。
                    .debugPluginBadge(metadata.name)
            ),
            id: "\(id).content",
            order: 10
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        sceneObserver?.cancel()
        sceneObserver = nil
        sceneViewModel = nil
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}
