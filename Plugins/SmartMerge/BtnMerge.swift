
import MagicAlert
import MagicKit
import LibGit2Swift
import OSLog
import SwiftUI

/// 分支合并按钮组件：提供将一个分支合并到另一个分支的功能
/// 执行 git checkout 和 git merge 命令，并在操作完成后显示结果消息
struct BtnMerge: View, SuperEvent, SuperThread, SuperLog {
    /// 是否启用详细日志输出
    nonisolated static let emoji = "🔀"
    nonisolated static let verbose = false

    /// 环境对象：消息提供者
    @EnvironmentObject var m: MagicMessageProvider

    /// 项目路径
    var path: String
    /// 源分支（要合并的分支）
    var from: GitBranch
    /// 目标分支（合并到的分支）
    var to: GitBranch

    /// 是否正在悬停
    @State private var isHovering = false

    var body: some View {
        Button("Merge", action: merge)
            .help("合并分支")
            .padding()
            .cornerRadius(8)
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

// MARK: - Action

extension BtnMerge {
    /// 执行分支合并操作
    /// 先切换到目标分支，然后将源分支合并到当前分支
    func merge() {
        do {
            try LibGit2.checkout(branch: to.name, at: path)

            // 发布分支切换事件
            let project = Project(URL(fileURLWithPath: path))
            project.postEvent(name: .projectDidChangeBranch, operation: "checkout",
                              additionalInfo: ["branch": to.name, "reason": "merge_setup"])

            try LibGit2.merge(branchName: from.name, at: path)

            // 发布合并成功事件
            project.postEvent(name: .projectDidMerge, operation: "merge",
                              additionalInfo: ["fromBranch": from.name, "toBranch": to.name])

            self.m.info("已将 \(from.name) 合并到 \(to.name), 并切换到 \(to.name)")
        } catch let error {
            os_log(.error, "\(self.t)❌ 分支合并失败: \(error.localizedDescription)")

            // 发布合并失败事件
            let project = Project(URL(fileURLWithPath: path))
            project.postEvent(name: .projectOperationDidFail, operation: "merge", success: false, error: error,
                              additionalInfo: ["fromBranch": from.name, "toBranch": to.name])

            m.error(error)
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
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
