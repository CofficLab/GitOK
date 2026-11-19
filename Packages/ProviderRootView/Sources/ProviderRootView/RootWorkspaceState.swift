import Foundation

/// 根布局当前工作区的可用状态。
///
/// 该状态只控制工作区内容是否挂载；工具栏和项目 Sidebar 始终保留，
/// 这样用户仍然可以切换项目、添加项目或移除失效项目。
@MainActor
public enum RootWorkspaceState: Equatable, Sendable {
    case noProject
    case projectMissing(path: String)
    case notGitRepository(path: String)
    case cloning
    case cloneFailed
    case ready
}