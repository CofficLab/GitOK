import AppKit
import ProjectSupportKit
import GitOKCoreKit
import SwiftUI

/// 配置行视图：显示单个项目分支的自动推送配置
struct ConfigRowView: View {
    let config: ProjectBranchAutoPushConfig
    let isCurrentProject: Bool
    let onToggle: (ProjectBranchAutoPushConfig) -> Void
    let onDelete: (ProjectBranchAutoPushConfig) -> Void

    var body: some View {
        AppSettingsRow(isHighlighted: isCurrentProject, verticalPadding: 8) {
            HStack(spacing: 12) {
                statusIndicator
                projectInfo
                Spacer()
                lastPushedTime
                toggleButton
                deleteButton
            }
        }
    }

    // MARK: - Subviews

    private var statusIndicator: some View {
        Circle()
            .fill(config.isEnabled ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
    }

    private var projectInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(config.projectTitle)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Text("/")
                    .foregroundColor(.secondary)

                Text(config.branchName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.purple)

                if isCurrentProject {
                    AppTag("Current", systemImage: "star.fill", style: .accent)
                }
            }

            Text(config.projectPath)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var lastPushedTime: some View {
        if let lastPushed = config.lastPushedAt {
            Text(String.localizedStringWithFormat(AutoPushPluginLocalization.string("Last pushed: %@"), formatDate(lastPushed)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var toggleButton: some View {
        Toggle(isOn: Binding(
            get: { config.isEnabled },
            set: { _ in onToggle(config) }
        )) {
            EmptyView()
        }
        .toggleStyle(.switch)
        .scaleEffect(0.9)
    }

    private var deleteButton: some View {
        AppIconButton(systemImage: "trash", tint: .red) {
            onDelete(config)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview("ConfigRowView") {
    let config = ProjectBranchAutoPushConfig(
        projectPath: "/Users/colorfy/Code/Project",
        branchName: "main",
        isEnabled: true,
        lastModified: Date(),
        lastPushedAt: Date().addingTimeInterval(-3600)
    )

    return ConfigRowView(
        config: config,
        isCurrentProject: true,
        onToggle: { _ in },
        onDelete: { _ in }
    )
    .frame(width: 600)
    .padding()
}
