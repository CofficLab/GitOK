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

        if Self.verbose {
            os_log("\(self.t)✅ AutoPull started (interval: \(self.timerInterval)s)")
        }

        // 立即执行一次检查
        performAutoPullIfSafe()
    }

    /// 停止自动拉取
    func stop() {
        guard isEnabled else { return }

        isEnabled = false
        timerCancellable?.cancel()
        timerCancellable = nil

        if Self.verbose {
            os_log("\(self.t)⏹️ AutoPull stopped")
        }
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

        // 获取所有项目
        let allProjects = await MainActor.run {
            dataProvider.projects
        }

        guard !allProjects.isEmpty else {
            if Self.verbose {
                await MainActor.run {
                    os_log("\(Self.t)⚠️ No projects available for auto pull")
                }
            }
            return
        }

        if Self.verbose {
            await MainActor.run {
                os_log("\(Self.t)🔍 Checking \(allProjects.count) projects for auto pull")
            }
        }

        // 遍历所有项目，为每个安全的项目执行拉取
        var pullResults: [(project: Project, success: Bool)] = []

        for project in allProjects {
            // 执行安全检查
            let safetyResult = await self.checkSafetyConditions(for: project, dataProvider: dataProvider)
            guard safetyResult.isSafe else {
                if Self.verbose {
                    await MainActor.run {
                        let reason = safetyResult.reason ?? "Unknown reason"
                        os_log("\(Self.t)⏭️ Skipping \(project.title) - \(reason)")
                    }
                }
                continue
            }

            // 执行拉取
            let success = await self.executePull(for: project)
            pullResults.append((project, success))
        }

        // 记录统计信息
        if Self.verbose {
            await MainActor.run {
                let successCount = pullResults.filter { $0.success }.count
                let totalCount = pullResults.count
                if totalCount > 0 {
                    os_log("\(Self.t)📊 Auto pull completed: \(successCount)/\(totalCount) projects pulled successfully")
                }
            }
        }
    }

    // MARK: - Safety Checks

    /// 安全检查结果
    private struct SafetyCheckResult {
        let isSafe: Bool
        let reason: String?
    }

    /// 检查是否满足自动拉取的安全条件
    /// - Returns: SafetyCheckResult 包含是否安全及失败原因
    private func checkSafetyConditions(for project: Project, dataProvider: DataProvider) async -> SafetyCheckResult {
        // 1. 检查是否是 Git 仓库（使用异步检查，避免缓存问题）
        let isGitRepo = await project.isGitAsync()
        guard isGitRepo else {
            return SafetyCheckResult(isSafe: false, reason: "Not a Git repository")
        }

        // 2. 检查工作区是否干净
        do {
            let isClean = try await MainActor.run {
                try project.isClean(verbose: false)
            }
            guard isClean else {
                return SafetyCheckResult(isSafe: false, reason: "Working directory not clean")
            }
        } catch {
            os_log(.error, "\(Self.t)❌ Error checking working directory: \(error)")
            return SafetyCheckResult(isSafe: false, reason: "Error checking working directory")
        }

        // 3. 检查是否有未提交的更改
        do {
            let hasNoUncommitted = try await MainActor.run {
                try project.hasNoUncommittedChanges()
            }
            guard hasNoUncommitted else {
                return SafetyCheckResult(isSafe: false, reason: "Has uncommitted changes")
            }
        } catch {
            os_log(.error, "\(Self.t)❌ Error checking uncommitted changes: \(error)")
            return SafetyCheckResult(isSafe: false, reason: "Error checking uncommitted changes")
        }

        // 4. 检查远程是否有新提交
        do {
            let unpulledCount = try await MainActor.run {
                try project.getUnPulledCount()
            }
            guard unpulledCount > 0 else {
                return SafetyCheckResult(isSafe: false, reason: "No new commits to pull")
            }

            if Self.verbose {
                os_log("\(Self.t)✅ Found \(unpulledCount) unpulled commits")
            }
        } catch {
            os_log(.error, "\(Self.t)❌ Error checking unpulled commits: \(error)")
            return SafetyCheckResult(isSafe: false, reason: "Error checking unpulled commits")
        }

        // 5. 检查是否正在进行 Git 操作
        if let activityStatus = await dataProvider.activityStatus,
           !activityStatus.isEmpty
        {
            return SafetyCheckResult(isSafe: false, reason: "Git operation in progress: \(activityStatus)")
        }

        // 所有检查通过
        return SafetyCheckResult(isSafe: true, reason: nil)
    }

    // MARK: - Pull Execution

    /// 执行拉取操作
    /// - Parameter project: 要拉取的项目
    /// - Returns: 是否成功
    @discardableResult
    private func executePull(for project: Project) async -> Bool {
        if Self.verbose {
            await MainActor.run {
                os_log("\(Self.t)🔄 Executing auto pull for \(project.title)")
            }
        }

        do {
            // 执行拉取（直接使用 LibGit2，避免触发 projectDidPull 事件）
            try await MainActor.run {
                try LibGit2.pull(at: project.path, verbose: false)
            }

            if Self.verbose {
                await MainActor.run {
                    os_log("\(Self.t)✅ Auto pull succeeded for \(project.title)")
                }
            }

            // 如果成功，显示简短通知
            await showSuccessNotification(for: project)

            return true

        } catch {
            await MainActor.run {
                os_log(.error, "\(Self.t)❌ Auto pull failed for \(project.title): \(error)")
            }

            return false
        }
    }

    // MARK: - Helpers

    private func showSuccessNotification(for project: Project) async {
        if Self.verbose {
            await MainActor.run {
                // 可选：使用 MagicToast 显示简短提示
                os_log("\(Self.t)📢 Auto pull completed for \(project.title)")
            }
        }
    }
}
