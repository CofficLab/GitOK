import SwiftUI

/// 显示单个stash项的行视图
struct StashRow: View {
    let stash: (index: Int, message: String)
    let onApply: () -> Void
    let onPop: () -> Void
    let onDrop: () -> Void

    @State private var showDropAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Stash 索引
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Text("\(stash.index)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }

                // Stash 信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(stash.message.isEmpty ? "WIP on \(getCurrentBranch())" : stash.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text("stash@{\(stash.index)}")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 操作按钮
                HStack(spacing: 8) {
                    Button(action: onApply) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .help("应用stash（保留stash）")

                    Button(action: onPop) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .help("弹出stash（应用并删除stash）")

                    Button(action: {
                        showDropAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("删除stash")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .alert("确认删除stash", isPresented: $showDropAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDrop()
            }
        } message: {
            Text("确定要删除stash@{\(stash.index)}吗？此操作不可撤销。")
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }

    /// 获取当前分支名（简化实现）
    private func getCurrentBranch() -> String {
        // 这里应该从数据提供者获取当前分支
        // 暂时返回默认值
        return "main"
    }
}