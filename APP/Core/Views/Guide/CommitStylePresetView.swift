import Foundation
import GitOKUI
import MagicKit
import OSLog
import PluginCommit
import SwiftUI

/// Commit 风格预设管理视图组件
struct CommitStylePresetView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🎨"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// 当前项目 Commit 风格
    @State private var projectCommitStyle: CommitStyle = .emoji

    /// 全局 Commit 风格
    @State private var globalCommitStyle: CommitStyle = .emoji

    var body: some View {
        GitOKUI.AppSettingsSection(title: "Commit 风格") {
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
        commitStylePickerRow(
            title: "当前项目风格",
            description: "此项目的 Commit 消息显示风格",
            icon: "square.and.pencil",
            selection: Binding(
                get: { projectCommitStyle },
                set: { style in
                    projectCommitStyle = style
                    if let project = vm.project {
                        project.commitStyle = style
                    }
                }
            )
        )
    }

    /// 全局风格选择器
    private var globalCommitStylePicker: some View {
        commitStylePickerRow(
            title: "全局默认风格",
            description: "新项目的默认 Commit 消息显示风格",
            icon: "arrow.up.arrow.down",
            selection: Binding(
                get: { globalCommitStyle },
                set: { style in
                    globalCommitStyle = style
                    UserDefaults.standard.set(style.rawValue, forKey: "globalCommitStyle")
                }
            )
        )
    }

    private func commitStylePickerRow(
        title: String,
        description: String,
        icon: String,
        selection: Binding<CommitStyle>
    ) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Picker("", selection: selection) {
                    ForEach(CommitStyle.allCases, id: \.self) { style in
                        Text(style.label)
                            .tag(style)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }
        }
    }

    // MARK: - Load Data

    private func loadData() {
        if let project = vm.project {
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
