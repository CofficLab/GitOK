import Foundation

/// 工作区同步失败状态。
public struct WorktreeSyncFailure: Identifiable, Equatable {
    public let id: UUID
    public let operation: String
    public let message: String

    public init(id: UUID = UUID(), operation: String, message: String) {
        self.id = id
        self.operation = operation
        self.message = message
    }
}

/// 工作区同步失败的持久化状态中心。
///
/// 与 Toast 不同，失败不会自动清除；用户确认后才关闭，避免 Git 的
/// divergent branches、认证失败等关键信息在用户读完前消失。
@MainActor
public final class WorktreeSyncFailureCenter: ObservableObject {
    @Published public private(set) var failure: WorktreeSyncFailure?

    public init() {}

    public func present(operation: String, message: String) {
        failure = WorktreeSyncFailure(operation: operation, message: message)
    }

    public func dismiss() {
        failure = nil
    }
}
