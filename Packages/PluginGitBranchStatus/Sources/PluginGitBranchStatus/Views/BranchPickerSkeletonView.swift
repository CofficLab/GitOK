import LumiUI
import SwiftUI

/// 分支选择弹层首屏加载骨架：模拟本地和远程分支行，
/// 让搜索弹层在读取分支期间保持稳定的列表结构。
struct BranchPickerSkeletonView: View {
    private let localRowCount: Int
    private let remoteRowCount: Int

    @LumiMotionPreferenceReader private var motionPreference
    @State private var isBreathing = false

    init(localRowCount: Int = 3, remoteRowCount: Int = 2) {
        self.localRowCount = localRowCount
        self.remoteRowCount = remoteRowCount
    }

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<localRowCount, id: \.self) { index in
                BranchPickerSkeletonRow(index: index, isRemote: false)
            }

            Divider()
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

            ForEach(0..<remoteRowCount, id: \.self) { index in
                BranchPickerSkeletonRow(index: index, isRemote: true)
            }
        }
        .padding(8)
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

private struct BranchPickerSkeletonRow: View {
    @LumiTheme private var theme

    let index: Int
    let isRemote: Bool

    private var nameWidth: CGFloat {
        switch index % 3 {
        case 0: 124
        case 1: 178
        default: 148
        }
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

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(theme.textSecondary.opacity(0.13))
                .frame(width: isRemote ? 14 : 12, height: 12)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
