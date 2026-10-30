import Foundation

/// 工作区内容的归属方。
///
/// 「工作区是否干净」此前由两个插件各自判断：变更列表插件读一次工作区快照，
/// 干净视图插件再读一次状态。两次读取不在同一时刻，一旦结论不一致，两个内容块
/// 会同时渲染 `EmptyView`，主内容区整块塌陷（提交表单漂到面板中间、详情区留白）。
///
/// 这里把判定收敛成唯一事实来源：两个插件都订阅同一份归属变化，任何时刻
/// 两边的结论都一致，因此内容区不会出现"两边都空"的空档。
public enum WorktreeContentOwner: String, Equatable, Sendable {
    /// 尚无结论（未扫描 / 扫描中）：变更列表展示加载占位，干净概览不占布局。
    case pending
    /// 工作区存在未提交变更：由变更列表展示文件列表。
    case changes
    /// 工作区干净：由干净概览展示仓库信息。
    case clean

    /// 由快照推导归属方：没有条目即工作区干净。
    public static func resolve(entriesCount: Int) -> WorktreeContentOwner {
        entriesCount == 0 ? .clean : .changes
    }
}

/// 工作区内容归属观察句柄。
public protocol WorktreeContentOwnerObserverHandle: AnyObject {
    func cancel()
}

/// 工作区内容归属的共享状态。
///
/// 线程安全：Git 读取发生在后台线程，观察者回调统一派发到主线程。
public final class WorktreeContentOwnership: @unchecked Sendable {
    private final class ObserverBox {
        let id: UUID
        let callback: @MainActor @Sendable (URL, WorktreeContentOwner) -> Void

        init(
            id: UUID,
            callback: @escaping @MainActor @Sendable (URL, WorktreeContentOwner) -> Void
        ) {
            self.id = id
            self.callback = callback
        }
    }

    private let lock = NSLock()
    private var owners: [String: WorktreeContentOwner] = [:]
    private var observers: [UUID: ObserverBox] = [:]

    public init() {}

    /// 当前归属方；未扫描过的仓库返回 `.pending`。
    public func owner(for repository: URL) -> WorktreeContentOwner {
        let key = repository.standardizedFileURL.path
        lock.lock()
        defer { lock.unlock() }
        return owners[key] ?? .pending
    }

    /// 发布归属变化；同一仓库的归属未变化时不会通知观察者。
    public func publish(owner: WorktreeContentOwner, for repository: URL) {
        let key = repository.standardizedFileURL.path
        lock.lock()
        let previous = owners[key]
        guard previous != owner else {
            lock.unlock()
            return
        }
        owners[key] = owner
        let current = Array(observers.values)
        lock.unlock()

        guard previous != owner else { return }
        for observer in current {
            Self.deliver(observer.callback, repository: repository, owner: owner)
        }
    }

    public func addObserver(
        _ callback: @escaping @MainActor @Sendable (URL, WorktreeContentOwner) -> Void
    ) -> any WorktreeContentOwnerObserverHandle {
        let id = UUID()
        lock.lock()
        observers[id] = ObserverBox(id: id, callback: callback)
        lock.unlock()
        return DefaultHandle { [weak self] in
            guard let self else { return }
            self.lock.lock()
            self.observers.removeValue(forKey: id)
            self.lock.unlock()
        }
    }

    /// 观察者回调统一在主线程派发，避免插件视图模型跨线程更新。
    private static func deliver(
        _ callback: @escaping @MainActor @Sendable (URL, WorktreeContentOwner) -> Void,
        repository: URL,
        owner: WorktreeContentOwner
    ) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                callback(repository, owner)
            }
        } else {
            DispatchQueue.main.async {
                callback(repository, owner)
            }
        }
    }

    private final class DefaultHandle: WorktreeContentOwnerObserverHandle {
        private let onCancel: () -> Void

        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }

        func cancel() {
            onCancel()
        }
    }
}

/// 不广播任何变化的观察句柄（用于没有共享归属存储的 Provider 兼容实现）。
final class NoopWorktreeContentOwnerObserverHandle: WorktreeContentOwnerObserverHandle {
    func cancel() {}
}
