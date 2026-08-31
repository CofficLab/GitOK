import Combine
import Foundation

@MainActor
public final class BlockingOperationCenter: ObservableObject {
    public struct State: Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let message: String
        public let detail: String?

        public init(id: UUID = UUID(), title: String, message: String, detail: String? = nil) {
            self.id = id
            self.title = title
            self.message = message
            self.detail = detail
        }
    }

    public static let shared = BlockingOperationCenter()

    @Published public private(set) var state: State?

    private init() {}

    @discardableResult
    public func begin(title: String, message: String, detail: String? = nil) -> UUID {
        let id = UUID()
        state = State(id: id, title: title, message: message, detail: detail)
        return id
    }

    public func update(id: UUID, message: String, detail: String? = nil) {
        guard state?.id == id else { return }
        state = State(id: id, title: state?.title ?? "", message: message, detail: detail)
    }

    public func end(id: UUID) {
        guard state?.id == id else { return }
        state = nil
    }
}
