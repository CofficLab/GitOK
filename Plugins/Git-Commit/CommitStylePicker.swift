import MagicKit
import SwiftUI

/// Commit 风格选择器枚举
/// 定义提交消息的不同显示风格
enum CommitStyle: String, CaseIterable {
    case emoji = "Emoji风格"
    case plain = "纯文本风格"
    case lowercase = "纯文本小写"

    /// 显示标签
    var label: String {
        return self.rawValue
    }

    /// 是否包含 emoji
    var includeEmoji: Bool {
        switch self {
        case .emoji:
            return true
        case .plain, .lowercase:
            return false
        }
    }

    /// 是否为小写格式
    var isLowercase: Bool {
        switch self {
        case .lowercase:
            return true
        case .emoji, .plain:
            return false
        }
    }
}

/// Commit 风格选择器组件
/// 提供提交风格的下拉选择功能，并自动保存到项目配置
struct CommitStylePicker: View {
    /// 环境对象：数据提供者
    @EnvironmentObject var g: DataProvider

    /// 绑定到外部的选中风格
    @Binding var selection: CommitStyle

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(CommitStyle.allCases, id: \.self) { style in
                Text(style.label)
                    .tag(style as CommitStyle?)
            }
        }
        .frame(width: 120)
        .pickerStyle(.automatic)
        .onChange(of: selection) { _, _ in
            saveCommitStyle()
        }
    }

    /// 保存提交风格到当前项目配置
    private func saveCommitStyle() {
        // 保存到当前项目，而不是全局配置
        if let project = g.project {
            project.commitStyle = selection
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
