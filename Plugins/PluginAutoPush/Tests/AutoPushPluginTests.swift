@testable import PluginAutoPush
import Combine
import Foundation
import Testing

@Suite("PluginAutoPush")
struct AutoPushPluginTests {
    @Test("metadata matches legacy plugin identity")
    func metadata() {
        #expect(AutoPushPlugin.metadata.id == "AutoPushPlugin")
        #expect(AutoPushPlugin.metadata.iconName == "arrow.up.circle")
        #expect(AutoPushPlugin.metadata.allowUserToggle == false)
        #expect(AutoPushPlugin.metadata.defaultEnabled == false)
        #expect(AutoPushPlugin.metadata.tableName == "AutoPush")
    }

    @Test("localization catalog is packaged")
    func localizationCatalog() {
        #expect(PluginAutoPushLocalization.bundle.url(forResource: "AutoPush", withExtension: "xcstrings") != nil)
        #expect(PluginAutoPushLocalization.string("Auto Push").isEmpty == false)
    }
}

@Suite("AutoPushService")
struct AutoPushServiceTests {
    @MainActor
    @Test("checkInterval is 30 seconds")
    func checkInterval() {
        #expect(AutoPushService.checkInterval == 30)
    }

    @MainActor
    @Test("shared instance is singleton")
    func sharedSingleton() {
        #expect(AutoPushService.shared === AutoPushService.shared)
    }

    @MainActor
    @Test("PushStatus equatable works correctly")
    func pushStatusEquatable() {
        #expect(AutoPushService.PushStatus.idle == .idle)
        #expect(AutoPushService.PushStatus.pushing == .pushing)
        #expect(AutoPushService.PushStatus.success == .success)
        #expect(AutoPushService.PushStatus.failed("error") == .failed("error"))
        #expect(AutoPushService.PushStatus.failed("error1") != AutoPushService.PushStatus.failed("error2"))
    }

    @MainActor
    @Test("initial state is idle and not pushing")
    func initialState() {
        let service = AutoPushService.shared
        // Reset state from previous tests
        service.stopTimer()

        #expect(service.isPushing == false)
        #expect(service.lastPushStatus == .idle)
        #expect(service.isTimerRunning == false)
    }

    @MainActor
    @Test("startTimer starts timer and sets isTimerRunning to true")
    func startTimerBehavior() async {
        let service = AutoPushService.shared
        service.register {
            AutoPushProjectSnapshot(
                projectPath: "/tmp/fake",
                projectTitle: "Fake",
                branchName: "main",
                isGitRepository: true
            )
        }

        service.startTimer()
        #expect(service.isTimerRunning == true)

        // Stop timer to clean up
        service.stopTimer()
        #expect(service.isTimerRunning == false)
    }

    @MainActor
    @Test("stopTimer stops timer and sets isTimerRunning to false")
    func stopTimerBehavior() {
        let service = AutoPushService.shared
        service.register {
            AutoPushProjectSnapshot(
                projectPath: "/tmp/fake",
                projectTitle: "Fake",
                branchName: "main",
                isGitRepository: true
            )
        }

        service.startTimer()
        service.stopTimer()
        #expect(service.isTimerRunning == false)
    }

    @MainActor
    @Test("checkAndAutoPushForCurrentProject returns early when no project registered")
    func checkAndAutoPushForCurrentProjectEarlyReturn() async {
        let service = AutoPushService.shared
        // Register a provider that returns nil
        service.register { nil }

        await service.checkAndAutoPushForCurrentProject()

        // Should not crash and status should remain idle
        #expect(service.lastPushStatus == .idle)
        #expect(service.isPushing == false)
    }

    @MainActor
    @Test("AutoPushProjectSnapshot equatable works correctly")
    func projectSnapshotEquatable() {
        let snapshot1 = AutoPushProjectSnapshot(
            projectPath: "/path/to/repo",
            projectTitle: "MyRepo",
            branchName: "main",
            isGitRepository: true
        )
        let snapshot2 = AutoPushProjectSnapshot(
            projectPath: "/path/to/repo",
            projectTitle: "MyRepo",
            branchName: "main",
            isGitRepository: true
        )
        let snapshot3 = AutoPushProjectSnapshot(
            projectPath: "/path/to/other",
            projectTitle: "OtherRepo",
            branchName: "dev",
            isGitRepository: true
        )

        #expect(snapshot1 == snapshot2)
        #expect(snapshot1 != snapshot3)
    }

    @MainActor
    @Test("AutoPushProjectSnapshot with nil branchName is still equatable")
    func projectSnapshotWithNilBranch() {
        let snapshot1 = AutoPushProjectSnapshot(
            projectPath: "/path/to/repo",
            projectTitle: "MyRepo",
            branchName: nil,
            isGitRepository: false
        )
        let snapshot2 = AutoPushProjectSnapshot(
            projectPath: "/path/to/repo",
            projectTitle: "MyRepo",
            branchName: nil,
            isGitRepository: false
        )

        #expect(snapshot1 == snapshot2)
    }
}

@Suite("AutoPushSettingsStore")
struct AutoPushSettingsStoreTests {
    @MainActor
    @Test("shared instance is singleton")
    func sharedSingleton() {
        #expect(AutoPushSettingsStore.shared === AutoPushSettingsStore.shared)
    }

    @MainActor
    @Test("isAutoPushEnabled returns false when config does not exist")
    func isAutoPushEnabledWhenConfigDoesNotExist() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settingsFileURL = tempDir.appendingPathComponent("settings.json")
        let store = AutoPushSettingsStore(settingsFileURL: settingsFileURL)

        #expect(store.isAutoPushEnabled(for: "/path/to/repo", branchName: "main") == false)
    }

    @MainActor
    @Test("setAutoPushEnabled updates settings and publishes changes")
    func setAutoPushEnabledUpdatesSettings() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settingsFileURL = tempDir.appendingPathComponent("settings.json")
        let store = AutoPushSettingsStore(settingsFileURL: settingsFileURL)

        var publishedCount = 0
        let cancellable = store.$settings.sink { _ in publishedCount += 1 }

        #expect(store.isAutoPushEnabled(for: "/path/to/repo", branchName: "main") == false)

        store.setAutoPushEnabled(for: "/path/to/repo", branchName: "main", enabled: true)

        #expect(store.isAutoPushEnabled(for: "/path/to/repo", branchName: "main") == true)
        #expect(publishedCount >= 1)

        cancellable.cancel()
    }

    @MainActor
    @Test("updateLastPushedDate updates lastPushedAt field")
    func updateLastPushedDateUpdatesField() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settingsFileURL = tempDir.appendingPathComponent("settings.json")
        let store = AutoPushSettingsStore(settingsFileURL: settingsFileURL)

        store.setAutoPushEnabled(for: "/path/to/repo", branchName: "main", enabled: true)

        let beforeUpdate = store.settings["/path/to/repo://main"]
        #expect(beforeUpdate?.lastPushedAt == nil)

        let pushedAt = Date()
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        store.updateLastPushedDate(for: "/path/to/repo", branchName: "main")

        let afterUpdate = store.settings["/path/to/repo://main"]
        #expect(afterUpdate?.lastPushedAt != nil)
        let actualPushedAt = afterUpdate?.lastPushedAt!
        #expect(actualPushedAt! > pushedAt)
    }

    @MainActor
    @Test("removeConfig removes configuration")
    func removeConfigRemovesConfiguration() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settingsFileURL = tempDir.appendingPathComponent("settings.json")
        let store = AutoPushSettingsStore(settingsFileURL: settingsFileURL)

        store.setAutoPushEnabled(for: "/path/to/repo", branchName: "main", enabled: true)
        #expect(store.isAutoPushEnabled(for: "/path/to/repo", branchName: "main") == true)

        store.removeConfig(for: "/path/to/repo", branchName: "main")
        #expect(store.isAutoPushEnabled(for: "/path/to/repo", branchName: "main") == false)
        #expect(store.settings["/path/to/repo://main"] == nil)
    }

    @MainActor
    @Test("settings are persisted to disk")
    func settingsArePersistedToDisk() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settingsFileURL = tempDir.appendingPathComponent("settings.json")

        // Create first store and add config
        let store1 = AutoPushSettingsStore(settingsFileURL: settingsFileURL)
        store1.setAutoPushEnabled(for: "/path/to/repo", branchName: "main", enabled: true)
        #expect(store1.isAutoPushEnabled(for: "/path/to/repo", branchName: "main") == true)

        // Create second store with same file path
        let store2 = AutoPushSettingsStore(settingsFileURL: settingsFileURL)
        #expect(store2.isAutoPushEnabled(for: "/path/to/repo", branchName: "main") == true)
    }

    @MainActor
    @Test("multiple configs can be stored independently")
    func multipleConfigsStoredIndependently() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let settingsFileURL = tempDir.appendingPathComponent("settings.json")
        let store = AutoPushSettingsStore(settingsFileURL: settingsFileURL)

        store.setAutoPushEnabled(for: "/path/to/repo-a", branchName: "main", enabled: true)
        store.setAutoPushEnabled(for: "/path/to/repo-a", branchName: "dev", enabled: false)
        store.setAutoPushEnabled(for: "/path/to/repo-b", branchName: "main", enabled: true)

        #expect(store.isAutoPushEnabled(for: "/path/to/repo-a", branchName: "main") == true)
        #expect(store.isAutoPushEnabled(for: "/path/to/repo-a", branchName: "dev") == false)
        #expect(store.isAutoPushEnabled(for: "/path/to/repo-b", branchName: "main") == true)

        store.removeConfig(for: "/path/to/repo-a", branchName: "main")
        #expect(store.isAutoPushEnabled(for: "/path/to/repo-a", branchName: "main") == false)
        #expect(store.isAutoPushEnabled(for: "/path/to/repo-b", branchName: "main") == true)
    }
}
