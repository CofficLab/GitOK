import LumiUI
import SwiftUI

/// LICENSE 文档内容加载骨架：模拟等宽文本行，
/// 保持查看器在读取文件时的内容密度和滚动区域高度。
struct LicenseSkeletonView: View {
    private let lineCount: Int

    @LumiTheme private var theme
    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(lineCount: Int = 12) {
        self.lineCount = lineCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lineCount, id: \.self) { index in
                LicenseSkeletonLine(index: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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

private struct LicenseSkeletonLine: View {
    @LumiTheme private var theme

    let index: Int

    private var width: CGFloat {
        switch index % 4 {
        case 0: 232
        case 1: 284
        case 2: 174
        default: 316
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(theme.textSecondary.opacity(0.13))
            .frame(width: width, height: 10)
    }
}
