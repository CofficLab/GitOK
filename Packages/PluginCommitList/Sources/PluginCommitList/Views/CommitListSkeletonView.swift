import LumiUI
import SwiftUI

/// 提交列表加载骨架：模拟真实提交行的结构，避免加载时内容区域突然跳动。
struct CommitListSkeletonView: View {
    private let rowCount: Int

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(rowCount: Int = 8) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { index in
                CommitListSkeletonRow(showTag: index.isMultiple(of: 3))

                if index < rowCount - 1 {
                    AppDivider()
                }
            }
        }
        .padding(.vertical, 4)
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
    }
}

private struct CommitListSkeletonRow: View {
    @LumiTheme private var theme

    let showTag: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                skeletonBlock(height: 11)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showTag {
                    skeletonBlock(width: 42, height: 16)
                }
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(theme.textSecondary.opacity(0.13))
                    .frame(width: 16, height: 16)

                skeletonBlock(width: 76, height: 8)

                Spacer(minLength: 8)

                skeletonBlock(width: 88, height: 8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
    }

    private func skeletonBlock(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(theme.textSecondary.opacity(0.13))
            .frame(width: width, height: height)
    }
}
