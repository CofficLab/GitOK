import KitGit
import LumiUI
import SwiftUI

/// Commit 详情主内容视图。
///
/// 提交表单已由 PluginCommitForm 作为独立内容块贡献到主内容区顶部
/// （VStack 组合），本视图只负责 commit 详情 / 工作区变动列表部分：
/// 绑定插件自有的 `CommitDetailViewModel`，无选中 commit 时显示占位
/// （工作区变动列表），有选中时展示 commit 信息头 + 文件列表。文件列表选中
/// 某文件时通过注入的 intent 写入 Provider，右侧的 git diff 插件
/// （trailing pane）据此展示该文件的 diff——diff 渲染已从本视图拆分出去。
///
/// 「当前 commit / 当前文件 / 当前 commit 下的变动的文件」由
/// `ProjectProviding` 统一维护；视图只绑定注入的 ViewModel，用户操作通过
/// 插件定义注入的 intent 写回 Provider，不注册任何外部监听。
///
/// 尺寸约定：只有 commit 详情（`CommitDetailLayout`）由本视图统一用
/// `.frame(maxHeight: .infinity)` 弹性填充；工作区模式交给
/// `WorktreeChangesView` 自行决定尺寸——工作区干净时它渲染 `EmptyView`
/// 不占布局，干净状态视图由 `PluginWorktreeClean` 插件作为另一块内容展示。
struct CommitDetailView: View {
    @ObservedObject var viewModel: CommitDetailViewModel
    let onSelectFile: (String?) -> Void
    let onDataChanged: () -> Void

    var body: some View {
        if let commit = viewModel.selectedCommit,
           let projectURL = viewModel.selectedProjectURL {
            CommitDetailLayout(
                commit: commit,
                projectURL: projectURL,
                selectedFile: viewModel.selectedFile,
                changes: viewModel.currentCommitFiles ?? [],
                isLoadingChanges: viewModel.isLoadingCommitFiles && viewModel.currentCommitFiles == nil,
                loadError: viewModel.commitFilesLoadError,
                onSelectFile: onSelectFile
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // 无选中 commit 时展示工作区变动文件列表（用户点击工作区状态条触发）。
            // 尺寸由 WorktreeChangesView 自决：干净 → EmptyView 不占布局。
            WorktreeChangesView(
                viewModel: viewModel,
                onSelectFile: onSelectFile,
                onDataChanged: onDataChanged
            )
        }
    }
}
