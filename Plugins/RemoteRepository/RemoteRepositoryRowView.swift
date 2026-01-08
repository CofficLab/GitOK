import MagicCore
import MagicShell
import MagicUI
import SwiftUI

struct RemoteRepositoryRowView: View {
    let remote: GitRemote
    let selectedRemote: GitRemote?
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
                }

                Text(remote.url)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let fetchURL = remote.fetchURL, fetchURL != remote.url {
                    HStack {
                        Text("Fetch:")
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
                        Text("Push:")
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
                MagicButton(icon: .iconEdit, action: { completion in
                    onEdit(remote)
                    completion()
                })
                .help("编辑")

                MagicButton(icon: .iconTrash, action: { completion in
                    showDeleteAlert = true
                    completion()
                })
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .help("删除")
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
            Text("确定要删除远程仓库 \"\(remote.name)\" 吗？此操作不可撤销。")
        }
    }
}
