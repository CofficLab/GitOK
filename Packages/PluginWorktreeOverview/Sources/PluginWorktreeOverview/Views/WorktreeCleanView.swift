import KitGit
import LumiUI
import ProviderActivityHeatmap
import ProviderGit
import ProviderProjects
import SwiftUI

/// 工作区概览视图。
///
/// 当「当前项目已打开 + 未选中 commit」时，作为主内容区的一块展示工作区
/// 概览：顶部是工作区状态提示（干净 / 有未提交变更）与提交活跃度热力图，
/// 下面是项目语言、仓库信息、Git 用户配置与用户预设（`CleanStateInfoView`）。
/// 工作区干净与否都会展示——干净时 CommitDetail 插件渲染 `EmptyView` 不占
/// 布局，本视图占满内容区；有未提交变更时 CommitDetail 插件在工作区上方
/// 展示变更文件列表，本视图在其下方继续展示概览。
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                statusBanner

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            theme.surface
        }
    }

    // MARK: - Status Banner

    /// 顶部工作区状态提示：干净 / 有未提交变更 / 首次检查中。
    private var statusBanner: some View {
        let isChecking = viewModel.isLoading && !viewModel.isClean && viewModel.changeCount == 0
        let isClean = viewModel.isClean

        return HStack(spacing: 8) {
            Image(systemName: isChecking
                  ? "arrow.triangle.2.circlepath"
                  : (isClean ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"))
                .font(.appCallout)
                .foregroundStyle(isChecking ? theme.textTertiary : (isClean ? theme.success : theme.warning))

            Text(statusText)
                .font(.appCallout)
                .foregroundStyle(theme.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface.opacity(0.72))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusText: String {
        if viewModel.isLoading && !viewModel.isClean && viewModel.changeCount == 0 {
            return loc("Checking worktree state...")
        }
        if viewModel.isClean {
            return loc("Worktree is clean")
        }
        return String(format: loc("%lld uncommitted changes"), viewModel.changeCount)
    }

    private func loc(_ key: String) -> String {
        WorktreeCleanLocalization.string(key, bundle: .module)
    }
}
