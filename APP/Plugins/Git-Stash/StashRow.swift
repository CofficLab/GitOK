import GitCoreKit
import SwiftUI

/// 显示单个stash项的行视图
struct StashRow: View {
    let stash: GitStashEntry
    let branchName: String
    let onBranch: () -> Void
    let onApply: () -> Void
    let onPop: () -> Void
    let onDrop: () -> Void

    @State private var showDropAlert = false
    @State private var isDiffExpanded = false

    var body: some View {
        GlassCard(padding: DesignTokens.Spacing.compactPadding, borderIntensity: 0.06) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(DesignTokens.Color.semantic.info.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Text("\(stash.index)")
                            .font(DesignTokens.Typography.caption1.weight(.semibold))
                            .foregroundColor(DesignTokens.Color.semantic.info)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(stash.message.isEmpty ? String(localized: "WIP on \(displayBranchName)", table: "GitStash") : stash.message)
                            .font(DesignTokens.Typography.bodyEmphasized)
                            .foregroundColor(DesignTokens.Color.semantic.textPrimary)
                            .lineLimit(2)

                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text(String(localized: "stash@{\(stash.index)}", table: "GitStash"))
                            Text("•")
                            Text(displayBranchName)
                            if let relativeDate = stash.relativeDate {
                                Text("•")
                                Text(relativeDate)
                            }
                            Text("•")
                            Text(String(localized: "\(stash.changedFileCount) files", table: "GitStash"))
                        }
                        .font(DesignTokens.Typography.caption1)
                        .foregroundColor(DesignTokens.Color.semantic.textTertiary)
                    }

                    Spacer(minLength: DesignTokens.Spacing.sm)

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        actionButton(icon: "arrow.triangle.branch", help: String(localized: "Create branch from stash", table: "GitStash"), action: onBranch)
                        actionButton(icon: "arrow.down.circle", help: String(localized: "Apply stash (keep stash)", table: "GitStash"), action: onApply)
                        actionButton(icon: "arrow.up.circle", help: String(localized: "Pop stash (apply and delete)", table: "GitStash"), action: onPop)
                        actionButton(icon: "trash", tint: DesignTokens.Color.semantic.error, help: String(localized: "Delete stash", table: "GitStash")) {
                            showDropAlert = true
                        }
                    }
                }

                if stash.diffPreview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    DisclosureGroup(isExpanded: $isDiffExpanded) {
                        ScrollView(.horizontal) {
                            Text(stash.diffPreview)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                                .textSelection(.enabled)
                                .padding(DesignTokens.Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 180)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .fill(DesignTokens.Material.glass.opacity(0.08))
                        )
                    } label: {
                        Label(String(localized: "Diff Preview", table: "GitStash"), systemImage: "doc.text.magnifyingglass")
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.textSecondary)
                    }
                    .disclosureGroupStyle(.automatic)
                }
            }
        }
        .alert(String(localized: "Confirm Delete Stash"), isPresented: $showDropAlert) {
            Button(String(localized: "Cancel"), role: .cancel) { }
            Button(String(localized: "Delete"), role: .destructive) {
                onDrop()
            }
        } message: {
            Text(String(localized: "Are you sure you want to delete stash@{\(stash.index)}? This action cannot be undone."))
        }
    }

    private var displayBranchName: String {
        stash.branchName ?? branchName
    }

    private func actionButton(icon: String, tint: Color = DesignTokens.Color.semantic.textSecondary, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(tint)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .fill(DesignTokens.Material.glass.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
