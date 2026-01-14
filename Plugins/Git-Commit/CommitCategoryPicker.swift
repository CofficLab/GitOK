import SwiftUI
import MagicKit

/// Commit 类别选择器组件
/// 提供提交类别的下拉选择功能，支持不同风格的显示
struct CommitCategoryPicker: View {
    /// 绑定到外部的选中类别
    @Binding var selection: CommitCategory

    /// 提交风格，用于控制显示格式
    var commitStyle: CommitStyle = .emoji

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CommitCategory.allCases, id: \.self) { category in
                Text(displayLabel(for: category))
                    .tag(category as CommitCategory?)
            }
        }
        .frame(width: 135)
        .pickerStyle(.automatic)
    }

    /// 根据提交风格生成类别显示标签
    /// - Parameter category: 提交类别
    /// - Returns: 格式化后的显示标签
    private func displayLabel(for category: CommitCategory) -> String {
        if commitStyle.includeEmoji {
            return category.label
        } else if commitStyle.isLowercase {
            return category.title.lowercased()
        } else {
            return category.title
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
