import KitGit
import LumiUI
import ProviderActivityHeatmap
import ProviderGit
import ProviderProjects
import SwiftUI

/// 工作区概览视图。
///
/// 当「当前项目已打开 + 未选中 commit」时，作为主内容区的一块展示工作区
/// 概览：顶部是提交活跃度热力图，下面是项目语言、仓库信息、Git 用户配置
/// 与用户预设（`CleanStateInfoView`）。工作区干净与否都会展示——干净时
/// CommitDetail 插件渲染 `EmptyView` 不占布局，本视图占满内容区；有未提交
/// 变更时 CommitDetail 插件在工作区上方展示变更文件列表，本视图在其下方
/// 继续展示概览。
/// 其余情况（无项目 / 已选中 commit）渲染 `EmptyView` 且**不占任何布局**——
/// commit 详情由 CommitDetail 插件展示，两个插件的内容块互斥，避免在内容区
/// VStack 中叠加。
struct WorktreeCleanView: View {
    @ObservedObject var viewModel: WorktreeCleanViewModel
    @ObservedObject var activityHeatmapViewModel: WorktreeCleanActivityHeatmapViewModel
    @ObservedObject var projectLanguagesViewModel: WorktreeCleanProjectLanguagesViewModel
    let git: any GitProviding
    let openUserSettings: (() -> Void)?
    @LumiTheme private var theme

    init(
        viewModel: WorktreeCleanViewModel,
        activityHeatmapViewModel: WorktreeCleanActivityHeatmapViewModel,
        projectLanguagesViewModel: WorktreeCleanProjectLanguagesViewModel,
        git: any GitProviding,
        openUserSettings: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self._activityHeatmapViewModel = ObservedObject(wrappedValue: activityHeatmapViewModel)
        self._projectLanguagesViewModel = ObservedObject(wrappedValue: projectLanguagesViewModel)
        self.git = git
        self.openUserSettings = openUserSettings
    }

    var body: some View {
        Group {
            if let project = viewModel.project, !viewModel.hasSelectedCommit {
                overviewView(project: project)
            } else {
                // 不占布局：EmptyView 本身零尺寸，避免与 CommitDetail 的内容块
                // 在 VStack 中同时弹性拉伸。
                EmptyView()
            }
        }
    }

    // MARK: - Overview View

    private func overviewView(project: Project) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            WorktreeCleanActivityHeatmapView(viewModel: activityHeatmapViewModel)
                .frame(maxWidth: .infinity, alignment: .leading)

            WorktreeCleanProjectLanguagesView(viewModel: projectLanguagesViewModel)
                .frame(maxWidth: .infinity, alignment: .leading)

            CleanStateInfoView(
                project: project,
                viewModel: viewModel,
                git: git,
                openUserSettings: openUserSettings
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
