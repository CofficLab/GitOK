import AppKit
import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 自动推送配置视图：管理项目分支的自动推送设置
struct AutoPushConfigView: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @Environment(\.dismiss) private var dismiss
    
    /// 修复：使用 ObservedObject 而不是 StateObject，避免创建新实例
    @ObservedObject private var settingsStore = AutoPushSettingsStore.shared
    
    @State private var currentProjectAutoPushEnabled = false
    @State private var isLoading = false
    @State private var statusMessage: String?
    
    private let verbose = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("自动推送配置")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("管理项目分支的自动推送设置")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Button("关闭") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            
            // 内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 当前项目配置
                    if let project = vm.project, let branch = data.branch {
                        currentProjectSection(project: project, branch: branch)
                    }
                    
                    // 所有已配置的项目分支
                    configuredSections
                }
                .padding()
            }
            
            // 底部状态栏
            if let message = statusMessage {
                HStack {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .top
                )
            }
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
    
    // MARK: - Current Project Section
    
    @ViewBuilder
    private func currentProjectSection(project: Project, branch: GitBranch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                Text("当前项目")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                        
                        Text(project.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(.purple)
                            Text(branch.name)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                        }
                        
                        if !project.isGitRepo {
                            Text("非 Git 项目")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if !hasRemoteBranch(project: project) {
                            Text("无远程仓库")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Toggle(isOn: $currentProjectAutoPushEnabled) {
                        Text("启用自动推送")
                            .fontWeight(.medium)
                    }
                    .toggleStyle(.switch)
                    .disabled(!project.isGitRepo)
                    .onChange(of: currentProjectAutoPushEnabled) { _, newValue in
                        // 关键修复：切换开关时保存到设置存储（后台执行）
                        saveCurrentProjectSetting(project: project, branch: branch, enabled: newValue)
                    }
                    
                    Spacer()
                    
                    if currentProjectAutoPushEnabled {
                        Label("已启用", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Label("已禁用", systemImage: "circle")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Text("启用后，将定时自动推送到远程仓库（每 30 秒检查一次）")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
    
    // MARK: - Configured Sections
    
    private var configuredSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                Text("已配置的项目分支")
                    .font(.headline)
                Spacer()
                
                if !settingsStore.settings.isEmpty {
                    Text("\(settingsStore.settings.count) 个配置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if settingsStore.settings.isEmpty {
                VStack(spacing: 16) {
                    Image.cloudUpload
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无配置")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("在当前项目中启用自动推送后，配置将显示在这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(settingsStore.settings.values.sorted { $0.lastModified > $1.lastModified }) { config in
                        ConfigRowView(
                            config: config,
                            isCurrentProject: isCurrentProject(config: config),
                            onToggle: toggleAutoPush,
                            onDelete: deleteConfig
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    /// 保存当前项目的自动推送设置（后台执行）
    private func saveCurrentProjectSetting(project: Project, branch: GitBranch, enabled: Bool) {
        // 保存设置（已经是线程安全的）
        settingsStore.setAutoPushEnabled(
            for: project.path,
            branchName: branch.name,
            enabled: enabled
        )
        
        // 如果启用，在后台执行推送
        if enabled {
            Task.detached {
                await self.performPush(project: project, branch: branch)
            }
        }
        
        // 更新状态消息（主线程）
        Task { @MainActor in
            self.statusMessage = "\(enabled ? "已启用" : "已禁用") 自动推送：\(project.title)/\(branch.name)"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.statusMessage = nil
            }
        }
    }
    
    private func toggleAutoPush(_ config: ProjectBranchAutoPushConfig) {
        let newStatus = !config.isEnabled
        
        // 保存设置（后台）
        settingsStore.setAutoPushEnabled(
            for: config.projectPath,
            branchName: config.branchName,
            enabled: newStatus
        )
        
        // 如果切换的是当前项目分支，同步更新状态
        if let project = vm.project,
           let branch = data.branch,
           config.projectPath == project.path && config.branchName == branch.name {
            Task { @MainActor in
                withAnimation {
                    self.currentProjectAutoPushEnabled = newStatus
                }
            }
            
            // 如果启用且是当前项目，在后台执行推送
            if newStatus {
                Task.detached {
                    await self.performPush(project: project, branch: branch)
                }
            }
        }
        
        // 更新状态消息
        Task { @MainActor in
            self.statusMessage = "\(newStatus ? "已启用" : "已禁用") 自动推送：\(config.projectTitle)/\(config.branchName)"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.statusMessage = nil
            }
        }
    }
    
    private func deleteConfig(_ config: ProjectBranchAutoPushConfig) {
        // 删除配置（后台）
        settingsStore.removeConfig(for: config.projectPath, branchName: config.branchName)
        
        // 如果删除的是当前项目分支，同步更新状态
        if let project = vm.project,
           let branch = data.branch,
           config.projectPath == project.path && config.branchName == branch.name {
            Task { @MainActor in
                withAnimation {
                    self.currentProjectAutoPushEnabled = false
                }
            }
        }
        
        // 更新状态消息
        Task { @MainActor in
            self.statusMessage = "已删除配置：\(config.projectTitle)/\(config.branchName)"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.statusMessage = nil
            }
        }
    }
    
    private func isCurrentProject(config: ProjectBranchAutoPushConfig) -> Bool {
        guard let project = vm.project,
              let branch = data.branch else {
            return false
        }
        return config.projectPath == project.path && config.branchName == branch.name
    }
    
    private func hasRemoteBranch(project: Project) -> Bool {
        // 同步检查远程仓库（在 UI 中直接调用，不阻塞）
        return (try? project.remoteList().isEmpty) == false
    }
    
    /// 执行推送操作（后台执行）
    private func performPush(project: Project, branch: GitBranch) async {
        await Task { @MainActor in
            self.isLoading = true
            self.statusMessage = "正在推送..."
        }.value
        
        do {
            try await Task.detached {
                try project.push()
            }.value
            
            // 更新最后推送时间
            AutoPushSettingsStore.shared.updateLastPushedDate(
                for: project.path,
                branchName: branch.name
            )
            
            await Task { @MainActor in
                self.isLoading = false
                self.statusMessage = "推送成功"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.statusMessage = nil
                }
            }.value
            
        } catch {
            await Task { @MainActor in
                self.isLoading = false
                self.statusMessage = "推送失败：\(error.localizedDescription)"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.statusMessage = nil
                }
            }.value
        }
    }
}

// MARK: - Config Row View

struct ConfigRowView: View {
    let config: ProjectBranchAutoPushConfig
    let isCurrentProject: Bool
    let onToggle: (ProjectBranchAutoPushConfig) -> Void
    let onDelete: (ProjectBranchAutoPushConfig) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态指示器
            Circle()
                .fill(config.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            // 项目信息
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(config.projectTitle)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    
                    Text("/")
                        .foregroundColor(.secondary)
                    
                    Text(config.branchName)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.purple)
                    
                    if isCurrentProject {
                        Label("当前", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(config.projectPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 最后推送时间
            if let lastPushed = config.lastPushedAt {
                Text(formatDate(lastPushed))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 切换开关
            Toggle(isOn: Binding(
                get: { config.isEnabled },
                set: { _ in onToggle(config) }
            )) {
                EmptyView()
            }
            .toggleStyle(.switch)
            .scaleEffect(0.9)
            
            // 删除按钮
            Button(action: { onDelete(config) }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color(NSColor.controlBackgroundColor) : Color.clear)
        )
        .onHover { hovering in
            withAnimation {
                isHovering = hovering
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview("AutoPushConfigView") {
    AutoPushConfigView()
        .frame(width: 600, height: 500)
}
