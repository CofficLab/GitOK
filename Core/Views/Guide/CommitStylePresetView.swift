import Foundation
import MagicKit
import OSLog
import SwiftUI

/// Commit 风格预设管理视图组件
struct CommitStylePresetView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🎨"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider

    /// 当前项目 Commit 风格
    @State private var projectCommitStyle: CommitStyle = .emoji

    /// 全局 Commit 风格
    @State private var globalCommitStyle: CommitStyle = .emoji

    var body: some View {
        MagicSettingSection(title: "Commit 风格", titleAlignment: .leading) {
            VStack(spacing: 0) {
                // 当前项目风格
                projectCommitStylePicker

                Divider()
                    .padding(.vertical, 8)

                // 全局风格
                globalCommitStylePicker
            }
        }
        .onAppear(perform: loadData)
    }

    // MARK: - View Components

    /// 当前项目风格选择器
    private var projectCommitStylePicker: some View {
        MagicSettingPicker(
            title: "当前项目风格",
            description: "此项目的 Commit 消息显示风格",
            icon: .iconTextEdit,
            options: CommitStyle.allCases.map { $0.label },
            selection: Binding(
                get: { projectCommitStyle.label },
                set: { newValue in
                    if let style = CommitStyle.allCases.first(where: { $0.label == newValue }) {
                        projectCommitStyle = style
                        if let project = data.project {
                            project.commitStyle = style
                        }
                    }
                }
            )
        ) { $0 }
    }

    /// 全局风格选择器
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

    // MARK: - Load Data

    private func loadData() {
        if let project = data.project {
            projectCommitStyle = project.commitStyle
        }

        if let savedStyleRaw = UserDefaults.standard.string(forKey: "globalCommitStyle"),
           let savedStyle = CommitStyle(rawValue: savedStyleRaw) {
            globalCommitStyle = savedStyle
        } else {
            globalCommitStyle = .emoji
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
