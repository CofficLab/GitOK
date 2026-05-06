import SwiftUI

/// 显示单个冲突文件的行视图
struct ConflictResolverRow: View {
    let file: GitMergeFile
    let isSelected: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    let onReveal: () -> Void
    let onStage: (() -> Void)?
    let isBusy: Bool

    var body: some View {
        GlassCard(padding: DesignTokens.Spacing.compactPadding, borderIntensity: isSelected ? 0.12 : 0.05) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(file.state.tint.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: file.state.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(file.state.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text((file.path as NSString).lastPathComponent)
                        .font(DesignTokens.Typography.bodyEmphasized)
                        .foregroundColor(DesignTokens.Color.semantic.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text(file.state.title)
                            .foregroundColor(file.state.tint)
                        Text("•")
                        Text(file.path)
                    }
                        .font(DesignTokens.Typography.caption1)
                        .foregroundColor(DesignTokens.Color.semantic.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: DesignTokens.Spacing.xs) {
                    rowAction(icon: "arrow.up.right.square", help: "打开文件", action: onOpen)
                    rowAction(icon: "folder", help: "在 Finder 中显示", action: onReveal)

                    if let onStage {
                        rowAction(
                            icon: file.state == .unresolved ? "checkmark.circle" : "square.and.arrow.down",
                            tint: file.state.tint,
                            help: file.state == .unresolved ? "标记为已解决并暂存" : "暂存已解决文件",
                            action: onStage
                        )
                        .disabled(isBusy)
                        .opacity(isBusy ? 0.5 : 1.0)
                    }

                    if isSelected {
                        Text("Selected")
                            .font(DesignTokens.Typography.caption1)
                            .foregroundColor(DesignTokens.Color.semantic.info)
                    }

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? DesignTokens.Color.semantic.info : DesignTokens.Color.semantic.textTertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2, perform: onOpen)
            .onTapGesture(perform: onSelect)
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(isSelected ? DesignTokens.Color.semantic.info.opacity(0.35) : Color.clear, lineWidth: 1)
        )
    }

    private func rowAction(icon: String, tint: Color = DesignTokens.Color.semantic.textSecondary, help: String, action: @escaping () -> Void) -> some View {
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

private extension GitMergeFileState {
    var title: String {
        switch self {
        case .unresolved:
            return "未解决"
        case .pendingStage:
            return "待暂存"
        case .staged:
            return "已暂存"
        }
    }

    var iconName: String {
        switch self {
        case .unresolved:
            return "exclamationmark.triangle.fill"
        case .pendingStage:
            return "square.and.arrow.down"
        case .staged:
            return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .unresolved:
            return DesignTokens.Color.semantic.warning
        case .pendingStage:
            return DesignTokens.Color.semantic.info
        case .staged:
            return DesignTokens.Color.semantic.success
        }
    }
}
