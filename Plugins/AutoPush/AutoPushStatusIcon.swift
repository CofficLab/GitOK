import AppKit
import MagicKit
import os
import SwiftUI

/// 自动推送状态栏图标：显示自动推送状态并提供配置入口
struct AutoPushStatusIcon: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var isSheetPresented = false
    @State private var isAutoPushEnabled = false
    @State private var hasRemoteBranch = false
    @State private var serviceRegistered = false

    /// 订阅设置存储的变化
    @ObservedObject private var settingsStore = AutoPushSettingsStore.shared

    // MARK: - Logger & Config

    /// 日志标识 emoji
    nonisolated static let emoji = "📡"

    /// 是否启用详细日志
    nonisolated static let verbose = false

    static let shared = AutoPushStatusIcon()

    init() {}
    
    var body: some View {
        StatusBarTile(icon: isAutoPushEnabled ? "arrow.up.circle.fill" : "arrow.up.circle", onTap: {
            isSheetPresented.toggle()
        })
        .help(isAutoPushEnabled ? "自动推送已启用 - 点击管理" : "自动推送已禁用 - 点击配置")
        .foregroundColor(isAutoPushEnabled ? .green : .secondary)
        .sheet(isPresented: $isSheetPresented) {
            AutoPushConfigView()
                .frame(minWidth: 500, minHeight: 400)
        }
        .onAppear {
            // 注册自动推送服务（只注册一次）
            if !serviceRegistered {
                serviceRegistered = true
                AutoPushService.shared.register(projectVM: vm)
                if Self.verbose {
                    AutoPushPlugin.logger.info("\(Self.t)📝 从状态栏注册 AutoPushService")
                }
            }
            updateStatus()
        }
        .onChange(of: vm.project) { _, _ in
            updateStatus()
        }
        .onChange(of: data.branch) { _, _ in
            updateStatus()
        }
        // 监听设置变化，当配置改变时自动更新状态
        .onChange(of: settingsStore.settings) { _, _ in
            updateStatus()
        }
    }
    
    private func updateStatus() {
        guard let project = vm.project,
              let branch = data.branch,
              project.isGitRepo else {
            isAutoPushEnabled = false
            hasRemoteBranch = false
            return
        }
        
        // 检查当前分支是否启用了自动推送
        isAutoPushEnabled = AutoPushSettingsStore.shared.isAutoPushEnabled(
            for: project.path,
            branchName: branch.name
        )
        
        // 检查是否有远程分支
        checkRemoteBranch(project: project, branchName: branch.name)
    }
    
    private func checkRemoteBranch(project: Project, branchName: String) {
        Task {
            do {
                let remotes = try project.remoteList()
                let hasRemote = !remotes.isEmpty
                
                // 简单检查：如果有 remote，就认为可能有远程分支
                await MainActor.run {
                    self.hasRemoteBranch = hasRemote
                }
            } catch {
                await MainActor.run {
                    self.hasRemoteBranch = false
                }
            }
        }
    }
}

#Preview("AutoPushStatusIcon") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}
