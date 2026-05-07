import SwiftUI

/// 显示单个stash项的行视图
struct StashRow: View {
    let stash: (index: Int, message: String)
    let branchName: String
    let onApply: () -> Void
    let onPop: () -> Void
    let onDrop: () -> Void

    @State private var showDropAlert = false

    var body: some View {
        GlassCard(padding: DesignTokens.Spacing.compactPadding, borderIntensity: 0.06) {
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
                    Text(stash.message.isEmpty ? "WIP on \(branchName)" : stash.message)
                        .font(DesignTokens.Typography.bodyEmphasized)
                        .foregroundColor(DesignTokens.Color.semantic.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text("stash@{\(stash.index)}")
                        Text("•")
                        Text(branchName)
                    }
                    .font(DesignTokens.Typography.caption1)
                    .foregroundColor(DesignTokens.Color.semantic.textTertiary)
                }

                Spacer(minLength: DesignTokens.Spacing.sm)

                HStack(spacing: DesignTokens.Spacing.xs) {
                    actionButton(icon: "arrow.down.circle", help: "应用stash（保留stash）", action: onApply)
                    actionButton(icon: "arrow.up.circle", help: "弹出stash（应用并删除stash）", action: onPop)
                    actionButton(icon: "trash", tint: DesignTokens.Color.semantic.error, help: "删除stash") {
                        showDropAlert = true
                    }
                }
            }
        }
        .alert("确认删除stash", isPresented: $showDropAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDrop()
            }
        } message: {
            Text("确定要删除stash@{\(stash.index)}吗？此操作不可撤销。")
        }
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
