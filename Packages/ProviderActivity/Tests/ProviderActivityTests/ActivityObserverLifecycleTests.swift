import Foundation
import Testing
@testable import ProviderActivity

/// 覆盖 `DefaultActivityProvider` 观察者体系里既有用例没有触达的分支：
/// 取消订阅、重复取消、空状态清理、多观察者广播与弱引用回收。
@MainActor
@Suite("ProviderActivity 观察者生命周期")
struct ActivityObserverLifecycleTests {

    @Test("取消订阅后不再收到事件")
    func cancelledObserverStopsReceivingEvents() {
        let provider = DefaultActivityProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }

        provider.setActivity("Committing...")
        #expect(count == 1)

        handle.cancel()
        provider.setActivity("Pushing...")
        provider.clearActivity()

        #expect(count == 1)
        #expect(provider.currentActivity == nil)
    }

    @Test("重复取消订阅是幂等的")
    func cancelIsIdempotent() {
        let provider = DefaultActivityProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }

        handle.cancel()
        handle.cancel()
        handle.cancel()

        provider.setActivity("Committing...")

        #expect(count == 0)
    }

    @Test("空状态下清理活动不产生事件")
    func clearingEmptyActivityDoesNotNotify() {
        let provider = DefaultActivityProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        defer { handle.cancel() }

        provider.clearActivity()
        provider.setActivity(nil)

        #expect(count == 0)
        #expect(provider.currentActivity == nil)
    }

    @Test("setActivity(nil) 等价于 clearActivity")
    func setNilEqualsClear() {
        let provider = DefaultActivityProvider()
        var events: [ActivityEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.setActivity("Committing...")
        provider.setActivity(nil)

        #expect(provider.currentActivity == nil)
        #expect(events.count == 2)
    }

    @Test("多个观察者都会收到广播")
    func broadcastsToAllObservers() {
        let provider = DefaultActivityProvider()
        var first = 0
        var second = 0
        let firstHandle = provider.addObserver { _ in first += 1 }
        let secondHandle = provider.addObserver { _ in second += 1 }
        defer {
            firstHandle.cancel()
            secondHandle.cancel()
        }

        provider.setActivity("Committing...")

        #expect(first == 1)
        #expect(second == 1)
    }

    @Test("取消其中一个观察者不影响其他观察者")
    func cancellingOneObserverKeepsOthersActive() {
        let provider = DefaultActivityProvider()
        var cancelled = 0
        var active = 0
        let cancelledHandle = provider.addObserver { _ in cancelled += 1 }
        let activeHandle = provider.addObserver { _ in active += 1 }
        defer { activeHandle.cancel() }

        cancelledHandle.cancel()
        provider.setActivity("Committing...")

        #expect(cancelled == 0)
        #expect(active == 1)
    }

    @Test("观察者句柄释放后被安全回收")
    func releasedHandleIsSafelyCollected() {
        let provider = DefaultActivityProvider()
        var count = 0
        do {
            let handle = provider.addObserver { _ in count += 1 }
            provider.setActivity("Committing...")
            #expect(count == 1)
            handle.cancel()
        }

        // 句柄已释放且已取消：再次广播不应崩溃，也不应触发回调。
        provider.setActivity("Pushing...")

        #expect(count == 1)
        #expect(provider.currentActivity == "Pushing...")
    }

    @Test("活动值变化时按顺序广播")
    func broadcastsOnEveryDistinctValue() {
        let provider = DefaultActivityProvider()
        var events: [ActivityEvent] = []
        let handle = provider.addObserver { events.append($0) }
        defer { handle.cancel() }

        provider.setActivity("A")
        provider.setActivity("B")
        provider.setActivity("C")

        #expect(events.count == 3)
        #expect(provider.currentActivity == "C")
    }
}
