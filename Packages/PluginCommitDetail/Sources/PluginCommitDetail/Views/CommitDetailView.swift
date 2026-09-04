import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

/// Commit 详情主内容视图。
///
/// 提交表单已由 PluginCommitForm 作为独立内容块贡献到主内容区顶部
/// （VStack 组合），本视图只负责 commit 详情 / 工作区变动列表部分：
/// 绑定插件自有的 `CommitDetailViewModel`，无选中 commit 时显示占位
/// （工作区变动列表），有选中时展示 commit 信息头 + 文件列表。文件列表选中
/// 某文件时通过 `projects.selectFile` 写入 Provider，右侧的 git diff 插件
/// （trailing pane）据此展示该文件的 diff——diff 渲染已从本视图拆分出去。
///
/// 「当前 commit / 当前文件 / 当前 commit 下的变动的文件」由
/// `ProjectProviding` 统一维护；视图只绑定注入的 ViewModel 与 Provider 的
/// 写操作，不再注册任何插件级外部监听（选中状态 / 仓库数据变化由
/// `CommitDetailObserver` 负责翻译进 ViewModel）。
struct CommitDetailView: View {
    let projects: any ProjectProviding
    @ObservedObject var viewModel: CommitDetailViewModel

    var body: some View {
        Group {
            if let commit = viewModel.selectedCommit,
               let projectURL = viewModel.selectedProjectURL {
                CommitDetailLayout(
                    commit: commit,
                    projectURL: projectURL,
                    selectedFile: viewModel.selectedFile,
                    changes: viewModel.currentCommitFiles ?? [],
                    isLoadingChanges: viewModel.isLoadingCommitFiles && viewModel.currentCommitFiles == nil,
                    loadError: viewModel.commitFilesLoadError,
                    onSelectFile: { projects.selectFile($0) }
                )
            } else {
                // 无选中 commit 时展示工作区变动文件列表（用户点击工作区状态条触发）。
                WorktreeChangesView(projects: projects, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
