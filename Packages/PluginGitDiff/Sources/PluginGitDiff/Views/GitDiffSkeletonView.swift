import LumiUI
import SwiftUI

/// Git diff 首屏加载骨架：保留代码面板的行号栏与多行文本结构，
/// 避免文件切换时右侧内容区域只剩一个孤立的 spinner。
struct GitDiffSkeletonView: View {
    private let rowCount: Int

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(rowCount: Int = 16) {
        self.rowCount = rowCount
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { index in
                    GitDiffSkeletonRow(index: index)

                    if index < rowCount - 1 {
                        AppDivider()
                            .opacity(0.35)
                    }
                }
            }
            .padding(.vertical, 8)
        }
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

private struct GitDiffSkeletonRow: View {
    @LumiTheme private var theme

    let index: Int

    private var codeWidthRatio: CGFloat {
        switch index % 5 {
        case 0: 0.42
        case 1: 0.72
        case 2: 0.58
        case 3: 0.86
        default: 0.64
        }
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 12) {
                skeletonBlock(width: 32, height: 9)

                skeletonBlock(
                    width: max(80, (proxy.size.width - 70) * codeWidthRatio),
                    height: 9
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 21)
    }

    private func skeletonBlock(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(theme.textSecondary.opacity(0.13))
            .frame(width: width, height: height)
    }
}
