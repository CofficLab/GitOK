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

            // 图标
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(theme.textTertiary)

            // 标题
            Text(loc("Project Not Found"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(theme.textPrimary)

            // 描述
            VStack(spacing: 8) {
                Text(loc("The project directory no longer exists on disk."))
                    .font(.body)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)

                Text(project.url.path)
                    .font(.callout.monospaced())
                    .foregroundStyle(theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .truncationMode(.middle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(theme.textTertiary.opacity(0.08))
                    )
            }

            // 提示
            Text(loc("You can remove this project from the project list, or move the directory back to the original location."))
                .font(.callout)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            // 操作按钮
            if let onRemoveProject {
                Button(role: .destructive) {
                    onRemoveProject()
                } label: {
                    Label(loc("Remove from Project List"), systemImage: "trash")
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.error)
                .padding(.top, 8)
            }

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
