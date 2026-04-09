import Foundation
import LibGit2Swift
import MagicKit
import OSLog
import Combine
import SwiftUI

/// 自动推送服务：定时检查并自动执行推送（后台执行）
class AutoPushService: ObservableObject, SuperLog {
    static let shared = AutoPushService()
    
    nonisolated static let emoji = "🚀"
    static let verbose = true  // 设为 true 以查看详细日志
    
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
    
    /// 注册服务，启动定时器
    func register(projectVM: ProjectVM) {
        self.projectVM = projectVM
        
        if Self.verbose {
            os_log(.info, "\(Self.t)AutoPushService registered, timer interval: \(Self.checkInterval)s")
        }
        
        // 启动定时器，定时检查并推送
        startTimer()
    }
    
    /// 启动定时器
    func startTimer() {
        guard timer == nil else {
            if Self.verbose {
                os_log(.info, "\(Self.t)Timer already running")
            }
            return
        }
        
        if Self.verbose {
            os_log(.info, "\(Self.t)Starting timer...")
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
            os_log(.info, "\(Self.t)Stopping timer...")
        }
        
        timer?.invalidate()
        timer = nil
        
        Task { @MainActor in
            withAnimation {
                self.isTimerRunning = false
            }
        }
    }
    
    /// 检查当前项目并执行自动推送
    private func checkAndAutoPushForCurrentProject() async {
        // 从 ProjectVM 获取当前项目（projectVM 是 weak 引用，需要在主线程访问）
        var project: Project?
        await MainActor.run {
            project = self.projectVM?.project
        }
        
        guard let project = project else {
            if Self.verbose {
                os_log(.info, "\(Self.t)No project selected, skip auto push")
            }
            return
        }
        
        await checkAndAutoPush(project: project)
    }
    
    /// 检查并执行自动推送
    private func checkAndAutoPush(project: Project) async {
        // 获取当前分支（可能在后台执行）
        let currentBranch: GitBranch? = await Task.detached {
            try? project.getCurrentBranch()
        }.value
        
        guard let currentBranch = currentBranch else {
            if Self.verbose {
                os_log(.info, "\(Self.t)Cannot get current branch, skip auto push")
            }
            return
        }
        
        // 检查是否启用了自动推送（后台读取）
        let isEnabled = await Task.detached {
            AutoPushSettingsStore.shared.isAutoPushEnabled(
                for: project.path,
                branchName: currentBranch.name
            )
        }.value
        
        if !isEnabled {
            if Self.verbose {
                os_log(.info, "\(Self.t)Auto push not enabled for \(project.title)/\(currentBranch.name)")
            }
            return
        }
        
        // 检查是否为 Git 仓库
        guard project.isGitRepo else {
            if Self.verbose {
                os_log(.info, "\(Self.t)Not a git repository, skip auto push")
            }
            return
        }
        
        // 检查是否有远程仓库（后台执行）
        let hasRemote = await Task.detached {
            guard let remoteURL = LibGit2.getRemoteURL(at: project.path, remote: "origin"),
                  !remoteURL.isEmpty else {
                return false
            }
            return true
        }.value
        
        if !hasRemote {
            if Self.verbose {
                os_log(.info, "\(Self.t)No remote repository configured, skip auto push")
            }
            return
        }
        
        // 执行推送（完全在后台）
        await performPush(project: project, branchName: currentBranch.name)
    }
    
    /// 执行推送操作（完全在后台）
    private func performPush(project: Project, branchName: String) async {
        // 检查是否正在推送
        let currentlyPushing = await Task { @MainActor in
            self.isPushing
        }.value
        
        guard !currentlyPushing else {
            if Self.verbose {
                os_log(.info, "\(Self.t)Already pushing, skip")
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
                let unpushedCommits = try LibGit2.getUnPushedCommits(at: project.path, verbose: false)
                
                if unpushedCommits.isEmpty {
                    if Self.verbose {
                        os_log(.info, "\(Self.t)No unpushed commits, skip push")
                    }
                    await self.updateStatus(.idle)
                    return
                }
                
                if Self.verbose {
                    os_log(.info, "\(Self.t)Pushing \(unpushedCommits.count) commit(s) to remote...")
                }
                
                // 执行推送（耗时操作）
                try project.push()
                
                // 更新最后推送时间
                AutoPushSettingsStore.shared.updateLastPushedDate(
                    for: project.path,
                    branchName: branchName
                )
                
                if Self.verbose {
                    os_log(.info, "\(Self.t)Auto push succeeded")
                }
                
                await self.updateStatus(.success)
                
                // 3 秒后重置状态
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await self.updateStatus(.idle)
                
            } catch {
                if Self.verbose {
                    os_log(.error, "\(Self.t)Auto push failed: \(error.localizedDescription)")
                }
                
                await self.updateStatus(.failed(error))
                
                // 显示错误提示
                await self.alertError(error)
                
                // 5 秒后重置状态
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await self.updateStatus(.idle)
            }
        }.value
    }
    
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
