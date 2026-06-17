import GitOKCoreKit
import GitCoreKit
import GitOKUI
import SwiftUI

struct BranchRowView: View {
    let branch: GitBranchSummary
    let isSelected: Bool
    let onSwitch: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    let onPublish: () -> Void
    let onSetUpstream: () -> Void
    let onUnsetUpstream: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.system(size: 12))

            Text(branch.name)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .primary : .secondary)

            Spacer()

            HStack(spacing: 8) {
                if !isSelected {
                    AppIconButton(
                        systemImage: "checkmark",
                        tint: DesignTokens.Color.semantic.success
                    ) {
                        onSwitch()
                    }
                    .help(GitBranchPluginLocalization.string("Switch Branch"))
                } else {
                    AppTag(GitBranchPluginLocalization.string("Current"), style: .accent)
                }

                Menu {
                    AppContextMenuRow(GitBranchPluginLocalization.string("Rename Branch"), systemImage: "pencil", action: onRename)
                    AppContextMenuRow(GitBranchPluginLocalization.string("Set upstream"), systemImage: "link", action: onSetUpstream)
                    AppContextMenuRow(GitBranchPluginLocalization.string("Publish Branch"), systemImage: "icloud.and.arrow.up", action: onPublish)
                    AppContextMenuRow(GitBranchPluginLocalization.string("Unset upstream"), systemImage: "link.badge.minus", action: onUnsetUpstream)
                    if !isSelected {
                        Divider()
                        AppContextMenuRow(GitBranchPluginLocalization.string("Delete Local Branch"), systemImage: "trash", role: .destructive) {
                            showDeleteAlert = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .gitOKUISurface(
            style: isSelected ? .listRowSelected : .custom(.clear),
            cornerRadius: 4
        )
        .alert(GitBranchPluginLocalization.string("Confirm Delete Branch"), isPresented: $showDeleteAlert) {
            Button(GitBranchPluginLocalization.string("Cancel"), role: .cancel) {}
            Button(GitBranchPluginLocalization.string("Delete"), role: .destructive, action: onDelete)
        } message: {
            Text(String(format: GitBranchPluginLocalization.string("Are you sure you want to delete local branch \"%@\"? Git will prevent deleting unmerged branches."), branch.name))
        }
    }
}
