import Combine
import Foundation
import ProviderProjects
import ProviderRootView

/// 根工作区状态模型。
///
/// 项目状态在根层统一计算，业务插件只负责提供视图，不再各自决定是否挂载。
@MainActor
final class RootWorkspaceModel: ObservableObject {
    @Published private(set) var state: RootWorkspaceState = .noProject
    @Published private(set) var project: Project?

    func update(state: RootWorkspaceState, project: Project?) {
        self.state = state
        self.project = project
    }

    func reset() {
        state = .noProject
        project = nil
    }
}
