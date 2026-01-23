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

    /// Commit 风格
    @State private var commitStyle: CommitStyle = .emoji

    /// 全局 Commit 风格
    @State private var globalCommitStyle: CommitStyle = .emoji

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 风格示例展示
                styleExamplesSection

                MagicSettingSection(title: "Commit 风格", titleAlignment: .leading) {
                    VStack(spacing: 0) {
                        projectCommitStylePicker
                        Divider()
                        globalCommitStylePicker
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Commit 风格")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    // 关闭设置视图
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
        .onAppear(perform: loadData)
    }

    // MARK: - View Components

    /// 风格示例展示区
    private var styleExamplesSection: some View {
        MagicSettingSection(title: "风格示例", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 16) {
                Text("选择不同的风格会改变 Commit 消息的显示方式：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    exampleCard(
                        title: "Emoji 风格",
                        examples: [
                            "✨ Feature: Add periodic remote status check",
                            "🐛 Fix: Plugin still shows when disabled",
                            "♻️ Refactor: Move logic to PluginProvider"
                        ]
                    )

                    exampleCard(
                        title: "纯文本风格",
                        examples: [
                            "Feature: Add periodic remote status check",
                            "Fix: Plugin still shows when disabled",
                            "Refactor: Move logic to PluginProvider"
                        ]
                    )

                    exampleCard(
                        title: "纯文本小写",
                        examples: [
                            "feature: Add periodic remote status check",
                            "fix: Plugin still shows when disabled",
                            "refactor: Move logic to PluginProvider"
                        ]
                    )
                }
            }
        }
    }

    /// 示例卡片
    private func exampleCard(title: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(examples, id: \.self) { example in
                    Text(example)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.controlBackgroundColor))
                        )
                }
            }
        }
    }

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

    // MARK: - Load Data

    private func loadData() {
        if let project = data.project {
            commitStyle = project.commitStyle
        }

        if let savedStyleRaw = UserDefaults.standard.string(forKey: "globalCommitStyle"),
           let savedStyle = CommitStyle(rawValue: savedStyleRaw) {
            globalCommitStyle = savedStyle
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
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
