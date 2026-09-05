import Foundation

/// 提交流程错误状态。
public struct CommitFormError: Identifiable, Equatable {
    public let id: UUID
    public let operation: String
    public let message: String

    public init(id: UUID = UUID(), operation: String, message: String) {
        self.id = id
        self.operation = operation
        self.message = message
    }
}

/// 提交或提交并推送失败的持久化状态中心。
@MainActor
public final class CommitFormErrorCenter: ObservableObject {
    @Published public private(set) var error: CommitFormError?

    public init() {}

    public func present(operation: String, message: String) {
        error = CommitFormError(operation: operation, message: message)
    }

    public func dismiss() {
        error = nil
    }
}
