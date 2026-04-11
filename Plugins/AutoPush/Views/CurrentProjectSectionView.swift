import SwiftUI
import LibGit2Swift

/// 当前项目的自动推送配置区块
struct CurrentProjectSectionView: View {
    let project: Project
    let branch: GitBranch
    @Binding var isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            
            configurationCard
        }
    }
    
    // MARK: - Subviews

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.blue)
            Text(String(localized: "Current Project", table: "AutoPush"))
                .font(.headline)
            Spacer()
        }
    }

    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            projectInfo
            Divider()
            toggleSection
            descriptionText
        }
        .padding()
        .background(cardBackground)
    }

    private var projectInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Text(project.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                branchInfo
                statusBadge
            }
        }
    }

    private var branchInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundColor(.purple)
            Text(branch.name)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if !project.isGitRepo {
            Label("Not a Git repository", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundColor(.red)
        } else if !hasRemoteBranch {
            Label("No remote repository", systemImage: "cloud")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }

    private var toggleSection: some View {
        HStack {
            Toggle(isOn: $isEnabled) {
                Text(String(localized: "Enable auto-push", table: "AutoPush"))
                    .fontWeight(.medium)
            }
            .toggleStyle(.switch)
            .disabled(!project.isGitRepo)
            .onChange(of: isEnabled) { _, newValue in
                onToggle(newValue)
            }

            Spacer()
        }
    }

    private var descriptionText: some View {
        Text(String(localized: "Enable auto-push will automatically push to remote repository every 30 seconds.", table: "AutoPush"))
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor))
    }
    
    private var hasRemoteBranch: Bool {
        (try? project.remoteList().isEmpty) == false
    }
}

#Preview("CurrentProjectSectionView") {
    // Preview 需要实际的 Project 和 GitBranch 对象，这里仅展示布局
    Text("CurrentProjectSectionView")
        .frame(width: 500)
        .padding()
}