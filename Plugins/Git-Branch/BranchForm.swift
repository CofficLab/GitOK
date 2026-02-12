import MagicKit
import LibGit2Swift
import MagicAlert
import OSLog
import SwiftUI

struct BranchForm: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    
    
    @State private var branches: [GitBranch] = []
    @State private var newBranchName: String = ""
    @State private var isCreating = false
    @State private var isLoading = false
    @State private var selectedBranch: GitBranch?
    
    private let verbose = false
    
    var project: Project? { data.project }
    
    var body: some View {
        if project != nil {
            VStack(spacing: 16) {
                // 新建分支区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("新建分支", tableName: "GitBranch")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        TextField(String(localized: "分支名称", table: "GitBranch"), text: $newBranchName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Image.add.inButtonWithAction {
                            createBranch()
                        }
                    }
                }
                
                Divider()
                
                // 分支列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("切换分支", tableName: "GitBranch")
                        .font(.headline)
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                            Spacer()
                        }
                        .frame(height: 60)
                    } else if branches.isEmpty {
                        Text("暂无分支", tableName: "GitBranch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 60)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(branches) { branch in
                                    BranchRowView(
                                        branch: branch,
                                        isSelected: selectedBranch?.id == branch.id,
                                        onSwitch: {
                                            switchBranch(branch)
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding()
            .frame(width: 300)
            .onAppear {
                loadBranches()
            }
        }
    }
}

// MARK: - Action

extension BranchForm {
    private func createBranch() {
        guard let project = project, !newBranchName.isEmpty else { return }
        
        let branchName = newBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !branchName.isEmpty else { return }
        
        isCreating = true
        
        Task.detached {
            do {
                try project.createBranch(branchName)
                
                await MainActor.run {
                    self.isCreating = false
                    self.newBranchName = ""
                    let msg = String.localizedStringWithFormat(
                        String(localized: "已创建并切换到分支: %@", table: "GitBranch"),
                        branchName
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    self.isCreating = false
                    let msg = String.localizedStringWithFormat(
                        String(localized: "创建分支失败: %@", table: "GitBranch"),
                        error.localizedDescription
                    )
                    alert_error(msg)
                }
            }
        }
    }
    
    private func switchBranch(_ branch: GitBranch) {
        guard let project = project else { return }

        Task.detached {
            do {
                try project.checkout(branch: branch)
                
                await MainActor.run {
                    self.selectedBranch = branch
                    let msg = String.localizedStringWithFormat(
                        String(localized: "已切换到分支: %@", table: "GitBranch"),
                        branch.name
                    )
                    alert_info(msg)
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    let msg = String.localizedStringWithFormat(
                        String(localized: "切换分支失败: %@", table: "GitBranch"),
                        error.localizedDescription
                    )
                    alert_error(msg)
                }
            }
        }
    }
    
    private func loadBranches() {
        guard let project = project else {
            branches = []
            return
        }
        
        // 检查是否是 git 项目
        guard project.isGitRepo else {
            branches = []
            isLoading = false
            return
        }
        
        // 设置刷新状态
        isLoading = true
        
        Task.detached {
            do {
                let allBranches = try project.getBranches()
                let currentBranch = try project.getCurrentBranch()
                
                await MainActor.run {
                    self.branches = allBranches
                    self.selectedBranch = currentBranch
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.branches = []
                    self.isLoading = false
                    if self.verbose {
                        os_log(.error, "Failed to load branches: \(error.localizedDescription)")
                    }
                    let msg = String.localizedStringWithFormat(
                        String(localized: "加载分支列表失败: %@", table: "GitBranch"),
                        error.localizedDescription
                    )
                    alert_error(msg)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

