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

    @State private var showDeleteAlert = false

    private var isSelected: Bool {
        selectedRemote?.id == remote.id
    }

    private var webLink: RemoteRepositoryFormRules.RemoteWebLink? {
        RemoteRepositoryFormRules.remoteWebLink(for: remote.url)
    }

    public var body: some View {
        AppSettingsRow(isSelected: isSelected, verticalPadding: 12) {
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
                            AppTag(
                                RemoteRepositoryPluginLocalization.string("Upstream"),
                                systemImage: "arrow.triangle.branch",
                                style: .accent
                            )
                        }
                    }

                    Text(remote.url)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let webLink {
                        HStack(spacing: 6) {
                            AppTag(webLink.provider.rawValue, systemImage: "network", style: .accent)

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

                    iconButton("trash", tint: .red, help: RemoteRepositoryPluginLocalization.string("Delete")) {
                        showDeleteAlert = true
                    }
                }
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

    private func iconButton(
        _ systemName: String,
        tint: Color? = nil,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        AppIconButton(systemImage: systemName, tint: tint, action: action)
        .help(help)
    }
}
