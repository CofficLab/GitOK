import Foundation
import KernelCore
import KitGit
import ProviderActivity
import ProviderCloneRepository
import ProviderGit
import ProviderProjects
import ProviderStorage
import ProviderToast
import Testing
@testable import PluginCloneRepository

/// 覆盖 `CloneRepositoryService` 的核心状态机：
/// 入队 / 取消 / 重试、观察者广播、持久化与重启恢复，以及
/// 「外部已完成」的任务对账。
@MainActor
@Suite("PluginCloneRepository 克隆任务服务")
struct CloneRepositoryServiceTests {

    // MARK: - Helpers

    @MainActor
    private struct Harness {
        let kernel: KernelCoreContainer
        let git: CloneRepositoryTestGit
        let storage: CloneRepositoryTestStorage
        let toast: CloneRepositoryTestToast
        let root: URL
        let destination: URL

        var service: any CloneRepositoryProviding {
            kernel.resolveProvider((any CloneRepositoryProviding).self)!
        }
    }

    private func makeHarness(
        withGit: Bool = true,
        withStorage: Bool = true,
        withToast: Bool = true
    ) throws -> Harness {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("GitOKCloneTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let kernel = KernelCoreContainer()
        let git = CloneRepositoryTestGit()
        let storage = CloneRepositoryTestStorage(dataRootDirectory: root)
        let toast = CloneRepositoryTestToast()

        if withGit {
            try kernel.registerProvider((any GitProviding).self, git)
        }
        if withStorage {
            try kernel.registerProvider((any StorageProviding).self, storage)
        }
        if withToast {
            try kernel.registerProvider((any ToastProviding).self, toast)
        }
        try kernel.registerProvider((any ActivityProviding).self, DefaultActivityProvider())

        return Harness(
            kernel: kernel,
            git: git,
            storage: storage,
            toast: toast,
            root: root,
            destination: root.appendingPathComponent("cloned", isDirectory: true)
        )
    }

    private func cleanUp(_ harness: Harness) {
        try? FileManager.default.removeItem(at: harness.root)
    }

    /// 等待某个条件成立；克隆 worker 在后台线程执行，这里用轮询避免时序抖动。
    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }

    // MARK: - 插件接线

    @Test("缺少 GitProviding 时不注册克隆 Provider")
    func onBootWithoutGitDoesNotRegisterProvider() throws {
        let harness = try makeHarness(withGit: false)
        defer { cleanUp(harness) }

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any CloneRepositoryProviding).self) == nil)
    }

    @Test("缺少 StorageProviding 时不注册克隆 Provider")
    func onBootWithoutStorageDoesNotRegisterProvider() throws {
        let harness = try makeHarness(withStorage: false)
        defer { cleanUp(harness) }

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any CloneRepositoryProviding).self) == nil)
    }

    @Test("onBoot 注册克隆 Provider")
    func onBootRegistersProvider() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any CloneRepositoryProviding).self) != nil)
    }

    @Test("onShutdown 撤回克隆 Provider")
    func onShutdownUnregistersProvider() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        try plugin.onShutdown(kernel: harness.kernel)

        #expect(harness.kernel.resolveProvider((any CloneRepositoryProviding).self) == nil)
    }

    // MARK: - 入队

    @Test("入队后任务立即进入克隆中状态")
    func enqueueStartsCloning() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        #expect(task.status == .cloning)
        #expect(task.phase == .preparing)
        #expect(task.repositoryName == "repo")
        #expect(task.destination == harness.destination.standardizedFileURL)
        #expect(service.tasks.count == 1)

        harness.git.releaseClone()
    }

    @Test("同一目标目录重复入队会被拒绝")
    func enqueueTwiceForSameDestinationThrows() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        #expect(throws: CloneRepositoryError.self) {
            _ = try service.enqueue(
                remoteURL: "https://example.com/repo.git",
                destination: harness.destination,
                repositoryName: "repo"
            )
        }

        harness.git.releaseClone()
    }

    @Test("按目标目录查询任务")
    func taskLookupByDestination() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        #expect(service.task(for: harness.destination)?.id == task.id)
        #expect(service.isCloning(for: harness.destination))
        #expect(service.task(for: harness.root.appendingPathComponent("missing")) == nil)
        #expect(service.isCloning(for: harness.root.appendingPathComponent("missing")) == false)

        harness.git.releaseClone()
    }

    // MARK: - 取消

    @Test("取消进行中的任务会切换到取消中状态")
    func cancelMarksTaskCancelling() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        service.cancel(taskID: task.id)

        #expect(service.task(for: harness.destination)?.status == .cancelling)

        harness.git.releaseClone()
    }

    @Test("取消未知任务是无副作用的空操作")
    func cancelUnknownTaskIsNoOp() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        service.cancel(taskID: UUID())

        #expect(service.tasks.isEmpty)
    }

    @Test("取消进行中的任务最终落到已取消状态")
    func cancellingTaskFinishesAsCancelled() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        service.cancel(taskID: task.id)

        let settled = await waitUntil {
            service.task(for: harness.destination)?.status == .cancelled
        }

        #expect(settled)
        #expect(service.task(for: harness.destination)?.status == .cancelled)
    }

    // MARK: - 重试

    @Test("重试不存在的任务会抛出")
    func retryUnknownTaskThrows() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        #expect(throws: CloneRepositoryError.self) {
            _ = try service.retry(taskID: UUID())
        }
    }

    @Test("重试进行中的任务会被拒绝")
    func retryActiveTaskThrows() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        #expect(throws: CloneRepositoryError.self) {
            _ = try service.retry(taskID: task.id)
        }

        harness.git.releaseClone()
    }

    @Test("重试失败的任务会重新进入队列")
    func retryFailedTaskRestartsClone() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)
        harness.git.cloneError = CloneRepositoryTestError("boom")

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        harness.git.releaseClone()

        let failed = await waitUntil {
            service.task(for: harness.destination)?.status == .failed
        }
        #expect(failed)

        // 清除失败原因后重试：任务应重新排队并再次进入克隆中状态。
        harness.git.cloneError = nil
        harness.git.cloneGate = DispatchSemaphore(value: 0)
        let retried = try service.retry(taskID: task.id)

        #expect(retried.status == .cloning)
        #expect(retried.errorMessage == nil)
        #expect(retried.phase == .preparing)

        harness.git.releaseClone()
    }

    @Test("目标目录校验失败时不会重试")
    func retryValidatesDestination() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)
        harness.git.cloneError = CloneRepositoryTestError("boom")

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        harness.git.releaseClone()

        #expect(throws: (any Error).self) {
            _ = try service.retry(taskID: task.id)
        }

        harness.git.releaseClone()
    }

    // MARK: - 观察者

    @Test("入队与取消都会广播事件")
    func observerReceivesEvents() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        var events: [CloneRepositoryEvent] = []
        let handle = service.addObserver { events.append($0) }
        defer { handle.cancel() }

        let task = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        service.cancel(taskID: task.id)

        #expect(events.contains { if case .tasksChanged = $0 { true } else { false } })
        #expect(events.contains { if case .taskUpdated(let id) = $0 { id == task.id } else { false } })

        harness.git.releaseClone()
    }

    @Test("取消订阅后不再收到事件")
    func cancelledObserverStopsReceivingEvents() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        var count = 0
        let handle = service.addObserver { _ in count += 1 }
        handle.cancel()

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        #expect(count == 0)

        harness.git.releaseClone()
    }

    // MARK: - 结果收敛

    @Test("克隆成功后任务落到已完成并弹出成功提示")
    func successfulCloneCompletesTask() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        harness.git.releaseClone()

        let completed = await waitUntil {
            service.task(for: harness.destination)?.status == .completed
        }

        #expect(completed)
        let task = service.task(for: harness.destination)
        #expect(task?.phase == .completed)
        #expect(task?.fractionCompleted == 1)
        #expect(task?.errorMessage == nil)
        #expect(task?.finishedAt != nil)
        #expect(harness.toast.toasts.count == 1)
        #expect(harness.toast.toasts.first?.style == .success)
    }

    @Test("克隆失败后任务落到已失败并记录错误信息")
    func failedCloneMarksTaskFailed() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)
        harness.git.cloneError = CloneRepositoryTestError("network unreachable")

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        harness.git.releaseClone()

        let failed = await waitUntil {
            service.task(for: harness.destination)?.status == .failed
        }

        #expect(failed)
        #expect(service.task(for: harness.destination)?.errorMessage == "network unreachable")
        #expect(harness.toast.toasts.first?.style == .error)
    }

    // MARK: - 持久化与恢复

    @Test("任务会持久化到插件数据目录")
    func tasksArePersisted() throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        let storeURL = harness.storage.pluginDataDirectory(for: plugin.id)
            .appendingPathComponent("clone-tasks.json")
        #expect(FileManager.default.fileExists(atPath: storeURL.path))

        harness.git.releaseClone()
    }

    @Test("重启后仍在进行中的任务会被标记为中断失败")
    func interruptedTaskIsFailedAfterReload() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        _ = try harness.service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        try plugin.onShutdown(kernel: harness.kernel)

        // 重新启动插件：持久化在磁盘上的进行中任务应被标记为中断。
        let restarted = CloneRepositoryPlugin()
        try restarted.onBoot(kernel: harness.kernel)
        let service = harness.service

        let task = service.task(for: harness.destination)
        #expect(task?.status == .failed)
        #expect(task?.detail == "Clone interrupted")
        #expect(task?.errorMessage == "Clone was interrupted when GitOK closed.")

        harness.git.releaseClone()
    }

    // MARK: - 外部完成对账

    @Test("远端匹配时失败任务会被对账为已完成")
    func failedTaskIsReconciledWhenRemoteMatches() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)
        harness.git.cloneError = CloneRepositoryTestError("boom")

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        harness.git.releaseClone()

        let failed = await waitUntil {
            service.task(for: harness.destination)?.status == .failed
        }
        #expect(failed)

        // 目标目录里已经出现了同名远端：任务应被对账为已完成。
        harness.git.remotes = [
            GitRemoteSummary(name: "origin", url: "https://example.com/repo", fetchURL: nil, pushURL: nil),
        ]
        let reconciled = service.task(for: harness.destination)

        #expect(reconciled?.status == .completed)
        #expect(reconciled?.phase == .completed)
        #expect(reconciled?.errorMessage == nil)
    }

    @Test("远端不匹配时失败任务保持失败")
    func failedTaskIsNotReconciledWhenRemoteDiffers() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }
        harness.git.cloneGate = DispatchSemaphore(value: 0)
        harness.git.cloneError = CloneRepositoryTestError("boom")

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        harness.git.releaseClone()

        let failed = await waitUntil {
            service.task(for: harness.destination)?.status == .failed
        }
        #expect(failed)

        harness.git.remotes = [
            GitRemoteSummary(name: "origin", url: "https://example.com/other", fetchURL: nil, pushURL: nil),
        ]
        let reconciled = service.task(for: harness.destination)

        #expect(reconciled?.status == .failed)
    }

    // MARK: - 目标目录安全

    @Test("克隆失败到已存在的非空目录时不得删除用户文件")
    func failingCloneKeepsExistingDestinationContent() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        // 目标目录已存在，且里面有用户自己的文件。
        try FileManager.default.createDirectory(at: harness.destination, withIntermediateDirectories: true)
        let userFile = harness.destination.appendingPathComponent("keep-me.txt")
        try Data("user data\n".utf8).write(to: userFile)

        harness.git.cloneGate = DispatchSemaphore(value: 0)
        harness.git.cloneError = CloneRepositoryTestError("boom")

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )
        harness.git.releaseClone()

        let failed = await waitUntil {
            service.task(for: harness.destination)?.status == .failed
        }
        #expect(failed)

        #expect(
            FileManager.default.fileExists(atPath: userFile.path),
            "克隆失败到已存在的非空目录时，不得删除用户已有的文件"
        )
        #expect(
            try String(contentsOf: userFile, encoding: .utf8) == "user data\n",
            "用户已有文件的内容不得被克隆失败清理破坏"
        )
    }

    @Test("克隆失败到克隆前新建的空目录时应清空克隆残留")
    func failingCloneCleansUpNewlyCreatedDestination() async throws {
        let harness = try makeHarness()
        defer { cleanUp(harness) }

        harness.git.cloneGate = DispatchSemaphore(value: 0)
        harness.git.cloneError = CloneRepositoryTestError("boom")

        let plugin = CloneRepositoryPlugin()
        try plugin.onBoot(kernel: harness.kernel)
        let service = harness.service

        _ = try service.enqueue(
            remoteURL: "https://example.com/repo.git",
            destination: harness.destination,
            repositoryName: "repo"
        )

        // 模拟克隆写了一半：目标目录被创建并留下残留文件。
        try FileManager.default.createDirectory(at: harness.destination, withIntermediateDirectories: true)
        try Data("partial\n".utf8).write(to: harness.destination.appendingPathComponent("partial.txt"))

        harness.git.releaseClone()

        let failed = await waitUntil {
            service.task(for: harness.destination)?.status == .failed
        }
        #expect(failed)

        #expect(
            !FileManager.default.fileExists(atPath: harness.destination.appendingPathComponent("partial.txt").path),
            "克隆失败后应清理由克隆产生的残留文件"
        )
    }
}
