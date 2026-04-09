import SwiftUI
import LibGit2Swift
import MagicKit

/// 自动推送配置视图：管理项目分支的自动推送设置
/// 
/// 这是主视图，整合所有子组件
struct AutoPushConfigView: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var settingsStore = AutoPushSettingsStore.shared
    
    @State private var currentProjectAutoPushEnabled = false
    @State private var isLoading = false
    @State private var statusMessage: String?
    
    private let verbose = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            AutoPushConfigHeaderView(
                isLoading: isLoading,
                onClose: { dismiss() }
            )
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 当前项目配置
                    if let project = vm.project, let branch = data.branch {
                        CurrentProjectSectionView(
                            project: project,
                            branch: branch,
                            isEnabled: $currentProjectAutoPushEnabled,
                            onToggle: { enabled in
                                handleToggle(project: project, branch: branch, enabled: enabled)
                            }
                        )
                    }
                    
                    // 所有已配置的项目分支
                    ConfiguredProjectsSectionView(
                        settingsStore: settingsStore,
                        isCurrentProject: isCurrentProject,
                        onToggle: handleToggleConfig,
                        onDelete: handleDeleteConfig
                    )
                }
                .padding()
            }
            
            // 底部状态栏
            AutoPushStatusBarView(message: statusMessage)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            updateCurrentProjectStatus()
        }
        .onChange(of: vm.project) { _, _ in
            updateCurrentProjectStatus()
        }
        .onChange(of: data.branch) { _, _ in
            updateCurrentProjectStatus()
        }
    }
    
    // MARK: - Event Handlers
    
    private func updateCurrentProjectStatus() {
        guard let project = vm.project,
              let branch = data.branch else {
            currentProjectAutoPushEnabled = false
            return
        }
        
        currentProjectAutoPushEnabled = settingsStore.isAutoPushEnabled(
            for: project.path,
            branchName: branch.name
        )
    }
    
    private func handleToggle(project: Project, branch: GitBranch, enabled: Bool) {
        // 保存设置
        settingsStore.setAutoPushEnabled(
            for: project.path,
            branchName: branch.name,
            enabled: enabled
        )
        
        // 如果启用，执行推送
        if enabled {
            performPush(project: project, branch: branch)
        }
        
        // 显示状态消息
        showStatusMessage("\(enabled ? "已启用" : "已禁用") 自动推送：\(project.title)/\(branch.name)")
    }
    
    private func handleToggleConfig(_ config: ProjectBranchAutoPushConfig) {
        let newStatus = !config.isEnabled
        
        settingsStore.setAutoPushEnabled(
            for: config.projectPath,
            branchName: config.branchName,
            enabled: newStatus
        )
        
        // 如果是当前项目，同步更新状态
        if let project = vm.project,
           let branch = data.branch,
           config.projectPath == project.path && config.branchName == branch.name {
            withAnimation {
                currentProjectAutoPushEnabled = newStatus
            }
            
            // 如果启用，执行推送
            if newStatus {
                performPush(project: project, branch: branch)
            }
        }
        
        showStatusMessage("\(newStatus ? "已启用" : "已禁用") 自动推送：\(config.projectTitle)/\(config.branchName)")
    }
    
    private func handleDeleteConfig(_ config: ProjectBranchAutoPushConfig) {
        settingsStore.removeConfig(
            for: config.projectPath,
            branchName: config.branchName
        )
        
        // 如果是当前项目，同步更新状态
        if let project = vm.project,
           let branch = data.branch,
           config.projectPath == project.path && config.branchName == branch.name {
            withAnimation {
                currentProjectAutoPushEnabled = false
            }
        }
        
        showStatusMessage("已删除配置：\(config.projectTitle)/\(config.branchName)")
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentProject(_ config: ProjectBranchAutoPushConfig) -> Bool {
        guard let project = vm.project,
              let branch = data.branch else {
            return false
        }
        return config.projectPath == project.path && config.branchName == branch.name
    }
    
    private func showStatusMessage(_ message: String) {
        statusMessage = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.statusMessage = nil
            }
        }
    }
    
    private func performPush(project: Project, branch: GitBranch) {
        Task { @MainActor in
            isLoading = true
            statusMessage = "正在推送..."
        }
        
        Task.detached {
            do {
                try project.push()
                
                // 更新最后推送时间
                AutoPushSettingsStore.shared.updateLastPushedDate(
                    for: project.path,
                    branchName: branch.name
                )
                
                await MainActor.run {
                    isLoading = false
                    statusMessage = "推送成功"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            statusMessage = nil
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    statusMessage = "推送失败：\(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview("AutoPushConfigView") {
    AutoPushConfigView()
        .frame(width: 600, height: 500)
}