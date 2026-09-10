import LumiUI
import ProviderCloneRepository
import ProviderProjects
import SwiftUI

/// 当前项目记录仍在列表中，但对应目录已从磁盘消失时显示的工作区视图。
@MainActor
struct ProjectMissingView: View {
    let project: Project
    let onRemoveProject: () -> Void
    @LumiTheme private var theme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            AppEmptyState(
                icon: "folder.badge.questionmark",
                title: LumiPluginLocalization.string("Project Not Found", bundle: .module),
                description: LumiPluginLocalization.string(
                    "The project directory no longer exists on disk.",
                    bundle: .module
                ),
                actionTitle: LumiPluginLocalization.string("Remove from Project List", bundle: .module),
                action: onRemoveProject
            )
            .frame(maxWidth: 500)

            AppCard(style: .subtle) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        LumiPluginLocalization.string("Project Path", bundle: .module),
                        systemImage: "folder"
                    )
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

            Text(LumiPluginLocalization.string(
                "You can remove this project from the project list, or move the directory back to the original location.",
                bundle: .module
            ))
            .font(.callout)
            .foregroundStyle(theme.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.surface)
    }
}

/// 根据根工作区状态选择无项目或项目缺失视图。
@MainActor
struct RootWorkspaceUnavailableView: View {
    @ObservedObject var model: RootWorkspaceModel
    let projects: any ProjectProviding
    let cloneProvider: (any CloneRepositoryProviding)?

    var body: some View {
        Group {
            switch model.state {
            case .noProject:
                NoProjectGuideView(projects: projects, cloneProvider: cloneProvider)
            case .projectMissing:
                if let project = model.project {
                    ProjectMissingView(
                        project: project,
                        onRemoveProject: { projects.removeProject(id: project.id) }
                    )
                } else {
                    NoProjectGuideView(projects: projects, cloneProvider: cloneProvider)
                }
            case .ready:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
