import GitOKCoreKit
import GitCoreKit
import GitOKUI
import SwiftUI

struct StashRow: View {
    let stash: GitStashEntry
    let fallbackBranchName: String
    let isBusy: Bool
    let onBranch: () -> Void
    let onApply: () -> Void
    let onPop: () -> Void
    let onDrop: () -> Void

    @State private var showDropAlert = false
    @State private var isDiffExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(stash.index)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 28, height: 28)
                    .gitOKUISurface(style: .custom(.blue.opacity(0.10)), cornerRadius: 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(StashPresentation.displayMessage(for: stash, fallbackBranchName: fallbackBranchName))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)

                    HStack(spacing: 5) {
                        Text("stash@{\(stash.index)}")
                        Text("/")
                        Text(StashPresentation.displayBranchName(for: stash, fallbackBranchName: fallbackBranchName))
                        if let relativeDate = stash.relativeDate {
                            Text("/")
                            Text(relativeDate)
                        }
                        Text("/")
                        Text(StashPresentation.fileCountText(stash.changedFileCount))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                }

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    actionButton(icon: "arrow.triangle.branch", help: GitStashPluginLocalization.string("Create branch from stash"), action: onBranch)
                    actionButton(icon: "arrow.down.circle", help: GitStashPluginLocalization.string("Apply stash (keep stash)"), action: onApply)
                    actionButton(icon: "arrow.up.circle", help: GitStashPluginLocalization.string("Pop stash (apply and delete)"), action: onPop)
                    actionButton(icon: "trash", tint: .red, help: GitStashPluginLocalization.string("Delete stash")) {
                        showDropAlert = true
                    }
                }
                .disabled(isBusy)
            }

            if stash.diffPreview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                DisclosureGroup(isExpanded: $isDiffExpanded) {
                    ScrollView(.horizontal) {
                        Text(stash.diffPreview)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 170)
                    .gitOKUISurface(style: .subtle, cornerRadius: 6)
                } label: {
                    Label(GitStashPluginLocalization.string("Diff Preview"), systemImage: "doc.text.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .gitOKUISurface(style: .subtle, cornerRadius: 8)
        .alert(GitStashPluginLocalization.string("Confirm Delete Stash"), isPresented: $showDropAlert) {
            Button(GitStashPluginLocalization.string("Cancel"), role: .cancel) {}
            Button(GitStashPluginLocalization.string("Delete"), role: .destructive) {
                onDrop()
            }
        } message: {
            Text(GitStashPluginLocalization.string("Are you sure you want to delete stash@{%lld}? This action cannot be undone.", stash.index))
        }
    }

    private func actionButton(icon: String, tint: Color = .secondary, help: String, action: @escaping () -> Void) -> some View {
        AppIconButton(systemImage: icon, tint: tint, action: action)
        .help(help)
    }
}
