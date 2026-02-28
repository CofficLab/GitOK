import Combine
import Foundation
import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 自动拉取管理器：负责在后台定期检查并安全地执行自动拉取操作
class AutoPullManager: NSObject, ObservableObject, SuperLog, SuperThread {
    // MARK: - Logging

    nonisolated static let emoji = "🔄"
    nonisolated static let verbose = false

    // MARK: - Configuration

    /// 定时器间隔（秒）: 默认5分钟
    private let timerInterval: TimeInterval = 300

    // MARK: - State

    /// 是否启用自动拉取
    @Published private(set) var isEnabled: Bool = false

    /// 最后检查时间
    @Published private(set) var lastCheckTime: Date?

    /// 最后拉取结果
    @Published private(set) var lastPullResult: PullResult?

    // MARK: - Timer Management

    private var timerCancellable: AnyCancellable?

    // MARK: - Dependencies

    private weak var dataProvider: DataProvider?

    // MARK: - Singleton

    static let shared = AutoPullManager()

    private override init() {
        super.init()
    }

    // MARK: - Lifecycle

    /// 设置数据提供者
    func setDataProvider(_ provider: DataProvider) {
        dataProvider = provider
    }

    /// 启动自动拉取
    func start() {
        guard !isEnabled else {
            if Self.verbose {
                os_log("\(self.t)⚠️ AutoPull is already enabled")
            }
            return
        }

        isEnabled = true

        // 取消之前的定时器
        timerCancellable?.cancel()

        // 创建新的定时器
        timerCancellable = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performAutoPullIfSafe()
            }

        os_log("\(self.t)✅ AutoPull started (interval: \(self.timerInterval)s)")

        // 立即执行一次检查
        performAutoPullIfSafe()
    }

    /// 停止自动拉取
    func stop() {
        guard isEnabled else { return }

        isEnabled = false
        timerCancellable?.cancel()
        timerCancellable = nil

        os_log("\(self.t)⏹️ AutoPull stopped")
    }

    // MARK: - Auto Pull Logic

    /// 执行自动拉取（如果条件安全）
    func performAutoPullIfSafe() {
        guard isEnabled else { return }

        // 记录检查时间
        lastCheckTime = Date()

        // 使用 Task.detached 在后台执行
        Task.detached(priority: .utility) { [weak self] in
            await self?.performAutoPullIfSafeAsync()
        }
    }

    private func performAutoPullIfSafeAsync() async {
        guard let dataProvider = await self.dataProvider else { return }

        // 在 MainActor 上执行所有安全检查和拉取操作
        await MainActor.run {
            guard let project = dataProvider.project else { return }

            // 使用 Task.detached 执行异步检查
            Task.detached(priority: .utility) { [weak self] in
                guard let self = self else { return }

                // 执行安全检查
                guard await self.checkSafetyConditions(for: project, dataProvider: dataProvider) else {
                    if Self.verbose {
                        await MainActor.run {
                            os_log("\(Self.t)⏭️ Safety check failed, skipping auto pull")
                        }
                    }
                    return
                }

                // 执行拉取
                await self.executePull(for: project)
            }
        }
    }

    // MARK: - Safety Checks

    /// 检查是否满足自动拉取的安全条件
    private func checkSafetyConditions(for project: Project, dataProvider: DataProvider) async -> Bool {
        // 1. 检查是否是 Git 仓库
        guard project.isGitRepo else {
            if Self.verbose {
                os_log("\(Self.t)❌ Not a Git repository")
            }
            return false
        }

        // 2. 检查工作区是否干净
        do {
            let isClean = try await MainActor.run {
                try project.isClean(verbose: false)
            }
            guard isClean else {
                if Self.verbose {
                    os_log("\(Self.t)❌ Working directory is not clean")
                }
                return false
            }
        } catch {
            os_log(.error, "\(Self.t)❌ Error checking working directory: \(error)")
            return false
        }

        // 3. 检查是否有未提交的更改
        do {
            let hasNoUncommitted = try await MainActor.run {
                try project.hasNoUncommittedChanges()
            }
            guard hasNoUncommitted else {
                if Self.verbose {
                    os_log("\(Self.t)❌ Has uncommitted changes")
                }
                return false
            }
        } catch {
            os_log(.error, "\(Self.t)❌ Error checking uncommitted changes: \(error)")
            return false
        }

        // 4. 检查远程是否有新提交
        do {
            let unpulledCount = try await MainActor.run {
                try project.getUnPulledCount()
            }
            guard unpulledCount > 0 else {
                if Self.verbose {
                    os_log("\(Self.t)⏭️ No new commits to pull")
                }
                return false
            }

            if Self.verbose {
                os_log("\(Self.t)✅ Found \(unpulledCount) unpulled commits")
            }
        } catch {
            os_log(.error, "\(Self.t)❌ Error checking unpulled commits: \(error)")
            return false
        }

        // 5. 检查是否正在进行 Git 操作
        if let activityStatus = await dataProvider.activityStatus,
           !activityStatus.isEmpty
        {
            if Self.verbose {
                os_log("\(Self.t)⏭️ Git operation in progress: \(activityStatus)")
            }
            return false
        }

        // 所有检查通过
        return true
    }

    // MARK: - Pull Execution

    /// 执行拉取操作
    private func executePull(for project: Project) async {
        await MainActor.run {
            os_log("\(Self.t)🔄 Executing auto pull for \(project.title)")
        }

        // 设置活动状态
        await setStatus("自动拉取中…")

        let result: PullResult

        do {
            // 执行拉取
            try await MainActor.run {
                try project.pull()
            }

            result = PullResult.success(commitCount: 0)

            await MainActor.run {
                os_log("\(Self.t)✅ Auto pull succeeded")
            }

        } catch {
            result = PullResult.failure(error)

            await MainActor.run {
                os_log(.error, "\(Self.t)❌ Auto pull failed: \(error)")
            }
        }

        // 更新结果
        await MainActor.run {
            self.lastPullResult = result
        }

        // 清除活动状态
        await setStatus(nil)

        // 如果成功，显示简短通知
        if result.success {
            await showSuccessNotification(result)
        }
    }

    // MARK: - Helpers

    private func setStatus(_ text: String?) {
        Task { @MainActor in
            dataProvider?.activityStatus = text
        }
    }

    private func showSuccessNotification(_ result: PullResult) async {
        // 只在确实拉取到新提交时显示通知
        // 由于我们无法精确知道拉取了多少提交，暂时显示通用消息
        await MainActor.run {
            // 可选：使用 MagicToast 显示简短提示
            os_log("\(Self.t)📢 \(result.localizedMessage)")
        }
    }
}
