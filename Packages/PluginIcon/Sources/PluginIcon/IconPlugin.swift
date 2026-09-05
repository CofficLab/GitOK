import Foundation
import KernelCore
import ProviderContentView
import ProviderProjects
import ProviderWorkspaceScene
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

    private var sceneViewModel: WorkspaceSceneVisibilityViewModel?
    private var sceneObserver: IconSceneObserver?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let projects = kernel.resolveProvider((any ProjectProviding).self),
              let contentView = kernel.resolveProvider((any ContentViewProviding).self) else {
            return
        }

        guard let scene = kernel.resolveProvider((any WorkspaceSceneProviding).self) else {
            return
        }

        let sceneViewModel = WorkspaceSceneVisibilityViewModel(targetScene: .icon)
        self.sceneViewModel = sceneViewModel
        self.sceneObserver = IconSceneObserver(scene: scene, viewModel: sceneViewModel)

        contentView.addContentView(
            AnyView(
                WorkspaceSceneVisibilityView(viewModel: sceneViewModel) {
                    IconWorkspaceView(projects: projects)
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
