import Foundation
import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI
import Combine

/// 自动推送服务：监听分支变化并自动执行推送
class AutoPushService: ObservableObject, SuperLog {
    static let shared = AutoPushService()
    
    nonisolated static let emoji = "🚀"
    static let verbose = true
    
    @Published var isPushing = false
    @Published var lastPushStatus: PushStatus?
    
    private var cancellables = Set<AnyCancellable>()
    private var dataProvider: DataProvider?
    
    enum PushStatus {
        case idle
        case pushing
        case success
        case failed(Error)
    }
    
    private init() {}
    
    /// 注册服务，开始监听事件
    func register(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        
        if Self.verbose {
            os_log(.info, "\(Self.t)AutoPushService registered")
        }
        
        // 监听分支变化事件
        NotificationCenter.default.publisher(for: .projectDidChangeBranch)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleBranchChange(notification)
            }
            .store(in: &cancellables)
        
        // 在项目变化时检查是否需要自动推送
        // 由于 DataProvider 是 @MainActor 隔离的，我们需要在主线程订阅
        Task { @MainActor in
            dataProvider.$project
                .receive(on: DispatchQueue.main)
                .sink { [weak self] project in
                    if let project = project {
                        self?.checkAndAutoPush(project: project)
                    }
                }
                .store(in: &self.cancellables)
        }
    }
    
    /// 处理分支变化事件
    private func handleBranchChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo else {
            return
        }
        
        if Self.verbose {
            os_log(.info, "\(Self.t)Branch changed: \(eventInfo.project.path) -> \(eventInfo.additionalInfo?["branchName"] as? String ?? "unknown")")
        }
        
        checkAndAutoPush(project: eventInfo.project)
    }
    
    /// 检查并执行自动推送
    private func checkAndAutoPush(project: Project) {
        // 确保在主线程执行
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.checkAndAutoPush(project: project)
            }
            return
        }
        
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
        DispatchQueue.main.async {
        }
    }
}
