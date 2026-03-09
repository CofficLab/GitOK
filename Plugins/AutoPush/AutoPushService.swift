import Foundation
import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI
import Combine

/// 自动推送服务：定时检查并自动执行推送
@MainActor
class AutoPushService: ObservableObject, SuperLog {
    static let shared = AutoPushService()
    
    nonisolated static let emoji = "🚀"
    static let verbose = true
    
    /// 定时检查间隔（秒）
    static let checkInterval: TimeInterval = 30.0
    
    @Published var isPushing = false
    @Published var lastPushStatus: PushStatus?
    @Published var isTimerRunning = false
    
    private var cancellables = Set<AnyCancellable>()
    private var dataProvider: DataProvider?
    private var timer: Timer?
    
    enum PushStatus {
        case idle
        case pushing
        case success
        case failed(Error)
    }
    
    private init() {}
    
    /// 注册服务，启动定时器
    func register(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        
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
        
        // 立即执行一次检查
        checkAndAutoPushForCurrentProject()
        
        // 创建定时器
        timer = Timer.scheduledTimer(withTimeInterval: Self.checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndAutoPushForCurrentProject()
            }
        }
        
        withAnimation {
            isTimerRunning = true
        }
    }
    
    /// 停止定时器
    func stopTimer() {
        if Self.verbose {
            os_log(.info, "\(Self.t)Stopping timer...")
        }
        
        timer?.invalidate()
        timer = nil
        
        withAnimation {
            isTimerRunning = false
        }
    }
    
    /// 检查当前项目并执行自动推送
    private func checkAndAutoPushForCurrentProject() {
        guard let project = dataProvider?.project else {
            if Self.verbose {
                os_log(.info, "\(Self.t)No project selected, skip auto push")
            }
            return
        }
        
        checkAndAutoPush(project: project)
    }
    
    /// 检查并执行自动推送
    private func checkAndAutoPush(project: Project) {
        // 获取当前分支
        guard let currentBranch = try? project.getCurrentBranch() else {
            if Self.verbose {
                os_log(.info, "\(Self.t)Cannot get current branch, skip auto push")
            }
            return
        }
        
        // 检查是否启用了自动推送
        let isEnabled = AutoPushSettingsStore.shared.isAutoPushEnabled(
            for: project.path,
            branchName: currentBranch.name
        )
        
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
        
        // 检查是否有远程仓库
        guard let remoteURL = LibGit2.getRemoteURL(at: project.path, remote: "origin"),
              !remoteURL.isEmpty else {
            if Self.verbose {
                os_log(.info, "\(Self.t)No remote repository configured, skip auto push")
            }
            return
        }
        
        // 执行推送
        performPush(project: project, branchName: currentBranch.name)
    }
    
    /// 执行推送操作
    private func performPush(project: Project, branchName: String) {
        guard !isPushing else {
            if Self.verbose {
                os_log(.info, "\(Self.t)Already pushing, skip")
            }
            return
        }
        
        withAnimation {
            isPushing = true
            lastPushStatus = .pushing
        }
        
        Task.detached {
            do {
                // 检查是否有未推送的提交
                let unpushedCommits = try LibGit2.getUnPushedCommits(at: project.path, verbose: false)
                
                if unpushedCommits.isEmpty {
                    if Self.verbose {
                        os_log(.info, "\(Self.t)No unpushed commits, skip push")
                    }
                    await MainActor.run {
                        withAnimation {
                            self.isPushing = false
                            self.lastPushStatus = .idle
                        }
                    }
                    return
                }
                
                if Self.verbose {
                    os_log(.info, "\(Self.t)Pushing \(unpushedCommits.count) commit(s) to remote...")
                }
                
                // 执行推送
                try project.push()
                
                // 更新最后推送时间
                await MainActor.run {
                    AutoPushSettingsStore.shared.updateLastPushedDate(
                        for: project.path,
                        branchName: branchName
                    )
                }
                
                await MainActor.run {
                    withAnimation {
                        self.isPushing = false
                        self.lastPushStatus = .success
                    }
                    
                    if Self.verbose {
                        os_log(.info, "\(Self.t)Auto push succeeded")
                    }
                    
                    // 3 秒后重置状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            self.lastPushStatus = .idle
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    withAnimation {
                        self.isPushing = false
                        self.lastPushStatus = .failed(error)
                    }
                    
                    if Self.verbose {
                        os_log(.error, "\(Self.t)Auto push failed: \(error.localizedDescription)")
                    }
                    
                    // 显示错误提示
                    self.alertError(error)
                    
                    // 5 秒后重置状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            self.lastPushStatus = .idle
                        }
                    }
                }
            }
        }
    }
    
    /// 显示错误提示
    private func alertError(_ error: Error) {
        // 空实现，错误已在 performPush 中处理
    }
}
