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
                    Button(action: onSwitch) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderless)
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
                    Button(BranchPluginLocalization.string("Rename Branch"), action: onRename)
                    Button(BranchPluginLocalization.string("Set upstream"), action: onSetUpstream)
                    Button(BranchPluginLocalization.string("Publish Branch"), action: onPublish)
                    Button(BranchPluginLocalization.string("Unset upstream"), action: onUnsetUpstream)
                    if !isSelected {
                        Divider()
                        Button(BranchPluginLocalization.string("Delete Local Branch"), role: .destructive) {
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
