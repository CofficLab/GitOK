import Foundation
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// Commit 风格设置视图
struct CommitStyleSettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🎨"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider

    /// Commit 风格绑定
    @Binding var commitStyle: CommitStyle

    /// 全局 Commit 风格绑定
    @Binding var globalCommitStyle: CommitStyle

    var body: some View {
        MagicSettingSection(title: "Commit 风格", titleAlignment: .leading) {
            VStack(spacing: 0) {
                projectCommitStylePicker
                Divider()
                globalCommitStylePicker
            }
        }
    }

    // MARK: - View Components

    private var projectCommitStylePicker: some View {
        MagicSettingPicker(
            title: "当前项目风格",
            description: "此项目的 Commit 消息显示风格",
            icon: .iconTextEdit,
            options: CommitStyle.allCases.map { $0.label },
            selection: Binding(
                get: { commitStyle.label },
                set: { newValue in
                    if let style = CommitStyle.allCases.first(where: { $0.label == newValue }) {
                        commitStyle = style
                        if let project = data.project {
                            project.commitStyle = style
                        }
                    }
                }
            )
        ) { $0 }
    }

    private var globalCommitStylePicker: some View {
        MagicSettingPicker(
            title: "全局默认风格",
            description: "新项目的默认 Commit 消息显示风格",
            icon: .iconSort,
            options: CommitStyle.allCases.map { $0.label },
            selection: Binding(
                get: { globalCommitStyle.label },
                set: { newValue in
                    if let style = CommitStyle.allCases.first(where: { $0.label == newValue }) {
                        globalCommitStyle = style
                        UserDefaults.standard.set(style.rawValue, forKey: "globalCommitStyle")
                    }
                }
            )
        ) { $0 }
    }
}

// MARK: - Preview

#Preview("Commit Style Settings") {
    CommitStyleSettingView(
        commitStyle: .constant(.emoji),
        globalCommitStyle: .constant(.emoji)
    )
}
