
import MagicKit
import MagicAlert
import MagicUI
import OSLog
import SwiftUI

struct BranchForm: View, SuperLog {
    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var m: MagicMessageProvider
    
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
                    Text("新建分支")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        TextField("分支名称", text: $newBranchName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        MagicButton.simple {
                            createBranch()
                        }
                        .magicTitle("创建")
                        .magicSize(.regular)
                        .magicIcon(.iconPlus)   
                        .disabled(newBranchName.isEmpty || isCreating)
                    }
                }
                
                Divider()
                
                // 分支列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("切换分支")
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
                        Text("暂无分支")
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
                    self.m.info("已创建并切换到分支: \(branchName)")
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    self.isCreating = false
                    self.m.error("创建分支失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func switchBranch(_ branch: GitBranch) {
        guard let project = project else { return }
        
        Task.detached {
            do {
                try project.setCurrentBranch(branch)
                
                await MainActor.run {
                    self.selectedBranch = branch
                    self.m.info("已切换到分支: \(branch.name)")
                    self.loadBranches()
                }
            } catch {
                await MainActor.run {
                    self.m.error("切换分支失败: \(error.localizedDescription)")
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
        guard project.isGit() else {
            branches = []
            isLoading = false
            return
        }
        
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
                    if verbose {
                        os_log(.error, "\(self.t)Failed to load branches: \(error.localizedDescription)")
                    }
                    self.m.error("加载分支列表失败: \(error.localizedDescription)")
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

