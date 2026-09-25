import LumiUI
import SwiftUI

/// 分支管理页首屏加载骨架：模拟本地分支名称、当前标记和操作按钮，
/// 让分支列表在读取期间保持稳定的内容结构。
struct BranchManagementSkeletonView: View {
    private let rowCount: Int

    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(rowCount: Int = 3) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rowCount, id: \.self) { index in
                BranchManagementSkeletonRow(index: index)
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

private struct BranchManagementSkeletonRow: View {
    @LumiTheme private var theme

    let index: Int

    private var nameWidth: CGFloat {
        index.isMultiple(of: 2) ? 160 : 112
    }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(theme.textSecondary.opacity(0.13))
                .frame(width: 14, height: 14)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(theme.textSecondary.opacity(0.13))
                .frame(width: nameWidth, height: 10)

            Spacer(minLength: 8)

            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(theme.textSecondary.opacity(0.13))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
