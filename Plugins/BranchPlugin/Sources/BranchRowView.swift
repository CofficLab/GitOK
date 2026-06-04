import GitOKCoreKit
import GitCoreKit
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
                    .help(BranchPluginLocalization.string("Switch Branch"))
                } else {
                    Text(BranchPluginLocalization.string("Current"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }

                Menu {
                    AppContextMenuRow(BranchPluginLocalization.string("Rename Branch"), systemImage: "pencil", action: onRename)
                    AppContextMenuRow(BranchPluginLocalization.string("Set upstream"), systemImage: "link", action: onSetUpstream)
                    AppContextMenuRow(BranchPluginLocalization.string("Publish Branch"), systemImage: "icloud.and.arrow.up", action: onPublish)
                    AppContextMenuRow(BranchPluginLocalization.string("Unset upstream"), systemImage: "link.badge.minus", action: onUnsetUpstream)
                    if !isSelected {
                        Divider()
                        AppContextMenuRow(BranchPluginLocalization.string("Delete Local Branch"), systemImage: "trash", role: .destructive) {
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
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .alert(BranchPluginLocalization.string("Confirm Delete Branch"), isPresented: $showDeleteAlert) {
            Button(BranchPluginLocalization.string("Cancel"), role: .cancel) {}
            Button(BranchPluginLocalization.string("Delete"), role: .destructive, action: onDelete)
        } message: {
            Text(String(format: BranchPluginLocalization.string("Are you sure you want to delete local branch \"%@\"? Git will prevent deleting unmerged branches."), branch.name))
        }
    }
}
