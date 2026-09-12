import KitGit
import LumiUI
import ProviderActivityHeatmap
import ProviderGit
import ProviderProjects
import SwiftUI

/// 工作区干净视图。
///
/// 当「当前项目已打开 + 未选中 commit + 工作区无未提交变更」时，作为主内容区
/// 的一块展示干净状态：顶部是提交活跃度热力图，下面是仓库信息、
/// Git 用户配置与用户预设（`CleanStateInfoView`）。其余情况（无项目 / 已选中 commit / 工作区有变更）
/// 渲染 `EmptyView` 且**不占任何布局**——变更列表由 CommitDetail 插件展示，
/// 两个插件的内容块互斥，避免在内容区 VStack 中叠加。
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
            if viewModel.isClean, let project = viewModel.project {
                cleanStateView(project: project)
            } else {
                // 不占布局：EmptyView 本身零尺寸，避免与 CommitDetail 的内容块
                // 在 VStack 中同时弹性拉伸。
                EmptyView()
            }
        }
    }

    // MARK: - Clean State View

    private func cleanStateView(project: Project) -> some View {
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
