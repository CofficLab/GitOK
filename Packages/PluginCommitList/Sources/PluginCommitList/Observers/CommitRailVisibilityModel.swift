import Combine
import Foundation
import ProviderProjects

/// Commit 列表 Rail 区块的可见性状态模型。
///
/// 当项目不存在于磁盘时，`CommitRailView` 返回 `EmptyView()`，
/// 此时 Rail 区块应当隐藏。此模型跟踪项目存在性状态，供插件创建 section 时使用。
@MainActor
final class CommitRailVisibilityModel: ObservableObject {
    @Published private(set) var hasVisibleContent: Bool = false

    private let projects: any ProjectProviding
    private var observerHandle: (any ProjectProvidingObserverHandle)?

    init(projects: any ProjectProviding) {
        self.projects = projects
        updateVisibility()

        observerHandle = projects.addObserver { [weak self] event in
            switch event {
            case .selectionChanged, .projectsChanged:
                self?.updateVisibility()
            default:
                break
            }
        }
    }

    /// 取消观察者。在插件关闭时调用。
    func cancel() {
        observerHandle?.cancel()
        observerHandle = nil
    }

    private func updateVisibility() {
        guard let project = projects.currentProject else {
            hasVisibleContent = false
            return
        }
        hasVisibleContent = FileManager.default.fileExists(atPath: project.url.path)
    }

    /// 返回可见性发布器，供 `RailSectionItem` 使用。
    var visibilityPublisher: AnyPublisher<Bool, Never> {
        $hasVisibleContent.eraseToAnyPublisher()
    }
}
