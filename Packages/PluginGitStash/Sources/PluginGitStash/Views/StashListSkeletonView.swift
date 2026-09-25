import LumiUI
import SwiftUI

/// stash 列表首屏加载骨架：模拟消息、索引和操作按钮，
/// 让面板在读取 stash 时保持稳定的列表结构。
struct StashListSkeletonView: View {
    private let rowCount: Int

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(rowCount: Int = 3) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<rowCount, id: \.self) { index in
                StashListSkeletonRow(index: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(
            motionPreference.allowsMotion
                ? (isBreathing ? 0.58 : 0.86)
                : 0.72
        )
        .animation(
            motionPreference.allowsMotion
                ? .easeInOut(duration: 1.15).repeatForever(autoreverses: true)
                : nil,
            value: isBreathing
        )
        .onAppear {
            isBreathing = motionPreference.allowsMotion
        }
        .onChange(of: motionPreference.allowsMotion) { _, allowsMotion in
            isBreathing = allowsMotion
        }
        .accessibilityHidden(true)
    }
}

private struct StashListSkeletonRow: View {
    @LumiTheme private var theme

    let index: Int

    private var messageWidth: CGFloat {
        index.isMultiple(of: 2) ? 196 : 142
    }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(theme.textSecondary.opacity(0.13))
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(theme.textSecondary.opacity(0.13))
                    .frame(width: messageWidth, height: 10)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(theme.textSecondary.opacity(0.13))
                    .frame(width: 72, height: 8)
            }

            Spacer(minLength: 8)

            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(theme.textSecondary.opacity(0.13))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
