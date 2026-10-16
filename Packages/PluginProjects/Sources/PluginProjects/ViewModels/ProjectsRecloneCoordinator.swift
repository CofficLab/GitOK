import Foundation
import OSLog
import ProviderCloneRepository
import ProviderProjects

/// Re-clone 异步工作流的状态机。
///
/// 「重新克隆」是一条跨越多分钟的链路：校验目标 → 后台克隆到临时目录 →
/// 轮询任务 → 原子替换项目目录 → 失败时回滚。原实现把这些状态散落在视图的
/// `@State` 里，视图重建即丢失，且无法脱离 SwiftUI 测试。
///
/// 协调器持有全部状态并自行轮询，视图只负责把 `state` 渲染成 alert。
@MainActor
@Observable
final class ProjectsRecloneCoordinator {
    /// 对外可观察的状态，供视图驱动 alert 展示。
    enum State: Equatable {
        /// 空闲，无 re-clone 进行中。
        case idle
        /// 已解析出 remote，等待用户确认 destructive 操作。
        case confirming(project: Project, remoteURL: String)
        /// 已入队后台克隆，正在轮询进度。
        case running(taskID: UUID)
        /// 轮询到失败或取消，附带可展示的错误信息。
        case failed(message: String)
    }

    private(set) var state: State = .idle

    /// 轮询间隔。克隆是 IO 密集操作，250ms 足够跟手又不至于刷爆主线程。
    private static let pollInterval = Duration.milliseconds(250)

    private let git: any GitRemoteCapability
    private let clone: any ProjectCloneCapability
    private let onProjectReplaced: @MainActor () -> Void
    private let log = Logger(subsystem: "com.coffic.gitok.plugin.projects", category: "Reclone")

    /// 当前批次的目标目录；替换阶段需要它。
    private var temporaryDestination: URL?
    /// 当前批次的项目；替换阶段需要它。
    private var targetProject: Project?

    init(
        git: any GitRemoteCapability,
        clone: any ProjectCloneCapability,
        onProjectReplaced: @escaping @MainActor () -> Void = {}
    ) {
        self.git = git
        self.clone = clone
        self.onProjectReplaced = onProjectReplaced
    }

    /// 是否有 re-clone 正在进行（用于禁用菜单项）。
    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    // MARK: - Flow

    /// 第一步：解析项目的 remote，进入确认态。
    ///
    /// - Throws: 没有可用 remote，或目标目录非法时抛出，由视图转成提示。
    func prepare(_ project: Project) throws {
        guard !isRunning else { return }

        let projectURL = project.url.standardizedFileURL
        let homeURL = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        guard projectURL.path != "/", projectURL != homeURL else {
            throw RecloneError.unsafeTarget
        }

        let remotes = git.listRemotes(in: projectURL)
        guard let remote = remotes.first(where: { $0.name == "origin" }) ?? remotes.first else {
            throw RecloneError.noRemote
        }
        let remoteURL = remote.fetchURL ?? remote.url
        guard !remoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RecloneError.noRemote
        }

        state = .confirming(project: project, remoteURL: remoteURL)
    }

    /// 第二步：用户确认后入队后台克隆，并启动轮询。
    func beginReclone() {
        guard case let .confirming(project, remoteURL) = state else { return }

        let projectURL = project.url.standardizedFileURL
        // 克隆到同级临时目录：同一文件系统才能保证后续 move 是原子的。
        let destination = projectURL
            .deletingLastPathComponent()
            .appendingPathComponent(".gitok-reclone-\(UUID().uuidString)", isDirectory: true)

        do {
            try clone.validateDestination(destination)
            let task = try clone.enqueue(
                remoteURL: remoteURL,
                destination: destination,
                repositoryName: project.title
            )
            temporaryDestination = destination
            targetProject = project
            state = .running(taskID: task.id)
            log.info("re-clone enqueued for \(projectURL.path, privacy: .public)")
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    /// 第三步：轮询直到任务结束并完成目录替换。
    ///
    /// 视图通过 `.task(id:)` 驱动；取消 Task 即中止轮询。
    func run(taskID: UUID) async {
        while !Task.isCancelled {
            guard case let .running(current) = state, current == taskID else { return }
            guard let task = clone.tasks.first(where: { $0.id == taskID }) else { return }

            switch task.status {
            case .completed:
                await finishReclone(taskID: taskID)
                return
            case .failed, .cancelled:
                fail(taskID: taskID, message: task.errorMessage ?? pluginLocalization.string("Re-clone Failed"))
                return
            case .queued, .cloning, .cancelling:
                break
            }

            do {
                try await Task.sleep(for: Self.pollInterval)
            } catch {
                return
            }
        }
    }

    /// 清理临时目录并回到空闲态；视图在确认框里调用。
    func cancelConfirmation() {
        guard case .confirming = state else { return }
        reset()
    }

    /// 清除失败提示，回到空闲态。
    func dismissFailure() {
        guard case .failed = state else { return }
        reset()
    }

    // MARK: - Directory Replacement

    private func finishReclone(taskID: UUID) async {
        guard case let .running(current) = state, current == taskID,
              let project = targetProject,
              let temporaryDestination else { return }

        let projectURL = project.url.standardizedFileURL
        // 目录替换是重 IO，放到后台线程，避免阻塞主线程上的列表滚动。
        let replacementError: String? = await Task.detached(priority: .userInitiated) {
            do {
                try Self.replaceProjectDirectory(with: temporaryDestination, at: projectURL)
                return nil
            } catch {
                return error.localizedDescription
            }
        }.value

        guard case let .running(latest) = state, latest == taskID else { return }
        if let replacementError {
            fail(taskID: taskID, message: replacementError)
            return
        }

        reset()
        onProjectReplaced()
        log.info("re-clone completed for \(projectURL.path, privacy: .public)")
    }

    private func fail(taskID: UUID, message: String) {
        guard case let .running(current) = state, current == taskID else { return }
        if let temporaryDestination {
            try? FileManager.default.removeItem(at: temporaryDestination)
        }
        reset()
        state = .failed(message: message)
    }

    private func reset() {
        temporaryDestination = nil
        targetProject = nil
        state = .idle
    }

    /// 原子替换项目目录：先把原目录移到备份，再把新克隆移到位，最后删备份。
    ///
    /// 任一步失败都回滚到原目录，保证磁盘上不会留下「既没有旧版本也没有新版本」
    /// 的中间态。必须在同一文件系统内执行。
    nonisolated static func replaceProjectDirectory(with clonedURL: URL, at projectURL: URL) throws {
        let fileManager = FileManager.default
        let parentURL = projectURL.deletingLastPathComponent()
        let backupURL = parentURL
            .appendingPathComponent(".gitok-reclone-backup-\(UUID().uuidString)", isDirectory: true)
        var originalWasMoved = false

        do {
            if fileManager.fileExists(atPath: projectURL.path) {
                try fileManager.moveItem(at: projectURL, to: backupURL)
                originalWasMoved = true
            }
            try fileManager.moveItem(at: clonedURL, to: projectURL)
            if originalWasMoved {
                try fileManager.removeItem(at: backupURL)
            }
        } catch {
            if originalWasMoved {
                if fileManager.fileExists(atPath: projectURL.path) {
                    try? fileManager.removeItem(at: projectURL)
                }
                if fileManager.fileExists(atPath: backupURL.path) {
                    try? fileManager.moveItem(at: backupURL, to: projectURL)
                }
            }
            throw error
        }
    }
}

// MARK: - Error

/// Re-clone 前置校验失败。
enum RecloneError: LocalizedError, Equatable {
    /// 目标是根目录或用户主目录，禁止覆盖。
    case unsafeTarget
    /// 项目没有可用的 remote。
    case noRemote

    var errorDescription: String? {
        switch self {
        case .unsafeTarget:
            pluginLocalization.string("Refusing to replace a system or home directory.")
        case .noRemote:
            pluginLocalization.string("No remote repository found.")
        }
    }
}