import Foundation
import LibGit2Swift
import MagicKit
import os
import Combine
import SwiftUI

/// 自动推送服务：定时检查并自动执行推送（后台执行）
class AutoPushService: ObservableObject, SuperLog {
    static let shared = AutoPushService()

    // MARK: - Logger & Config

    /// 日志标识 emoji
    nonisolated static let emoji = "🚀"

    /// 是否启用详细日志
    nonisolated static let verbose = false

    // MARK: - Properties

    /// 定时检查间隔（秒）
    static let checkInterval: TimeInterval = 30.0

    @Published var isPushing = false
    @Published var lastPushStatus: PushStatus?
    @Published var isTimerRunning = false

    private var cancellables = Set<AnyCancellable>()
    private weak var projectVM: ProjectVM?
    private var timer: Timer?

    enum PushStatus {
        case idle
        case pushing
        case success
        case failed(Error)
    }

    private init() {}

    // MARK: - Lifecycle

    /// 注册服务，启动定时器
    func register(projectVM: ProjectVM) {
        self.projectVM = projectVM

        if Self.verbose {
            AutoPushPlugin.logger.info("\(Self.t)📝 AutoPushService 已注册，定时器间隔: \(Self.checkInterval)s")
        }

        // 启动定时器，定时检查并推送
        startTimer()
    }

    /// 启动定时器
    func startTimer() {
        guard timer == nil else {
            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)定时器已在运行")
            }
            return
        }

        if Self.verbose {
            AutoPushPlugin.logger.info("\(Self.t)🚀 启动定时器...")
        }

        // 立即执行一次检查（在后台）
        Task.detached { [weak self] in
            await self?.checkAndAutoPushForCurrentProject()
        }

        // 创建定时器，在后台执行检查
        timer = Timer.scheduledTimer(withTimeInterval: Self.checkInterval, repeats: true) { [weak self] _ in
            Task.detached { [weak self] in
                await self?.checkAndAutoPushForCurrentProject()
            }
        }

        Task { @MainActor in
            withAnimation {
                self.isTimerRunning = true
            }
        }
    }

    /// 停止定时器
    func stopTimer() {
        if Self.verbose {
            AutoPushPlugin.logger.info("\(Self.t)⛔️ 停止定时器...")
        }

        timer?.invalidate()
        timer = nil

        Task { @MainActor in
            withAnimation {
                self.isTimerRunning = false
            }
        }
    }

    // MARK: - Auto Push Logic

    /// 检查当前项目并执行自动推送
    private func checkAndAutoPushForCurrentProject() async {
        let projectSnapshot = await MainActor.run { () -> (path: String, isGitRepo: Bool, title: String)? in
            guard let project = self.projectVM?.project else { return nil }
            return (project.path, project.isGitRepo, project.title)
        }

        guard let projectSnapshot else {
            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)没有选中的项目，跳过自动推送")
            }
            return
        }

        await checkAndAutoPush(
            projectPath: projectSnapshot.path,
            isGitRepo: projectSnapshot.isGitRepo,
            projectTitle: projectSnapshot.title
        )
    }

    /// 检查并执行自动推送
    private func checkAndAutoPush(projectPath: String, isGitRepo: Bool, projectTitle: String) async {
        // 获取当前分支（可能在后台执行）
        let currentBranch: GitBranch? = await Task.detached {
            try? LibGit2.getCurrentBranchInfo(at: projectPath)
        }.value

        // 检查是否启用了自动推送（后台读取）
        let isEnabled = await Task.detached {
            AutoPushSettingsStore.shared.isAutoPushEnabled(
                for: projectPath,
                branchName: currentBranch?.name ?? ""
            )
        }.value

        // 检查是否有远程仓库（后台执行）
        let hasRemote = await Task.detached {
            guard let remoteURL = LibGit2.getRemoteURL(at: projectPath, remote: "origin"),
                  !remoteURL.isEmpty else {
                return false
            }
            return true
        }.value

        switch AutoPushDecision.check(
            currentBranchName: currentBranch?.name,
            isEnabled: isEnabled,
            isGitRepo: isGitRepo,
            hasRemote: hasRemote
        ) {
        case .skip(.missingBranch):
            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)无法获取当前分支，跳过自动推送")
            }
        case .skip(.disabled):
            if Self.verbose {
                let branchName = currentBranch?.name ?? "unknown"
                AutoPushPlugin.logger.info("\(Self.t)未启用自动推送 \(projectTitle)/\(branchName)")
            }
        case .skip(.notGitRepository):
            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)不是 Git 仓库，跳过自动推送")
            }
        case .skip(.missingRemote):
            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)未配置远程仓库，跳过自动推送")
            }
        case let .shouldPush(branchName):
            await performPush(projectPath: projectPath, branchName: branchName)
        }
    }

    /// 执行推送操作（完全在后台）
    private func performPush(projectPath: String, branchName: String) async {
        // 检查是否正在推送
        let currentlyPushing = await Task { @MainActor in
            self.isPushing
        }.value

        let executionDecision = AutoPushDecision.execution(
            isAlreadyPushing: currentlyPushing,
            unpushedCommitCount: 1
        )

        guard executionDecision != .skipAlreadyPushing else {
            if Self.verbose {
                AutoPushPlugin.logger.info("\(Self.t)正在推送中，跳过")
            }
            return
        }

        // 更新 UI 状态
        await Task { @MainActor in
            withAnimation {
                self.isPushing = true
                self.lastPushStatus = .pushing
            }
        }.value

        // 在后台执行推送
        await Task.detached { [weak self] in
            guard let self = self else { return }

            do {
                // 检查是否有未推送的提交
                let unpushedCommits = try LibGit2.getUnPushedCommits(at: projectPath, verbose: false)

                if AutoPushDecision.execution(
                    isAlreadyPushing: false,
                    unpushedCommitCount: unpushedCommits.count
                ) == .markIdle {
                    if Self.verbose {
                        AutoPushPlugin.logger.info("\(Self.t)没有未推送的提交，跳过推送")
                    }
                    await self.updateStatus(.idle)
                    return
                }

                if Self.verbose {
                    AutoPushPlugin.logger.info("\(Self.t)⬆️ 正在推送 \(unpushedCommits.count) 个提交到远程...")
                }

                // 执行推送（耗时操作）
                try LibGit2.push(at: projectPath, verbose: false)

                // 更新最后推送时间
                AutoPushSettingsStore.shared.updateLastPushedDate(
                    for: projectPath,
                    branchName: branchName
                )

                if Self.verbose {
                    AutoPushPlugin.logger.info("\(Self.t)✅ 自动推送成功")
                }

                await self.updateStatus(.success)

                // 3 秒后重置状态
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await self.updateStatus(.idle)

            } catch {
                // 错误日志始终输出，不依赖 verbose
                AutoPushPlugin.logger.error("\(Self.t)❌ 自动推送失败: \(error.localizedDescription)")

                await self.updateStatus(.failed(error))

                // 显示错误提示
                await self.alertError(error)

                // 5 秒后重置状态
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await self.updateStatus(.idle)
            }
        }.value
    }

    // MARK: - Helper Methods

    /// 更新状态（在主线程）
    private func updateStatus(_ status: PushStatus) async {
        await Task { @MainActor in
            withAnimation {
                self.isPushing = false
                self.lastPushStatus = status
            }
        }.value
    }

    /// 显示错误提示（在主线程）
    private func alertError(_ error: Error) async {
        await Task { @MainActor in
            // 可以在这里显示 NSAlert
            // 暂时空实现，错误日志已记录
        }.value
    }
}
