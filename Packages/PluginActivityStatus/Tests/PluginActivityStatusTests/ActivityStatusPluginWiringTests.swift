import Foundation
import KernelCore
import ProviderActivity
import ProviderStatusBar
import SwiftUI
import Testing
@testable import PluginActivityStatus

// MARK: - Test doubles

/// `ActivityProviding` double whose events fire on demand.
@MainActor
private final class Activity: ActivityProviding {
    var currentActivity: String?
    private var callbacks: [UUID: (ActivityEvent) -> Void] = [:]
    private(set) var observerCount = 0

    func addObserver(_ callback: @escaping (ActivityEvent) -> Void) -> any ActivityObserverHandle {
        let token = UUID()
        observerCount += 1
        callbacks[token] = callback
        return ActivityHandle { [weak self] in
            self?.callbacks[token] = nil
            self?.observerCount -= 1
        }
    }

    func setActivity(_ activity: String?) { currentActivity = activity }

    func clearActivity() { currentActivity = nil }

    /// Simulates an activity change reaching every live observer.
    func emit(_ event: ActivityEvent) {
        callbacks.values.forEach { $0(event) }
    }
}

@MainActor
private final class ActivityHandle: ActivityObserverHandle {
    private var cancelAction: (() -> Void)?

    init(cancel: @escaping () -> Void) {
        self.cancelAction = cancel
    }

    func cancel() {
        cancelAction?()
        cancelAction = nil
    }
}

@MainActor
private final class StatusBar: StatusBarProviding, ObservableObject {
    var statusBarItems: [StatusBarItem] = []

    func registerStatusBarItems(_ items: [StatusBarItem]) { statusBarItems = items }

    func makeStatusBarView() -> AnyView { AnyView(EmptyView()) }
}

// MARK: - Lifecycle

/// Wiring coverage for `ActivityStatusPlugin`.
///
/// `onBoot` resolves a status bar and an activity provider, then registers a
/// single centred item. These tests cover each guard and the teardown path.
@Suite("ActivityStatusPlugin wiring")
@MainActor
struct ActivityStatusPluginWiringTests {
    @Test("缺少 StatusBarProviding 时不注册状态栏项")
    func bootWithoutStatusBar() throws {
        let kernel = KernelCoreContainer()
        let plugin = ActivityStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("缺少 ActivityProviding 时不注册状态栏项")
    func bootWithoutActivity() throws {
        let kernel = KernelCoreContainer()
        let statusBar = StatusBar()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let plugin = ActivityStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
        try plugin.onShutdown(kernel: kernel)
    }

    @Test("依赖齐备时注册单个状态栏项")
    func bootRegistersStatusBarItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = StatusBar()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ActivityProviding).self, Activity())
        let plugin = ActivityStatusPlugin()

        try plugin.onBoot(kernel: kernel)

        let item = try #require(statusBar.statusBarItems.first)
        #expect(item.id == ActivityStatusPlugin.itemID)
        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("onShutdown 移除状态栏项")
    func shutdownRemovesItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = StatusBar()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ActivityProviding).self, Activity())
        let plugin = ActivityStatusPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }

    @Test("重复 boot 不产生重复状态栏项")
    func repeatedBootDoesNotDuplicate() throws {
        let kernel = KernelCoreContainer()
        let statusBar = StatusBar()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        try kernel.registerProvider((any ActivityProviding).self, Activity())
        let plugin = ActivityStatusPlugin()

        try plugin.onBoot(kernel: kernel)
        try plugin.onBoot(kernel: kernel)

        #expect(statusBar.statusBarItems.count == 1)

        try plugin.onShutdown(kernel: kernel)
    }

    @Test("重复 shutdown 不会抛错")
    func repeatedShutdownIsSafe() throws {
        let kernel = KernelCoreContainer()
        let statusBar = StatusBar()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let plugin = ActivityStatusPlugin()

        try plugin.onShutdown(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        #expect(statusBar.statusBarItems.isEmpty)
    }
}

// MARK: - Observation model

@Suite("ActivityObservationModel")
@MainActor
struct ActivityObservationModelTests {
    @Test("订阅后 observer 计数为 1")
    func subscribesOnInit() {
        let activity = Activity()

        let model = ActivityObservationModel(activity: activity)

        #expect(activity.observerCount == 1)
        #expect(model.revision == 0)
        _ = model
    }

    @Test("每个活动事件都会推进 revision")
    func eventsAdvanceRevision() {
        let activity = Activity()
        let model = ActivityObservationModel(activity: activity)

        activity.emit(.activityChanged)
        #expect(model.revision == 1)

        activity.emit(.activityChanged)
        #expect(model.revision == 2)
    }

    @Test("当前活动描述可从 provider 读取")
    func readsCurrentActivity() {
        let activity = Activity()
        let model = ActivityObservationModel(activity: activity)

        activity.setActivity("Pushing")
        #expect(activity.currentActivity == "Pushing")

        activity.clearActivity()
        #expect(activity.currentActivity == nil)

        _ = model
    }
}
