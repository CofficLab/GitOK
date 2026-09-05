import ProviderWorkspaceScene

/// GitSubmodule 插件对工作场景的最小能力边界。
///
/// 插件入口把内核的场景 Provider 适配成此能力；Observer 只依赖该能力并把
/// 场景事件写入插件自己的状态模型，避免场景 Provider 穿透到视图层。
@MainActor
protocol GitSubmoduleSceneCapability: AnyObject {
    var currentScene: GitOKWorkspaceScene { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle
}
/// 将内核场景 Provider 收窄成 GitSubmodule 插件所需的能力。
@MainActor
final class GitSubmoduleSceneCapabilityAdapter: GitSubmoduleSceneCapability {
    private let provider: any WorkspaceSceneProviding

    init(scene: any WorkspaceSceneProviding) {
        self.provider = scene
    }

    var currentScene: GitOKWorkspaceScene {
        provider.currentScene
    }

    @discardableResult
    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle {
        provider.addObserver(callback)
    }
}
