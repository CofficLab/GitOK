import Foundation

// MARK: - Events

/// 仓库监听事件。
///
/// 由实现了 `GitRepositoryWatching` 的 provider 在监听状态变化或
/// 检测到 `.git` 目录内容变动时广播给订阅方。事件分两类：
/// - 监听生命周期：`.started` / `.stopped`；
/// - `.git` 内部状态变化（按维度细分，便于订阅方按需刷新）：
///   `.headChanged` / `.indexChanged` / `.stashChanged` / `.refsChanged`；
/// - 工作区文件变化：`.workingTreeChanged`（外部编辑 / 新增 / 删除文件）。
///
/// 对齐旧版 `GitDirectoryWatcher` 的 5 类通知
/// （`projectGitDirectoryDidChange` / `Head` / `Index` / `Stash` / `Refs`），
/// 但采用 Lumi provider 的观察者体系（`addObserver` + `ObserverHandle`）广播。
@MainActor
public enum GitRepositoryWatchingEvent: Equatable, Sendable {
    /// 开始监听指定仓库。
    case started(repositoryURL: URL)
    /// 停止监听。
    case stopped
    /// HEAD（当前 commit）发生变化；携带旧 / 新 hash，便于消费方精确判断。
    ///
    /// - 无旧 hash：首次读取或 HEAD 由 ref 形式切换成 detached 等场景；
    /// - 无新 hash：HEAD 被清空（如仓库被销毁 / `.git/HEAD` 读取失败）。
    case headChanged(previousHead: String?, head: String?)
    /// 暂存区（`.git/index`）发生变化。
    case indexChanged
    /// stash 引用 / 日志发生变化。
    case stashChanged
    /// refs（分支 / 标签 / 远程引用 / `packed-refs`）发生变化。
    case refsChanged
    /// 工作区文件发生变化（外部编辑 / 新增 / 删除文件）。
    ///
    /// 当用户在其他编辑器中修改文件、或在 Finder 中操作文件时触发。
    /// 消费方（如工作区状态条）应重新计算变更文件数量。
    case workingTreeChanged
}

// MARK: - Observer Handle

/// 仓库监听观察者的取消句柄。
///
/// 调用 `cancel()` 后订阅方不再收到任何后续事件；重复取消为空操作。
/// 与 `ProjectProvidingObserverHandle` / `CommitFormObserverHandle` 同一套
/// Lumi provider 约定：handle 为 class（`AnyObject`），捕获订阅 id 即可。
@MainActor
public protocol GitRepositoryWatchingObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// 仓库监听提供能力协议。
///
/// 定义「内核 → 仓库监听」这一段的最小契约：宿主与插件通过内核解析
/// `GitRepositoryWatching`，启动对当前项目 `.git` 目录的监听，
/// 并在状态变化时把事件广播给订阅方。
///
/// 协议只声明逻辑能力，不关心实现：
/// - 具体监听策略（FSEventStream / 轮询 / 外部触发）由实现决定；
/// - 事件语义（head / index / stash / refs 变化的维度区分）由本协议固定；
/// - 实现方需保证回调在 MainActor 上执行（协议已 `@MainActor`）。
///
/// 典型消费方：
/// - 工作区状态条（关注 `indexChanged` 重算变更文件数；关注 `headChanged`
///   刷新当前分支 / commit 信息）；
/// - commit 列表（关注 `headChanged` 刷新列表）；
/// - 分支状态条（关注 `refsChanged` 刷新远程跟踪状态）。
///
/// 典型实现：宿主在 `PluginGitRepositoryWatch` 里用 `FSEventStream`
/// 监听 `.git` 目录、按维度对比 snapshot 后广播对应事件；或更简单地，
/// 在内部操作（commit / push / stash / branch checkout）完成后由插件主动
/// 调用广播方法——事件语义保持一致，消费方无需区分来源。
@MainActor
public protocol GitRepositoryWatching: AnyObject {
    /// 当前正在监听的仓库 URL；未监听时为 `nil`。
    var watchingRepositoryURL: URL? { get }

    /// 订阅仓库监听事件。回调在事件发生后立即在 MainActor 上执行。
    @discardableResult
    func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle

    /// 开始监听指定仓库。
    ///
    /// 如已在监听同一 URL，幂等（不重复广播 `.started`）；
    /// 如在监听不同 URL，先停旧监听再启新监听。
    func startWatching(repositoryURL: URL)

    /// 停止当前监听。
    ///
    /// 未监听时为空操作；停止后广播一次 `.stopped`。
    func stopWatching()
}

// MARK: - Default (No-op) Implementation

/// `GitRepositoryWatching` 的默认空实现。
///
/// 只做「状态 + 订阅 + 生命周期事件广播」，不接入任何真实文件系统监听，
/// 便于测试 / 预览 / 不需要真实监听的场景（例如 CLI 测试、SwiftUI Preview）。
///
/// 真正的 FSEventStream 监听由宿主插件（如 `PluginGitRepositoryWatch`）
/// 提供自己的实现并注册到内核；默认实现作为「兜底 provider」保证
/// 内核解析 `GitRepositoryWatching` 始终有值。
@MainActor
public final class DefaultGitRepositoryWatching: GitRepositoryWatching {
    public private(set) var watchingRepositoryURL: URL?

    private var observers: [(id: UUID, callback: (GitRepositoryWatchingEvent) -> Void)] = []

    public init() {}

    public func addObserver(
        _ callback: @escaping (GitRepositoryWatchingEvent) -> Void
    ) -> any GitRepositoryWatchingObserverHandle {
        let id = UUID()
        observers.append((id, callback))
        return DefaultHandle { [weak self] in
            self?.observers.removeAll { $0.id == id }
        }
    }

    public func startWatching(repositoryURL: URL) {
        let standardized = repositoryURL.standardizedFileURL
        guard watchingRepositoryURL?.standardizedFileURL != standardized else { return }
        watchingRepositoryURL = standardized
        broadcast(.started(repositoryURL: standardized))
    }

    public func stopWatching() {
        guard watchingRepositoryURL != nil else { return }
        watchingRepositoryURL = nil
        broadcast(.stopped)
    }

    // MARK: - Internal

    /// 向所有订阅方广播事件（实现方在检测到 `.git` 内部变化时调用）。
    ///
    /// 拷贝 observers 数组再遍历，避免回调内增删订阅导致迭代失效。
    public func broadcast(_ event: GitRepositoryWatchingEvent) {
        let current = observers
        for observer in current {
            observer.callback(event)
        }
    }

    // MARK: - Handle

    private final class DefaultHandle: GitRepositoryWatchingObserverHandle {
        private let onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func cancel() {
            onCancel()
        }
    }
}
