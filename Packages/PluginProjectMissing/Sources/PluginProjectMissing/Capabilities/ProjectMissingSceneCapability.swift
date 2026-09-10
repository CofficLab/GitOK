import Foundation
import ProviderWorkspaceScene

/// 场景能力适配器：把 `WorkspaceSceneProviding` 转成本插件需要的最小接口。
@MainActor
protocol ProjectMissingSceneCapability {
    var currentScene: GitOKWorkspaceScene { get }
    func addObserver(_ callback: @escaping (WorkspaceSceneEvent) -> Void) -> any WorkspaceSceneObserverHandle
}

/// `WorkspaceSceneProviding` → `ProjectMissingSceneCapability` 适配器。
@MainActor
final class ProjectMissingSceneCapabilityAdapter: ProjectMissingSceneCapability {
    private let scene: any WorkspaceSceneProviding

    init(scene: any WorkspaceSceneProviding) {
        self.scene = scene
    }

    var currentScene: GitOKWorkspaceScene {
        scene.currentScene
    }

    func addObserver(_ callback: @escaping (WorkspaceSceneEvent) -> Void) -> any WorkspaceSceneObserverHandle {
        scene.addObserver(callback)
    }
}
