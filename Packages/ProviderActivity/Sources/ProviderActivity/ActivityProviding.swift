import Foundation

// MARK: - Events

/// 活动状态事件。
@MainActor
public enum ActivityEvent {
    /// 当前活动状态变化（开始 / 结束）；回调执行时 `currentActivity` 已是新值。
    case activityChanged
}

// MARK: - Observer Handle

@MainActor
public protocol ActivityObserverHandle: AnyObject {
    func cancel()
}

// MARK: - Contract

/// 活动状态提供能力协议
///
/// 维护「当前正在进行的长时间操作」状态（如提交 / 推送），供状态栏等
/// 消费方展示 spinner + 文本。状态变化通过**观察者体系**通知
/// （参考 Lumi 其他 Provider）：调用 `addObserver` 订阅 `ActivityEvent`。
@MainActor
public protocol ActivityProviding: AnyObject {
    /// 当前活动描述；无活动时为 nil。
    var currentActivity: String? { get }

    /// 监听活动状态变化。
    @discardableResult
    func addObserver(_ callback: @escaping (ActivityEvent) -> Void) -> any ActivityObserverHandle

    /// 开始 / 更新一个活动；传 nil 等价于 `clearActivity()`。
    func setActivity(_ activity: String?)

    /// 结束当前活动。
    func clearActivity()
}

// MARK: - Default Implementation

/// 默认实现：内存状态 + 弱引用观察者广播。
@MainActor
public final class DefaultActivityProvider: ActivityProviding {
    public private(set) var currentActivity: String?

    private var observers: [WeakActivityObserver] = []

    public init() {}

    public func setActivity(_ activity: String?) {
        guard currentActivity != activity else { return }
        currentActivity = activity
        notifyObservers(.activityChanged)
    }

    public func clearActivity() {
        setActivity(nil)
    }

    @discardableResult
    public func addObserver(
        _ callback: @escaping (ActivityEvent) -> Void
    ) -> any ActivityObserverHandle {
        let handle = ActivityObserverHandleImpl(owner: self, callback: callback)
        observers.append(WeakActivityObserver(handle))
        return handle
    }

    fileprivate func removeObserver(_ handle: any ActivityObserverHandle) {
        observers.removeAll { $0.handle === handle }
    }

    private func notifyObservers(_ event: ActivityEvent) {
        observers.removeAll { $0.handle == nil }
        let current = observers
        for observer in current {
            observer.handle?.invoke(event)
        }
    }
}

// MARK: - Observer Handle Implementation

@MainActor
private final class ActivityObserverHandleImpl: ActivityObserverHandle {
    private weak var owner: DefaultActivityProvider?
    private let callback: (ActivityEvent) -> Void
    private var isCancelled = false

    init(owner: DefaultActivityProvider, callback: @escaping (ActivityEvent) -> Void) {
        self.owner = owner
        self.callback = callback
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        owner?.removeObserver(self)
    }

    fileprivate func invoke(_ event: ActivityEvent) {
        guard !isCancelled else { return }
        callback(event)
    }
}

@MainActor
private final class WeakActivityObserver {
    fileprivate weak var handle: ActivityObserverHandleImpl?

    init(_ handle: ActivityObserverHandleImpl) {
        self.handle = handle
    }
}
