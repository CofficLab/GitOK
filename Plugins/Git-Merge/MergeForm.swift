import MagicKit
import LibGit2Swift
import OSLog
import SwiftUI

/// 分支合并表单：提供分支选择和合并操作的界面
struct MergeForm: View, SuperLog {
    /// 是否启用详细日志输出
    nonisolated static let emoji = "🔀"
    nonisolated static let verbose = false

    /// 环境对象：应用提供者
    @EnvironmentObject var app: AppProvider
    /// 环境对象：数据提供者
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var vm: ProjectVM

    /// 项目分支列表
    @State var branches: [GitBranch] = []
    /// 提交消息文本（未使用）
    @State var text: String = ""
    /// 提交类别（未使用）
    @State var category: CommitCategory = .Chore
    /// 源分支（要合并的分支）
    @State var branch1: GitBranch? = nil
    /// 目标分支（合并到的分支）
    @State var branch2: GitBranch? = nil

    /// 当前项目
    var project: Project? { vm.project }

    var body: some View {
        if let project = project {
            Group {
                VStack {
                    VStack {
                        Picker("", selection: $branch1, content: {
                            ForEach(branches, id: \.self, content: {
                                Text($0.name)
                                    .tag($0 as GitBranch?)
                            })
                        })

                        Text("至").padding()

                        Picker("", selection: $branch2, content: {
                            ForEach(branches, id: \.self, content: {
                                Text($0.name)
                                    .tag($0 as GitBranch?)
                            })
                        })
                    }

                    if let branch1 = branch1, let branch2 = branch2 {
                        BtnMerge(path: project.path, from: branch1, to: branch2)
//                            .padding(.top, 20)
//                            .controlSize(.extraLarge)
                    }
                }
            }
            .onAppear(perform: onAppear)
        }
    }
}

// MARK: - Action

extension MergeForm {
    /// 加载项目分支列表
    /// 获取当前项目的所有分支，并设置默认选择
    private func onAppear() {
        guard let project = project else { return }

        do {
            self.branches = try project.getBranches()
            self.branch1 = branches.first
            self.branch2 = branches.count >= 2 ? branches[1] : branches.first

            if Self.verbose {
                os_log("\(self.t)Loaded \(branches.count) branches for project")
            }
        } catch let error {
            os_log(.error, "\(self.t)❌ Failed to load branches: \(error.localizedDescription)")
        }
    }
}

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
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
