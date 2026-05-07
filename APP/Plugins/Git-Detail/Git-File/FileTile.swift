import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 文件状态显示组件：显示单个文件的Git状态和操作选项
struct FileTile: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📄"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// Git 差异文件对象
    var file: GitDiffFile

    /// 丢弃更改的回调函数
    var onDiscardChanges: ((GitDiffFile) -> Void)?

    /// 是否显示详细信息弹窗
    @State var isPresented: Bool = false

    /// 是否显示丢弃更改确认对话框
    @State private var showDiscardAlert = false

    var body: some View {
        HStack(spacing: 12) {
            Text(file.file)
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(.primary)

            Spacer()

            statusIcon
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 8)
        .cornerRadius(4)
        .contextMenu {
            if onDiscardChanges != nil {
                Button("丢弃更改") {
                    showDiscardAlert = true
                }
            }
        }
        .alert("确认丢弃更改", isPresented: $showDiscardAlert) {
            Button("取消", role: .cancel) { }
            Button("丢弃", role: .destructive) {
                if let onDiscardChanges = onDiscardChanges {
                    onDiscardChanges(file)
                }
            }
        } message: {
            Text("确定要丢弃文件 \"\(file.file)\" 的更改吗？此操作不可撤销。")
        }
    }

    /// 文件状态图标视图：根据文件变更类型显示对应的图标和颜色
    private var statusIcon: some View {
        let (icon, color) = iconInfo(for: file.changeType)
        return Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(2)
            .cornerRadius(6)
    }

    /// 获取文件变更类型的图标和颜色信息
    /// - Parameter change: 文件变更类型字符串
    /// - Returns: 返回图标名称和对应颜色的元组
    private func iconInfo(for change: String) -> (String, Color) {
        let normalizedChange = change.uppercased()
        switch normalizedChange {
        case "M", "MODIFIED":
            return (.iconEditCircle, .orange)
        case "A", "ADDED", "NEW":
            return (.iconPlus, .green)
        case "D", "DELETED":
            return (.iconMinus, .red)
        case "R", "RENAMED":
            return (.iconEditCircle, .blue)
        case "C", "COPIED":
            return (.iconEditCircle, .purple)
        case "?", "UNTRACKED":
            return (.iconPlus, .gray)
        default:
            if Self.verbose {
                os_log(.info, "\(self.t)Unknown change type: '\(change)'")
            }
            return (.iconInfo, .gray)
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
