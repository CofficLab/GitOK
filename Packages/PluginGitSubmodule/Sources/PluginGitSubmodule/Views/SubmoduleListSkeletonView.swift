import LumiUI
import SwiftUI

/// 子模块列表首屏加载骨架：保留路径和远程地址的两行结构，
/// 避免弹窗在读取子模块时只显示一个空白转圈。
struct SubmoduleListSkeletonView: View {
    private let rowCount: Int

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(rowCount: Int = 3) {
        self.rowCount = rowCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rowCount, id: \.self) { index in
                SubmoduleListSkeletonRow(index: index)
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

private struct SubmoduleListSkeletonRow: View {
    @LumiTheme private var theme

    let index: Int

    private var pathWidth: CGFloat {
        index.isMultiple(of: 2) ? 136 : 184
    }

    private var urlWidth: CGFloat {
        index.isMultiple(of: 2) ? 218 : 172
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            skeletonBlock(width: pathWidth, height: 10)
            skeletonBlock(width: urlWidth, height: 8)
        }
        .padding(.vertical, 4)
    }

    private func skeletonBlock(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(theme.textSecondary.opacity(0.13))
            .frame(width: width, height: height)
    }
}
