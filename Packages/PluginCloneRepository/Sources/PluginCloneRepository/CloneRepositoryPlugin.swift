import Foundation
import KernelCore
import KitGit
import KitLocalization
import KitSuperLog
import LumiUI
import os
import ProviderActivity
import ProviderCloneRepository
import ProviderContentView
import ProviderGit
import ProviderProjects
import ProviderStorage
import ProviderToast
import SwiftUI

private func cloneLocalized(_ key: String) -> String {
    LumiLocalization.string(key, bundle: .module)
}

@MainActor
public final class CloneRepositoryPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.clone-repository", category: "CloneRepository")
    nonisolated public static let emoji = "📥"
    nonisolated static let verbose = false

    public let id = "com.coffic.gitok.plugin.clone-repository"
    /// 先注册任务 Provider；ProjectsPlugin 会在自己的 onBoot 中解析它。
    public let order = -10
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.clone-repository",
        name: "Clone Repository",
        description: "Runs clone jobs in the background and keeps their progress available",
        category: .project,
        stage: .stable,
        policy: .required
    )

    private var service: CloneRepositoryService?

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let git = kernel.resolveProvider((any GitProviding).self) else {
            Self.logger.error("GitProviding is not registered; clone tasks are unavailable")
            return
        }
        guard let storage = kernel.resolveProvider((any StorageProviding).self) else {
            Self.logger.error("StorageProviding is not registered; clone tasks are unavailable")
            return
        }

        let directory = storage.pluginDataDirectory(for: id)
        let service = CloneRepositoryService(
            git: git,
            storeURL: directory.appendingPathComponent("clone-tasks.json"),
            activity: kernel.resolveProvider((any ActivityProviding).self),
            toast: kernel.resolveProvider((any ToastProviding).self)
        )
        self.service = service
        try kernel.registerProvider((any CloneRepositoryProviding).self, service)
    }

    public func onReady(kernel: KernelCoreContainer) throws {
        guard let service else { return }
        guard let projects = kernel.resolveProvider((any ProjectProviding).self) else {
            Self.logger.error("ProjectProviding is not registered; clone project rows are unavailable")
            return
        }

        // 任务先于仓库目录存在：将未完成和失败任务重新挂回项目列表，
        // 让用户可以点击项目查看完整任务快照。
        for task in service.tasks where task.status != .completed {
            projects.addProject(at: task.destination)
        }
        service.onTaskFinished = { [weak projects] _ in
            projects?.notifyDataChanged()
        }

        guard let contentView = kernel.resolveProvider((any ContentViewProviding).self) else {
            Self.logger.error("ContentViewProviding is not registered; clone detail is unavailable")
            return
        }
        contentView.addContentView(
            AnyView(
                CloneRepositoryDetailView(
                    projects: projects,
                    cloneRepository: service
                )
            ),
            id: "\(id).content",
            order: 0
        )
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        service?.shutdown()
        service?.onTaskFinished = nil
        service = nil
        kernel.unregisterProvider((any CloneRepositoryProviding).self)
        kernel.resolveProvider((any ContentViewProviding).self)?
            .removeContentView(id: "\(id).content")
    }
}

// MARK: - Provider implementation

@MainActor
private final class CloneRepositoryService: CloneRepositoryProviding {
    private struct Store: Codable {
        var tasks: [CloneTask]
    }

    private final class ObserverHandle: CloneRepositoryObserverHandle {
        private var callback: ((CloneRepositoryEvent) -> Void)?
        private weak var owner: CloneRepositoryService?

        init(owner: CloneRepositoryService, callback: @escaping (CloneRepositoryEvent) -> Void) {
            self.owner = owner
            self.callback = callback
        }

        func cancel() {
            guard callback != nil else { return }
            callback = nil
            owner?.removeObserver(self)
        }

        func invoke(_ event: CloneRepositoryEvent) {
            callback?(event)
        }

        var isCancelled: Bool { callback == nil }
    }

    private let git: any GitProviding
    private let storeURL: URL
    private let activity: (any ActivityProviding)?
    private let toast: (any ToastProviding)?
    private var taskStore: [UUID: CloneTask] = [:]
    private var observers: [ObserverHandle] = []
    private var workers: [UUID: Task<URL, Error>] = [:]
    private var cancellations: [UUID: GitProcessCancellation] = [:]
    private var destinationExistedBeforeTask: [UUID: Bool] = [:]
    private var lastPersistAt = Date.distantPast

    var onTaskFinished: ((CloneTask) -> Void)?

    init(
        git: any GitProviding,
        storeURL: URL,
        activity: (any ActivityProviding)?,
        toast: (any ToastProviding)?
    ) {
        self.git = git
        self.storeURL = storeURL
        self.activity = activity
        self.toast = toast
        load()
    }

    var tasks: [CloneTask] {
        taskStore.values.sorted {
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    func task(for destination: URL) -> CloneTask? {
        let standardized = destination.standardizedFileURL
        return tasks.first { $0.destination.standardizedFileURL == standardized }
    }

    func enqueue(remoteURL: String, destination: URL, repositoryName: String) throws -> CloneTask {
        if let existing = task(for: destination), existing.status.isActive {
            throw CloneRepositoryError.taskAlreadyExists(destination: destination)
        }

        let task = CloneTask(
            remoteURL: remoteURL,
            destination: destination.standardizedFileURL,
            repositoryName: repositoryName
        )
        taskStore[task.id] = task
        destinationExistedBeforeTask[task.id] = FileManager.default.fileExists(atPath: task.destination.path)
        persist()
        notify(.tasksChanged)
        start(taskID: task.id)
        return taskStore[task.id] ?? task
    }

    func cancel(taskID: UUID) {
        guard var task = taskStore[taskID], task.status.isActive else { return }
        task.status = .cancelling
        task.updatedAt = Date()
        task.detail = cloneLocalized("Cancelling")
        taskStore[taskID] = task
        persist()
        notify(.taskUpdated(taskID))
        cancellations[taskID]?.cancel()
    }

    func retry(taskID: UUID) throws -> CloneTask {
        guard var task = taskStore[taskID] else {
            throw CloneRepositoryError.taskNotFound(taskID)
        }
        guard task.status == .failed || task.status == .cancelled else {
            throw CloneRepositoryError.invalidRetryStatus(task.status)
        }
        try git.validateCloneDestination(task.destination)
        task.status = .queued
        task.phase = nil
        task.fractionCompleted = nil
        task.detail = nil
        task.errorMessage = nil
        task.updatedAt = Date()
        task.startedAt = nil
        task.finishedAt = nil
        taskStore[taskID] = task
        destinationExistedBeforeTask[taskID] = FileManager.default.fileExists(atPath: task.destination.path)
        persist()
        notify(.taskUpdated(taskID))
        start(taskID: taskID)
        return taskStore[taskID] ?? task
    }

    @discardableResult
    func addObserver(_ callback: @escaping (CloneRepositoryEvent) -> Void) -> any CloneRepositoryObserverHandle {
        let handle = ObserverHandle(owner: self, callback: callback)
        observers.append(handle)
        return handle
    }

    func shutdown() {
        for cancellation in cancellations.values { cancellation.cancel() }
        workers.removeAll()
        cancellations.removeAll()
        persist()
        activity?.clearActivity()
    }

    private func start(taskID: UUID) {
        guard var task = taskStore[taskID], task.status == .queued else { return }
        let cancellation = GitProcessCancellation()
        cancellations[taskID] = cancellation
        task.status = .cloning
        task.phase = .preparing
        task.startedAt = Date()
        task.updatedAt = Date()
        task.detail = cloneLocalized("Preparing clone...")
        taskStore[taskID] = task
        persist()
        notify(.taskUpdated(taskID))
        updateActivity(for: task)

        let remoteURL = task.remoteURL
        let destination = task.destination
        let cloneGit = git
        let (stream, continuation) = AsyncStream<GitCloneProgress>.makeStream()
        let worker = Task.detached(priority: .userInitiated) {
            defer { continuation.finish() }
            return try cloneGit.clone(
                remoteURL: remoteURL,
                destination: destination,
                progress: { progress in continuation.yield(progress) },
                cancellation: cancellation
            )
        }
        workers[taskID] = worker

        Task { [weak self] in
            guard let self else { return }
            for await progress in stream {
                self.updateProgress(taskID: taskID, progress: progress)
            }

            do {
                _ = try await worker.value
                self.complete(taskID: taskID)
            } catch is CancellationError {
                self.finishCancellation(taskID: taskID)
            } catch {
                if cancellation.isCancelled {
                    self.finishCancellation(taskID: taskID)
                } else {
                    self.fail(taskID: taskID, error: error)
                }
            }
        }
    }

    private func updateProgress(taskID: UUID, progress: GitCloneProgress) {
        guard var task = taskStore[taskID] else { return }
        task.phase = CloneTaskPhase(rawValue: progress.phase.rawValue)
        task.fractionCompleted = progress.fractionCompleted
        task.detail = progress.detail
        task.updatedAt = Date()
        taskStore[taskID] = task
        if Date().timeIntervalSince(lastPersistAt) >= 0.25 {
            persist()
        }
        notify(.taskUpdated(taskID))
        updateActivity(for: task)
    }

    private func complete(taskID: UUID) {
        guard var task = taskStore[taskID] else { return }
        task.status = .completed
        task.phase = .completed
        task.fractionCompleted = 1
        task.detail = cloneLocalized("Completed")
        task.errorMessage = nil
        task.updatedAt = Date()
        task.finishedAt = Date()
        taskStore[taskID] = task
        cleanupWorker(taskID: taskID)
        persist()
        notify(.taskUpdated(taskID))
        toast?.show(cloneLocalized("Clone completed"), detail: task.repositoryName, style: .success)
        onTaskFinished?(task)
        clearActivityIfIdle()
    }

    private func finishCancellation(taskID: UUID) {
        guard var task = taskStore[taskID] else { return }
        task.status = .cancelled
        task.detail = cloneLocalized("Clone cancelled")
        task.updatedAt = Date()
        task.finishedAt = Date()
        taskStore[taskID] = task
        cleanupPartialDestination(taskID: taskID)
        cleanupWorker(taskID: taskID)
        persist()
        notify(.taskUpdated(taskID))
        toast?.show(cloneLocalized("Clone cancelled"), detail: task.repositoryName, style: .info)
        onTaskFinished?(task)
        clearActivityIfIdle()
    }

    private func fail(taskID: UUID, error: Error) {
        guard var task = taskStore[taskID] else { return }
        task.status = .failed
        task.detail = cloneLocalized("Clone failed")
        task.errorMessage = error.localizedDescription
        task.updatedAt = Date()
        task.finishedAt = Date()
        taskStore[taskID] = task
        cleanupPartialDestination(taskID: taskID)
        cleanupWorker(taskID: taskID)
        persist()
        notify(.taskUpdated(taskID))
        toast?.show(cloneLocalized("Clone failed"), detail: task.repositoryName, style: .error)
        onTaskFinished?(task)
        clearActivityIfIdle()
    }

    private func cleanupWorker(taskID: UUID) {
        workers.removeValue(forKey: taskID)
        cancellations.removeValue(forKey: taskID)
        destinationExistedBeforeTask.removeValue(forKey: taskID)
    }

    private func cleanupPartialDestination(taskID: UUID) {
        guard let task = taskStore[taskID],
              FileManager.default.fileExists(atPath: task.destination.path) else { return }
        let existedBefore = destinationExistedBeforeTask[taskID] ?? false
        if existedBefore {
            try? FileManager.default.removeItem(at: task.destination)
            try? FileManager.default.createDirectory(at: task.destination, withIntermediateDirectories: true)
        } else {
            try? FileManager.default.removeItem(at: task.destination)
        }
    }

    private func updateActivity(for task: CloneTask) {
        activity?.setActivity(task.detail ?? "Cloning \(task.repositoryName)...")
    }

    private func clearActivityIfIdle() {
        guard !taskStore.values.contains(where: { $0.status.isActive }) else { return }
        activity?.clearActivity()
    }

    private func notify(_ event: CloneRepositoryEvent) {
        observers.removeAll { $0.isCancelled }
        for observer in observers { observer.invoke(event) }
    }

    private func removeObserver(_ handle: ObserverHandle) {
        observers.removeAll { $0 === handle }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let store = try? JSONDecoder().decode(Store.self, from: data) else { return }
        let interruptionMessage = "Clone was interrupted when GitOK closed."
        for var task in store.tasks {
            if task.status.isActive {
                task.status = .failed
                task.detail = "Clone interrupted"
                task.errorMessage = interruptionMessage
                task.updatedAt = Date()
                task.finishedAt = Date()
            }
            taskStore[task.id] = task
        }
        persist()
    }

    private func persist() {
        let store = Store(tasks: tasks)
        guard let data = try? JSONEncoder().encode(store) else { return }
        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: storeURL, options: .atomic)
            lastPersistAt = Date()
        } catch {
            CloneRepositoryPlugin.logger.error("Failed to persist clone tasks: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - Detail view

@MainActor
private final class CloneRepositoryObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any CloneRepositoryObserverHandle)?

    init(cloneRepository: any CloneRepositoryProviding) {
        handle = cloneRepository.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}

private struct CloneRepositoryDetailView: View {
    let projects: any ProjectProviding
    let cloneRepository: any CloneRepositoryProviding
    @StateObject private var observation: CloneRepositoryObservationModel
    @State private var retryError: String?
    @LumiTheme private var theme

    init(projects: any ProjectProviding, cloneRepository: any CloneRepositoryProviding) {
        self.projects = projects
        self.cloneRepository = cloneRepository
        _observation = StateObject(wrappedValue: CloneRepositoryObservationModel(cloneRepository: cloneRepository))
    }

    private var task: CloneTask? {
        _ = observation.revision
        guard let project = projects.currentProject else { return nil }
        return cloneRepository.task(for: project.url)
    }

    var body: some View {
        Group {
            if let task, task.status != .completed {
                ScrollView(.vertical, showsIndicators: false) {
                    detail(task)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.surface)
            } else {
                EmptyView()
            }
        }
    }

    private func detail(_ task: CloneTask) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: task.status.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(task.status.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.status.title)
                        .font(.title3.weight(.semibold))
                    Text(task.repositoryName)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                if task.status.isActive {
                    ProgressView().controlSize(.small)
                }
            }

            if let fraction = task.fractionCompleted {
                ProgressView(value: fraction)
                Text("\(Int(fraction * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(theme.textSecondary)
            } else if task.status.isActive {
                ProgressView()
            }

            if let detail = task.detail, !detail.isEmpty {
                infoRow(cloneLocalized("Current operation"), detail)
            }
            infoRow(cloneLocalized("Remote"), task.remoteURL)
            infoRow(cloneLocalized("Destination"), task.destination.path)
            if let startedAt = task.startedAt {
                infoRow(cloneLocalized("Started"), startedAt.formatted(date: .abbreviated, time: .standard))
            }
            if let updatedAt = Optional(task.updatedAt) {
                infoRow(cloneLocalized("Last update"), updatedAt.formatted(date: .abbreviated, time: .standard))
            }

            if let error = task.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.red)
                    .textSelection(.enabled)
            }
            if let retryError {
                Text(retryError)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }

            HStack {
                if task.status.isActive {
                    Button(cloneLocalized("Cancel")) { cloneRepository.cancel(taskID: task.id) }
                        .buttonStyle(.bordered)
                } else if task.status == .failed || task.status == .cancelled {
                    Button(cloneLocalized("Retry")) {
                        do {
                            _ = try cloneRepository.retry(taskID: task.id)
                            retryError = nil
                        } catch {
                            retryError = error.localizedDescription
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
            Text(value)
                .font(.callout)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension CloneTaskStatus {
    var title: String {
        switch self {
        case .queued: cloneLocalized("Queued")
        case .cloning: cloneLocalized("Cloning")
        case .cancelling: cloneLocalized("Cancelling")
        case .completed: cloneLocalized("Completed")
        case .failed: cloneLocalized("Clone failed")
        case .cancelled: cloneLocalized("Clone cancelled")
        }
    }

    var icon: String {
        switch self {
        case .queued, .cloning, .cancelling: "arrow.down.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .queued, .cloning, .cancelling: .blue
        case .completed: .green
        case .failed: .red
        case .cancelled: .orange
        }
    }
}
