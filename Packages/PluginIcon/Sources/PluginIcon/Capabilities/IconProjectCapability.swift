import Foundation
import ProviderProjects

/// Icon 插件读取当前项目与订阅项目选择变化所需的最小能力。
@MainActor
public protocol IconProjectCapability: AnyObject {
    var currentProject: Project? { get }

    @discardableResult
    func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle
}

/// 将项目 Provider 收窄成 Icon 插件的业务能力。
@MainActor
public final class IconProjectCapabilityAdapter: IconProjectCapability {
    private let provider: any ProjectProviding

    public init(projects: any ProjectProviding) {
        self.provider = projects
    }

    public var currentProject: Project? {
        provider.currentProject
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (ProjectProvidingEvent) -> Void
    ) -> any ProjectProvidingObserverHandle {
        provider.addObserver(callback)
    }
}
