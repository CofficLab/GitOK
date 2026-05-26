import MagicKit
import LibGit2Swift
import ProjectRulesKit
import SwiftUI

struct RemoteRepositoryRowView: View {
    let remote: GitRemote
    let selectedRemote: GitRemote?
    let isCurrentUpstreamRemote: Bool
    let onSelect: (GitRemote) -> Void
    let onEdit: (GitRemote) -> Void
    let onDelete: (GitRemote) -> Void

    @State private var isHovered = false
    @State private var showDeleteAlert = false

    private var isSelected: Bool {
        selectedRemote?.id == remote.id
    }

    private var backgroundColorForState: Color {
        if isHovered {
            return isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var borderColorForState: Color {
        if isHovered {
            return isSelected ? Color.blue.opacity(0.9) : Color.gray.opacity(0.5)
        } else if isSelected {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private var webLink: RemoteRepositoryFormRules.RemoteWebLink? {
        RemoteRepositoryFormRules.remoteWebLink(for: remote.url)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Remote Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(remote.name)
                        .font(.headline)
                        .fontWeight(.medium)

                    if remote.isDefault {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }

                    if isCurrentUpstreamRemote {
                        Text("Upstream")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                    }
                }

                Text(remote.url)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let webLink {
                    HStack(spacing: 6) {
                        Text(webLink.provider.rawValue)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)

                        Text(webLink.authenticationNote)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                if let fetchURL = remote.fetchURL, fetchURL != remote.url {
                    HStack {
                        Text("获取:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(fetchURL)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                if let pushURL = remote.pushURL, pushURL != remote.url {
                    HStack {
                        Text("推送:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(pushURL)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 8) {
                if let webLink {
                    Image.safari.inButtonWithAction {
                        webLink.url.openInBrowser()
                    }
                    .help("打开远程页面")
                }

                Image.copyIcon.inButtonWithAction {
                    remote.url.copy()
                }
                .help("复制远程 URL")

                Image.edit.inButtonWithAction {
                    onEdit(remote)
                }

                Image.trash.inButtonWithAction {
                    showDeleteAlert = true
                }
            }
            .transition(.opacity.combined(with: .scale))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColorForState)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColorForState, lineWidth: 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect(remote)
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete(remote)
            }
        } message: {
            Text(deleteWarningMessage)
        }
    }

    private var deleteWarningMessage: String {
        RemoteRepositoryFormRules.deleteWarning(
            remoteName: remote.name,
            isCurrentUpstreamRemote: isCurrentUpstreamRemote
        )
    }
}
