import LumiUI
import ProviderProjects
import SwiftUI

private func loc(_ key: String) -> String {
    ProjectMissingLocalization.string(key, bundle: .module)
}

/// 项目缺失视图。
///
/// 当「当前项目已打开 + 项目目录在磁盘上不存在」时，作为主内容区的一块
/// 展示友好提示，告知用户项目已丢失。其余情况（无项目 / 项目存在）
/// 渲染 `EmptyView` 且**不占任何布局**——与其他内容插件互斥。
struct ProjectMissingView: View {
    @ObservedObject var viewModel: ProjectMissingViewModel
    let onRemoveProject: (() -> Void)?
    @LumiTheme private var theme

    init(
        viewModel: ProjectMissingViewModel,
        onRemoveProject: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onRemoveProject = onRemoveProject
    }

    var body: some View {
        Group {
            if viewModel.isMissing, let project = viewModel.project {
                missingProjectView(project: project)
            } else {
                // 不占布局：EmptyView 本身零尺寸，避免与其他内容插件
                // 在 VStack 中同时弹性拉伸。
                EmptyView()
            }
        }
    }

    // MARK: - Missing Project View

    private func missingProjectView(project: Project) -> some View {
        VStack(spacing: 20) {
            Spacer()

            // 主内容区：使用 AppEmptyState 展示核心信息
            AppEmptyState(
                icon: "folder.badge.questionmark",
                title: loc("Project Not Found"),
                description: loc("The project directory no longer exists on disk."),
                actionTitle: onRemoveProject != nil ? loc("Remove from Project List") : "",
                action: onRemoveProject ?? {}
            )
            .frame(maxWidth: 500)

            // 项目路径信息卡片
            AppCard(style: .subtle) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(loc("Project Path"), systemImage: "folder")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.textSecondary)

                    Text(project.url.path)
                        .font(.callout.monospaced())
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 500)

            // 提示文字
            Text(loc("You can remove this project from the project list, or move the directory back to the original location."))
                .font(.callout)
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            theme.surface
        }
    }
}
