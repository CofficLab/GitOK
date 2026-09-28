import LumiUI
import SwiftUI

/// 远程仓库列表首屏加载骨架：模拟远程名称、URL 和操作按钮，
/// 让面板在读取 Git remote 时保持稳定的列表结构。
struct RemoteRepositorySkeletonView: View {
    private let rowCount: Int

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(rowCount: Int = 3) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<rowCount, id: \.self) { index in
                RemoteRepositorySkeletonRow(index: index)
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
        .accessibilityHidden(true)
    }
}

private struct RemoteRepositorySkeletonRow: View {
    @LumiTheme private var theme

    let index: Int

    private var nameWidth: CGFloat {
        index.isMultiple(of: 2) ? 92 : 128
    }

    private var urlWidth: CGFloat {
        index.isMultiple(of: 2) ? 230 : 178
    }

    var body: some View {
        HStack(spacing: 8) {
            skeletonBlock(width: 18, height: 18, cornerRadius: 9)

            VStack(alignment: .leading, spacing: 4) {
                skeletonBlock(width: nameWidth, height: 10)
                skeletonBlock(width: urlWidth, height: 8)
            }

            Spacer(minLength: 8)

            skeletonBlock(width: 18, height: 18, cornerRadius: 4)
            skeletonBlock(width: 18, height: 18, cornerRadius: 4)
            skeletonBlock(width: 18, height: 18, cornerRadius: 4)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func skeletonBlock(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 4
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(theme.textSecondary.opacity(0.13))
            .frame(width: width, height: height)
    }
}
