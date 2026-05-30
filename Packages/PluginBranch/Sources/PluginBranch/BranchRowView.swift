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
                    Button(action: onSwitch) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderless)
                } else {
                    Text(PluginBranchLocalization.string("Current"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }

                Menu {
                    Button(PluginBranchLocalization.string("Rename Branch"), action: onRename)
                    Button(PluginBranchLocalization.string("Set upstream"), action: onSetUpstream)
                    Button(PluginBranchLocalization.string("Publish Branch"), action: onPublish)
                    Button(PluginBranchLocalization.string("Unset upstream"), action: onUnsetUpstream)
                    if !isSelected {
                        Divider()
                        Button(PluginBranchLocalization.string("Delete Local Branch"), role: .destructive) {
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
        .alert(PluginBranchLocalization.string("Confirm Delete Branch"), isPresented: $showDeleteAlert) {
            Button(PluginBranchLocalization.string("Cancel"), role: .cancel) {}
            Button(PluginBranchLocalization.string("Delete"), role: .destructive, action: onDelete)
        } message: {
            Text(String(format: PluginBranchLocalization.string("Are you sure you want to delete local branch \"%@\"? Git will prevent deleting unmerged branches."), branch.name))
        }
    }
}
