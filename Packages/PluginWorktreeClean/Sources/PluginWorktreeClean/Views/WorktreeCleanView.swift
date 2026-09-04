import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// 工作区干净视图。
///
/// 当「当前项目已打开 + 未选中 commit + 工作区无未提交变更」时，作为主内容区
/// 的一块展示干净状态：绿色对勾提示 + 仓库信息与 Git 用户配置
/// （`CleanStateInfoView`）。其余情况（无项目 / 已选中 commit / 工作区有变更）
/// 渲染 `EmptyView` 且**不占任何布局**——变更列表由 CommitDetail 插件展示，
/// 两个插件的内容块互斥，避免在内容区 VStack 中叠加。
struct WorktreeCleanView: View {
    @ObservedObject var viewModel: WorktreeCleanViewModel
    @LumiTheme private var theme

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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text(loc("Working Tree Clean"))
                        .font(.title3)
                        .fontWeight(.medium)

                    Text(loc("No uncommitted changes."))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)

                CleanStateInfoView(project: project)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            theme.surface
        }
    }
}
