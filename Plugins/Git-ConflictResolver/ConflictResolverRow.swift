import SwiftUI

/// 显示单个冲突文件的行视图
struct ConflictResolverRow: View {
    let filePath: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 冲突图标
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }

                // 文件信息
                VStack(alignment: .leading, spacing: 2) {
                    Text((filePath as NSString).lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Text(filePath)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 选择指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
        }
        .background(
            isSelected ?
                Color.blue.opacity(0.1) :
                Color(NSColor.controlBackgroundColor)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}