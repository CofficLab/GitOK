import Foundation
import KitGit

// MARK: - Events

/// Commit 详情选择事件。
@MainActor
public enum CommitDetailEvent {
    /// 选中的 commit 发生变化；回调执行时 `selectedCommit` / `selectedProjectURL` 已是新值。
    case selectionChanged

    /// 当前 commit 内选中的文件发生变化；回调执行时 `selectedFile` 已是新值。
    /// （例如 commit 详情文件列表选中某文件，git diff 等消费方据此刷新。）
    case selectedFileChanged
}

// MARK: - Observer Handle

@MainActor
public protocol CommitDetailObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// Commit 详情提供能力协议
///
/// 定义「commit 列表 → commit 详情」这一段的最小契约：commit 列表插件
/// （侧边栏 Rail）在用户选中某条 commit 时把选择写入本 Provider；
/// commit 详情插件（主内容区）订阅本 Provider 并渲染对应变动。
///
/// 状态变化通过**观察者体系**通知（参考 Lumi 其他 Provider，如
/// `ProjectProviding` / `ThemeProviding`）：消费方调用 `addObserver` 订阅
/// `CommitDetailEvent`，在状态更新完成后收到回调；返回的 handle 用于取消。
///
/// 协议只声明逻辑能力，不关心 UI，也不做任何 git 读取——git 加载由
/// 消费方（详情插件）通过 `KitGit` 完成。
@MainActor
public protocol CommitDetailProviding: AnyObject {
    /// 当前选中的 commit；未选中时为 nil。
    var selectedCommit: GitCommit? { get }

    /// 选中 commit 所属的项目路径。
    var selectedProjectURL: URL? { get }

    /// 当前选中的 commit 内选中的文件路径；未选中文件时为 nil。
    ///
    /// 该状态与 `selectedCommit` 联动：切换 commit 时自动清空（新 commit 无选中文件）。
    var selectedFile: String? { get }

    /// 监听选中状态变化（commit 或文件变化都会触发）。
    @discardableResult
    func addObserver(_ callback: @escaping (CommitDetailEvent) -> Void) -> any CommitDetailObserverHandle

    /// 选中一个 commit（写入状态并广播事件）。
    ///
    /// 会同时清空 `selectedFile`，因为新 commit 尚无选中的文件。
    func selectCommit(_ commit: GitCommit, in projectURL: URL)

    /// 选中当前 commit 内的某个文件（写入状态并广播 `selectedFileChanged`）。
    /// 传 `nil` 表示取消文件选择。
    func selectFile(_ path: String?)

    /// 清除选中状态（例如切换项目或关闭项目时）。
    func clearSelection()
}

// MARK: - Default Implementation

/// 默认实现：内存状态 + 弱引用观察者广播。
///
/// 状态保持单一权威来源（本实例），广播在状态更新完成后同步执行。
/// 观察者令牌被外部释放后自动失效，并在下次广播时清理（无需手动反注册）。
@MainActor
public final class DefaultCommitDetailProvider: CommitDetailProviding {
    public private(set) var selectedCommit: GitCommit?
    public private(set) var selectedProjectURL: URL?
    public private(set) var selectedFile: String?

    /// 当前注册的观察者集合（弱引用持有令牌）。
    private var observers: [WeakCommitDetailObserver] = []

    public init() {}

    public func selectCommit(_ commit: GitCommit, in projectURL: URL) {
        // 以 hash 为 commit 唯一标识做去重（date 等元信息每次加载可能不同）。
        guard selectedCommit?.hash != commit.hash || selectedProjectURL != projectURL else { return }
        selectedCommit = commit
        selectedProjectURL = projectURL
        // 新 commit 尚无选中文件：清空并广播文件变化，让 diff 等消费方跟随。
        let hadFile = selectedFile != nil
        selectedFile = nil
        notifyObservers(.selectionChanged)
        if hadFile {
            notifyObservers(.selectedFileChanged)
        }
    }

    public func selectFile(_ path: String?) {
        guard selectedFile != path else { return }
        selectedFile = path
        notifyObservers(.selectedFileChanged)
    }

    public func clearSelection() {
        guard selectedCommit != nil || selectedProjectURL != nil || selectedFile != nil else { return }
        let hadFile = selectedFile != nil
        selectedCommit = nil
        selectedProjectURL = nil
        selectedFile = nil
        notifyObservers(.selectionChanged)
        if hadFile {
            notifyObservers(.selectedFileChanged)
        }
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (CommitDetailEvent) -> Void
    ) -> any CommitDetailObserverHandle {
        let handle = CommitDetailObserverHandleImpl(owner: self, callback: callback)
        observers.append(WeakCommitDetailObserver(handle))
        return handle
    }

    /// 从集合中移除指定观察者（供令牌的 cancel 调用）。
    fileprivate func removeObserver(_ handle: any CommitDetailObserverHandle) {
        observers.removeAll { $0.handle === handle }
    }

    /// 向所有已注册观察者广播事件。
    ///
    /// 先清理已释放令牌并复制再遍历，避免回调中注销自身导致数组在遍历期间变化。
    private func notifyObservers(_ event: CommitDetailEvent) {
        observers.removeAll { $0.handle == nil }
        let current = observers
        for observer in current {
            observer.handle?.invoke(event)
        }
    }
}

// MARK: - Observer Handle Implementation

/// 观察者令牌：弱引用 owner，避免形成引用环。
///
/// 令牌被外部释放后，管理器侧持有的弱引用自动失效，并在下次广播时清理。
@MainActor
private final class CommitDetailObserverHandleImpl: CommitDetailObserverHandle {
    private weak var owner: DefaultCommitDetailProvider?
    private let callback: (CommitDetailEvent) -> Void
    private var isCancelled = false

    init(owner: DefaultCommitDetailProvider, callback: @escaping (CommitDetailEvent) -> Void) {
        self.owner = owner
        self.callback = callback
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        owner?.removeObserver(self)
    }

    /// 通知回调（已注销的令牌不再触发）。
    fileprivate func invoke(_ event: CommitDetailEvent) {
        guard !isCancelled else { return }
        callback(event)
    }
}

/// 观察者集合的元素：弱引用持有令牌，令牌被外部释放后自动失效。
@MainActor
private final class WeakCommitDetailObserver {
    fileprivate weak var handle: CommitDetailObserverHandleImpl?

    init(_ handle: CommitDetailObserverHandleImpl) {
        self.handle = handle
    }
}
