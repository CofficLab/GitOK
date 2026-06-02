import AppKit
import ProjectRulesKit
import GitCoreKit
import GitOKCoreKit
import SwiftUI

public struct RemoteRepositoryRowView: View {
    let remote: GitRemoteSummary
    let selectedRemote: GitRemoteSummary?
    let isCurrentUpstreamRemote: Bool
    let onSelect: (GitRemoteSummary) -> Void
    let onEdit: (GitRemoteSummary) -> Void
    let onDelete: (GitRemoteSummary) -> Void

    @State private var isHovered = false
    @State private var showDeleteAlert = false

    private var isSelected: Bool {
        selectedRemote?.id == remote.id
    }

    private var webLink: RemoteRepositoryFormRules.RemoteWebLink? {
        RemoteRepositoryFormRules.remoteWebLink(for: remote.url)
    }

    public var body: some View {
        HStack(spacing: 12) {
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
                        Text(RemoteRepositoryPluginLocalization.string("Upstream"))
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
                    }
                }

                if let fetchURL = remote.fetchURL, fetchURL != remote.url {
                    remoteURLLine(label: "Fetch:", value: fetchURL)
                }

                if let pushURL = remote.pushURL, pushURL != remote.url {
                    remoteURLLine(label: "Push:", value: pushURL)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if let webLink {
                    iconButton("safari", help: RemoteRepositoryPluginLocalization.string("Open Remote Page")) {
                        NSWorkspace.shared.open(webLink.url)
                    }
                }

                iconButton("doc.on.doc", help: RemoteRepositoryPluginLocalization.string("Copy Remote URL")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(remote.url, forType: .string)
                }

                iconButton("pencil", help: RemoteRepositoryPluginLocalization.string("Edit")) {
                    onEdit(remote)
                }

                iconButton("trash", help: RemoteRepositoryPluginLocalization.string("Delete")) {
                    showDeleteAlert = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect(remote)
        }
        .alert(RemoteRepositoryPluginLocalization.string("Confirm Delete"), isPresented: $showDeleteAlert) {
            Button(RemoteRepositoryPluginLocalization.string("Cancel"), role: .cancel) {}
            Button(RemoteRepositoryPluginLocalization.string("Delete"), role: .destructive) {
                onDelete(remote)
            }
        } message: {
            Text(RemoteRepositoryFormRules.deleteWarning(remoteName: remote.name, isCurrentUpstreamRemote: isCurrentUpstreamRemote))
        }
    }

    private var backgroundColor: Color {
        if isHovered {
            return isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08)
        }

        return isSelected ? Color.blue.opacity(0.1) : Color.clear
    }

    private var borderColor: Color {
        if isHovered {
            return isSelected ? Color.blue.opacity(0.9) : Color.gray.opacity(0.5)
        }

        return isSelected ? Color.blue : Color.gray.opacity(0.3)
    }

    private func remoteURLLine(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func iconButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}
