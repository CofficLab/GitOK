import Foundation

// MARK: - Workspace Scene

/// GitOK 主窗口的工作场景。
///
/// 场景只描述工作区上下文，不承载 Banner 或 Icon 的领域数据。
/// 具体数据仍由对应插件 / Provider 持有。
public enum GitOKWorkspaceScene: String, CaseIterable, Codable, Identifiable, Sendable {
    case git
    case banner
    case icon

    public var id: String { rawValue }
}

// MARK: - Events

/// 工作场景变化事件。
public enum WorkspaceSceneEvent: Equatable, Sendable {
    case sceneChanged(from: GitOKWorkspaceScene, to: GitOKWorkspaceScene)
}

// MARK: - Observer Handle

/// 工作场景观察者令牌。
@MainActor
public protocol WorkspaceSceneObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// 工作场景 Provider。
///
/// Provider 只管理当前场景和场景变化通知。后续各类 UI contribution 会以
/// 场景范围注册到对应 Provider，由公共渲染层负责过滤非当前场景的内容。
@MainActor
public protocol WorkspaceSceneProviding: AnyObject {
    /// 当前场景。
    var currentScene: GitOKWorkspaceScene { get }

    /// 当前宿主支持的场景，顺序也是 UI 选择器的默认顺序。
    var availableScenes: [GitOKWorkspaceScene] { get }

    /// 切换当前场景；切换到相同场景时不重复广播。
    func selectScene(_ scene: GitOKWorkspaceScene)

    /// 监听场景变化。
    @discardableResult
    func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle
}

// MARK: - Default Implementation

/// 工作场景 Provider 的默认实现。
@MainActor
public final class DefaultWorkspaceSceneProvider: WorkspaceSceneProviding {
    public private(set) var currentScene: GitOKWorkspaceScene
    public let availableScenes: [GitOKWorkspaceScene]

    private var observers: [WeakWorkspaceSceneObserver] = []

    public init(
        initialScene: GitOKWorkspaceScene = .git,
        availableScenes: [GitOKWorkspaceScene] = GitOKWorkspaceScene.allCases
    ) {
        let uniqueScenes = Self.uniqueScenes(availableScenes)
        self.availableScenes = uniqueScenes.isEmpty ? GitOKWorkspaceScene.allCases : uniqueScenes
        self.currentScene = self.availableScenes.contains(initialScene)
            ? initialScene
            : self.availableScenes[0]
    }

    public func selectScene(_ scene: GitOKWorkspaceScene) {
        guard availableScenes.contains(scene), currentScene != scene else { return }
        let previousScene = currentScene
        currentScene = scene
        notifyObservers(.sceneChanged(from: previousScene, to: scene))
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (WorkspaceSceneEvent) -> Void
    ) -> any WorkspaceSceneObserverHandle {
        let handle = WorkspaceSceneObserverHandleImpl(owner: self, callback: callback)
        observers.append(WeakWorkspaceSceneObserver(handle))
        return handle
    }

    fileprivate func removeObserver(_ handle: any WorkspaceSceneObserverHandle) {
        observers.removeAll { $0.handle === handle }
    }

    private func notifyObservers(_ event: WorkspaceSceneEvent) {
        observers.removeAll { $0.handle == nil }
        for observer in observers {
            observer.handle?.invoke(event)
        }
    }

    private static func uniqueScenes(
        _ scenes: [GitOKWorkspaceScene]
    ) -> [GitOKWorkspaceScene] {
        var result: [GitOKWorkspaceScene] = []
        for scene in scenes where !result.contains(scene) {
            result.append(scene)
        }
        return result
    }
}

// MARK: - Observer Handle Implementation

@MainActor
private final class WorkspaceSceneObserverHandleImpl: WorkspaceSceneObserverHandle {
    private weak var owner: DefaultWorkspaceSceneProvider?
    private let callback: (WorkspaceSceneEvent) -> Void
    private var isCancelled = false

    init(
        owner: DefaultWorkspaceSceneProvider,
        callback: @escaping (WorkspaceSceneEvent) -> Void
    ) {
        self.owner = owner
        self.callback = callback
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        owner?.removeObserver(self)
    }

    fileprivate func invoke(_ event: WorkspaceSceneEvent) {
        guard !isCancelled else { return }
        callback(event)
    }
}

@MainActor
private final class WeakWorkspaceSceneObserver {
    fileprivate weak var handle: WorkspaceSceneObserverHandleImpl?

    init(_ handle: WorkspaceSceneObserverHandleImpl) {
        self.handle = handle
    }
}
