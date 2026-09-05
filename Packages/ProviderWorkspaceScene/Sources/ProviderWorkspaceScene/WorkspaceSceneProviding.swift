import Foundation
import SwiftUI

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

    public var title: String {
        switch self {
        case .git: WorkspaceSceneLocalization.string("Git", bundle: .module)
        case .banner: WorkspaceSceneLocalization.string("Banner", bundle: .module)
        case .icon: WorkspaceSceneLocalization.string("Icon", bundle: .module)
        }
    }

    public var systemImage: String {
        switch self {
        case .git: "arrow.triangle.branch"
        case .banner: "rectangle.inset.filled"
        case .icon: "app.dashed"
        }
    }
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
/// Provider 只管理当前场景和场景变化通知。各插件通过自己的 Observer
/// 把场景状态同步到自己的 ViewModel，再决定自己的 UI 是否渲染。
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

// MARK: - Scene Picker

/// 工作场景选择器的观察模型。
@MainActor
public final class WorkspaceScenePickerModel: ObservableObject {
    @Published public private(set) var selectedScene: GitOKWorkspaceScene
    public let availableScenes: [GitOKWorkspaceScene]

    private let provider: any WorkspaceSceneProviding
    private var observer: (any WorkspaceSceneObserverHandle)?

    public init(provider: any WorkspaceSceneProviding) {
        self.provider = provider
        self.selectedScene = provider.currentScene
        self.availableScenes = provider.availableScenes
        self.observer = provider.addObserver { [weak self] event in
            guard case let .sceneChanged(_, scene) = event else { return }
            self?.selectedScene = scene
        }
    }

    public func select(_ scene: GitOKWorkspaceScene) {
        provider.selectScene(scene)
    }
}

// MARK: - Plugin Scene State

/// 插件自己的场景状态容器。
///
/// 场景 Provider 只负责发布变更；插件入口通过自己的 Observer 把事件写入
/// 这个 ViewModel，插件视图只观察 `isActive`，不直接读取场景 Provider。
@MainActor
public final class WorkspaceSceneVisibilityViewModel: ObservableObject {
    public let targetScene: GitOKWorkspaceScene
    @Published public private(set) var currentScene: GitOKWorkspaceScene

    public init(
        targetScene: GitOKWorkspaceScene,
        currentScene: GitOKWorkspaceScene = .git
    ) {
        self.targetScene = targetScene
        self.currentScene = currentScene
    }

    public var isActive: Bool { currentScene == targetScene }

    public func handleSceneChange(_ scene: GitOKWorkspaceScene) {
        currentScene = scene
    }
}

/// 根据插件自己的场景 ViewModel 渲染内容；不持有也不查询场景 Provider。
@MainActor
public struct WorkspaceSceneVisibilityView<Content: View>: View {
    @ObservedObject private var viewModel: WorkspaceSceneVisibilityViewModel
    private let content: () -> Content

    public init(
        viewModel: WorkspaceSceneVisibilityViewModel,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.viewModel = viewModel
        self.content = content
    }

    public var body: some View {
        if viewModel.isActive {
            content()
        } else {
            EmptyView()
        }
    }
}

/// 主窗口工具栏使用的工作场景选择器。
@MainActor
public struct WorkspaceScenePickerView: View {
    @StateObject private var model: WorkspaceScenePickerModel

    public init(provider: any WorkspaceSceneProviding) {
        _model = StateObject(wrappedValue: WorkspaceScenePickerModel(provider: provider))
    }

    public var body: some View {
        Picker(WorkspaceSceneLocalization.string("Workspace", bundle: .module), selection: Binding(
            get: { model.selectedScene },
            set: { model.select($0) }
        )) {
            ForEach(model.availableScenes) { scene in
                Label(scene.title, systemImage: scene.systemImage)
                    .tag(scene)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel(WorkspaceSceneLocalization.string("Workspace", bundle: .module))
    }
}
