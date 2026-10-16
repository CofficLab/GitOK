import Foundation
import KitGit
import ProviderCloneRepository
import ProviderGit

/// 解析项目 remote 所需的最小能力。
///
/// re-clone 要从既有项目里读出 remote URL，这是 `GitProviding` 中与 clone
/// 无关的另一个切面，单独收窄以便协调器可脱离 Provider 独立测试。
@MainActor
protocol GitRemoteCapability: AnyObject {
    func listRemotes(in repositoryURL: URL) -> [GitRemoteSummary]
}

/// 将 `GitProviding` 收窄成 remote 解析能力。
@MainActor
final class GitRemoteCapabilityAdapter: GitRemoteCapability {
    private let git: any GitProviding

    init(git: any GitProviding) {
        self.git = git
    }

    func listRemotes(in repositoryURL: URL) -> [GitRemoteSummary] {
        git.listRemotes(in: repositoryURL)
    }
}

/// Re-clone 流程所需的最小克隆能力。
///
/// 校验目标目录是 `GitProviding` 的职责、登记后台任务是 `CloneRepositoryProviding`
/// 的职责；二者在 re-clone 中强耦合，因此在装配阶段一次适配成同一能力。
@MainActor
protocol ProjectCloneCapability: AnyObject {
    var tasks: [CloneTask] { get }

    func validateDestination(_ url: URL) throws
    func enqueue(remoteURL: String, destination: URL, repositoryName: String) throws -> CloneTask
}

/// 将 `GitProviding` 与 `CloneRepositoryProviding` 收窄成 re-clone 所需的克隆能力。
@MainActor
final class ProjectCloneCapabilityAdapter: ProjectCloneCapability {
    private let git: (any GitProviding)?
    private let cloneRepository: (any CloneRepositoryProviding)?

    init(
        git: (any GitProviding)?,
        cloneRepository: (any CloneRepositoryProviding)?
    ) {
        self.git = git
        self.cloneRepository = cloneRepository
    }

    var tasks: [CloneTask] {
        cloneRepository?.tasks ?? []
    }

    func validateDestination(_ url: URL) throws {
        guard let git else { throw ProjectCloneError.unavailable }
        try git.validateCloneDestination(url)
    }

    func enqueue(remoteURL: String, destination: URL, repositoryName: String) throws -> CloneTask {
        guard let cloneRepository else { throw ProjectCloneError.unavailable }
        return try cloneRepository.enqueue(
            remoteURL: remoteURL,
            destination: destination,
            repositoryName: repositoryName
        )
    }
}

/// 克隆 Provider 未注册时的降级错误。
enum ProjectCloneError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        pluginLocalization.string("Clone repository is unavailable.")
    }
}