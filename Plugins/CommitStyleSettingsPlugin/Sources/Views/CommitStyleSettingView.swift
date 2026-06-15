import GitOKAppCore
import Foundation
import GitOKCoreKit
import GitOKUI
import GitOKSupportKit
import OSLog
import SwiftUI

/// Commit 风格设置视图
public struct CommitStyleSettingView: View, SuperLog {
    /// emoji 标识符
    nonisolated public static let emoji = "🎨"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    /// Commit 风格
    @State private var commitStyle: CommitStyle = .emoji

    /// 全局 Commit 风格
    @State private var globalCommitStyle: CommitStyle = .emoji

    private var stateRepo: any StateRepoProtocol {
        data.repoManager.stateRepo
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 风格示例展示
                styleExamplesSection

                GitOKUI.AppSettingsSection(title: String(localized: "Commit 风格")) {
                    projectCommitStylePicker
                    globalCommitStylePicker
                }
            }
            .padding()
        }
        .navigationTitle(Text("Commit 风格"))
        .onAppear(perform: loadData)
    }

    // MARK: - View Components

    /// 风格示例展示区
    private var styleExamplesSection: some View {
        GitOKUI.AppSettingsSection(title: String(localized: "Style Examples")) {
            VStack(alignment: .leading, spacing: 16) {
                Text("选择不同的风格会改变 Commit 消息的显示方式：")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    exampleCard(
                        title: String(localized: "Emoji 风格"),
                        examples: [
                            "✨ Feature: Add periodic remote status check",
                            "🐛 Fix: Plugin still shows when disabled",
                            "♻️ Refactor: Move logic to PluginProvider"
                        ]
                    )

                    exampleCard(
                        title: String(localized: "Plain Text Style"),
                        examples: [
                            "Feature: Add periodic remote status check",
                            "Fix: Plugin still shows when disabled",
                            "Refactor: Move logic to PluginProvider"
                        ]
                    )

                    exampleCard(
                        title: String(localized: "Plain Text Lowercase"),
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
                        .gitOKUISurface(style: .subtle, cornerRadius: 6)
                }
            }
        }
    }

    private var projectCommitStylePicker: some View {
        commitStylePickerRow(
            title: String(localized: "Current Project Style"),
            description: String(localized: "Commit message display style for this project"),
            icon: "square.and.pencil",
            selection: Binding(
                get: { commitStyle },
                set: { style in
                    commitStyle = style
                    if let project = vm.project {
                        project.commitStyle = style
                    }
                }
            )
        )
    }

    private var globalCommitStylePicker: some View {
        commitStylePickerRow(
            title: String(localized: "Global Default Style"),
            description: String(localized: "Default commit message display style for new projects"),
            icon: "arrow.up.arrow.down",
            selection: Binding(
                get: { globalCommitStyle },
                set: { style in
                    globalCommitStyle = style
                    stateRepo.setGlobalCommitStyle(style)
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
                        Text(String(localized: .init(String.LocalizationValue(style.rawValue))))
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
            commitStyle = project.commitStyle
        }

        globalCommitStyle = stateRepo.globalCommitStyle
    }
}
