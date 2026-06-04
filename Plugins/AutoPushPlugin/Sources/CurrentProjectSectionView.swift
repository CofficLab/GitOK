import GitOKCoreKit
import GitCoreKit
import SwiftUI

struct CurrentProjectSectionView: View {
    let project: AutoPushProjectSnapshot
    @Binding var isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                Text(AutoPushPluginLocalization.string("Current Project"))
                    .font(.headline)
                Spacer()
            }

            AppSettingsRow(verticalPadding: 12) {
                VStack(alignment: .leading, spacing: 8) {
                projectInfo
                Divider()
                toggleSection
                Text(AutoPushPluginLocalization.string("Enable auto-push will automatically push to remote repository every 30 seconds."))
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private var projectInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.projectTitle)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Text(project.projectPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let branchName = project.branchName {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.purple)
                        Text(branchName)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                }

                if !project.isGitRepository {
                    AppTag(AutoPushPluginLocalization.string("Not a Git repository"), systemImage: "exclamationmark.triangle")
                } else if !hasRemoteBranch {
                    AppTag(AutoPushPluginLocalization.string("No remote repository"), systemImage: "cloud")
                }
            }
        }
    }

    private var toggleSection: some View {
        AppToggleRow(
            title: AutoPushPluginLocalization.string("Enable auto-push"),
            systemImage: "arrow.up.circle",
            isOn: $isEnabled
        )
        .disabled(!project.isGitRepository || project.branchName == nil)
        .onChange(of: isEnabled) { _, newValue in
            onToggle(newValue)
        }
    }

    private var hasRemoteBranch: Bool {
        ((try? GitRepositoryCLI(repositoryURL: URL(fileURLWithPath: project.projectPath)).remoteNames()) ?? []).isEmpty == false
    }
}
