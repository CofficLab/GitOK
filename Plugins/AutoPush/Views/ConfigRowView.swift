import SwiftUI

/// 配置行视图：显示单个项目分支的自动推送配置
struct ConfigRowView: View {
    let config: ProjectBranchAutoPushConfig
    let isCurrentProject: Bool
    let onToggle: (ProjectBranchAutoPushConfig) -> Void
    let onDelete: (ProjectBranchAutoPushConfig) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态指示器
            statusIndicator
            
            // 项目信息
            projectInfo
            
            Spacer()
            
            // 最后推送时间
            lastPushedTime
            
            // 切换开关
            toggleButton
            
            // 删除按钮
            deleteButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundStyle)
        .onHover { hovering in
            withAnimation {
                isHovering = hovering
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
                    Label("Current", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
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
            Text(String(localized: "Last pushed: \(formatDate(lastPushed))", table: "AutoPush"))
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
        Button(action: { onDelete(config) }) {
            Image(systemName: "trash")
                .foregroundColor(.red)
        }
        .buttonStyle(.borderless)
        .opacity(isHovering ? 1 : 0)
    }
    
    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isHovering ? Color(NSColor.controlBackgroundColor) : Color.clear)
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