import LumiUI
import SwiftUI

/// 工作区变更列表加载骨架：模拟文件行结构，减少首次加载时的布局跳动。
struct WorktreeChangesSkeletonView: View {
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
                WorktreeChangesSkeletonRow(showStageAction: index.isMultiple(of: 2))

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

private struct WorktreeChangesSkeletonRow: View {
    @LumiTheme private var theme

    let showStageAction: Bool

    var body: some View {
        HStack(spacing: 8) {
            skeletonBlock(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 5) {
                skeletonBlock(height: 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 5) {
                    skeletonBlock(width: 16, height: 12)
                    skeletonBlock(width: 62, height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            if showStageAction {
                skeletonBlock(width: 18, height: 18)
            }
            skeletonBlock(width: 18, height: 18)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(theme.textTertiary.opacity(0.24))
                .frame(width: 3)
                .allowsHitTesting(false)
        }
    }

    private func skeletonBlock(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(theme.textSecondary.opacity(0.13))
            .frame(width: width, height: height)
    }
}
