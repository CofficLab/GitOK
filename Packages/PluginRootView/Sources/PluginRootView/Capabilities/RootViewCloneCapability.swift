import Foundation
import ProviderCloneRepository

/// 根视图插件读取克隆任务状态与重试的最小能力。
///
/// 插件入口用本能力把 `CloneRepositoryProviding` 收窄；克隆状态视图只依赖此协议，
/// 避免克隆 Provider 穿透到视图层。
@MainActor
protocol RootViewCloneCapability: AnyObject {
    func task(for destination: URL) -> CloneTask?

    /// 重试失败的克隆任务；失败时由调用方决定如何展示错误。
    func retry(taskID: UUID) throws -> CloneTask

    @discardableResult
    func addObserver(
        _ callback: @escaping (CloneRepositoryEvent) -> Void
    ) -> any CloneRepositoryObserverHandle
}

/// 将 `CloneRepositoryProviding` 收窄成根视图所需的克隆能力。
@MainActor
final class RootViewCloneCapabilityAdapter: RootViewCloneCapability {
    private let cloneRepository: (any CloneRepositoryProviding)?

    init(cloneRepository: (any CloneRepositoryProviding)?) {
        self.cloneRepository = cloneRepository
    }

    func task(for destination: URL) -> CloneTask? {
        cloneRepository?.task(for: destination)
    }

    func retry(taskID: UUID) throws -> CloneTask {
        guard let cloneRepository else {
            throw RootViewCloneCapabilityError.unavailable
        }
        return try cloneRepository.retry(taskID: taskID)
    }

    @discardableResult
    func addObserver(
        _ callback: @escaping (CloneRepositoryEvent) -> Void
    ) -> any CloneRepositoryObserverHandle {
        guard let cloneRepository else {
            return RootViewCloneCapabilityNoopHandle()
        }
        return cloneRepository.addObserver(callback)
    }
}

/// 克隆 Provider 未注册时的降级错误。
enum RootViewCloneCapabilityError: Error {
    case unavailable
}

/// 克隆 Provider 未注册时返回的空令牌，供视图层安全地订阅而不必做可选判断。
@MainActor
final class RootViewCloneCapabilityNoopHandle: CloneRepositoryObserverHandle {
    func cancel() {}
}