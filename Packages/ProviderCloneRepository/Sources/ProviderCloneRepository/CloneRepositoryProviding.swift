import Foundation

/// 后台克隆任务的生命周期。
public enum CloneTaskStatus: String, Codable, Equatable, Sendable {
    case queued
    case cloning
    case cancelling
    case completed
    case failed
    case cancelled

    public var isActive: Bool {
        switch self {
        case .queued, .cloning, .cancelling:
            true
        case .completed, .failed, .cancelled:
            false
        }
    }
}

/// Git 后端上报的克隆阶段。
public enum CloneTaskPhase: String, Codable, Equatable, Sendable {
    case preparing
    case receivingObjects
    case resolvingDeltas
    case checkingOut
    case completed
}

/// 可持久化的克隆任务快照。
public struct CloneTask: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let remoteURL: String
    public let destination: URL
    public let repositoryName: String
    public var status: CloneTaskStatus
    public var phase: CloneTaskPhase?
    public var fractionCompleted: Double?
    public var detail: String?
    public var errorMessage: String?
    public let createdAt: Date
    public var updatedAt: Date
    public var startedAt: Date?
    public var finishedAt: Date?

    public init(
        id: UUID = UUID(),
        remoteURL: String,
        destination: URL,
        repositoryName: String,
        status: CloneTaskStatus = .queued,
        phase: CloneTaskPhase? = nil,
        fractionCompleted: Double? = nil,
        detail: String? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        startedAt: Date? = nil,
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.remoteURL = remoteURL
        self.destination = destination
        self.repositoryName = repositoryName
        self.status = status
        self.phase = phase
        self.fractionCompleted = fractionCompleted
        self.detail = detail
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}

public enum CloneRepositoryError: Error, LocalizedError, Equatable, Sendable {
    case taskAlreadyExists(destination: URL)
    case taskNotFound(UUID)
    case invalidRetryStatus(CloneTaskStatus)

    public var errorDescription: String? {
        switch self {
        case let .taskAlreadyExists(destination):
            "A clone task already exists for \(destination.path)."
        case let .taskNotFound(id):
            "Clone task \(id.uuidString) was not found."
        case let .invalidRetryStatus(status):
            "A clone task in \(status.rawValue) state cannot be retried."
        }
    }
}

@MainActor
public enum CloneRepositoryEvent {
    case tasksChanged
    case taskUpdated(UUID)
}

@MainActor
public protocol CloneRepositoryObserverHandle: AnyObject {
    func cancel()
}

/// 克隆任务的唯一权威来源。
///
/// 该 Provider 不依赖具体 Git 后端，也不规定任务如何落盘；实现插件负责
/// 将任务交给 `ProviderGit` 执行，并在需要时持久化 `CloneTask`。
@MainActor
public protocol CloneRepositoryProviding: AnyObject {
    var tasks: [CloneTask] { get }

    /// 返回项目目录当前是否存在仍在运行的克隆任务。
    func isCloning(for projectURL: URL) -> Bool
    func task(for destination: URL) -> CloneTask?
    func enqueue(remoteURL: String, destination: URL, repositoryName: String) throws -> CloneTask
    func cancel(taskID: UUID)
    func retry(taskID: UUID) throws -> CloneTask

    @discardableResult
    func addObserver(_ callback: @escaping (CloneRepositoryEvent) -> Void) -> any CloneRepositoryObserverHandle
}
