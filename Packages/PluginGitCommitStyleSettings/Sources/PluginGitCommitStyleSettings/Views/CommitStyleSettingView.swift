import LumiUI
import ProviderCommitForm
import SwiftUI

/// Commit 风格设置视图：风格示例 + 全局默认风格
/// （对齐旧版 CommitStyleSettingView）。
public struct CommitStyleSettingView: View {
    @State private var globalCommitStyle: CommitStyle = CommitStyleStore.current
    @LumiTheme private var theme

    public init() {}

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 16) {
                styleExamplesSection
                AppSettingSection(title: "Global Default Style", titleAlignment: .leading) {
                    AppSettingRow(
                        title: "Global Default Style",
                        description: "Default commit message display style for new projects",
                        icon: "arrow.up.arrow.down"
                    ) {
                        Picker("", selection: $globalCommitStyle) {
                            ForEach(CommitStyle.allCases, id: \.self) { style in
                                Text(style.label).tag(style)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180)
                        .onChange(of: globalCommitStyle) { _, newValue in
                            CommitStyleStore.set(newValue)
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Commit Style"))
    }

    private var styleExamplesSection: some View {
        AppSettingSection(title: "Style Examples", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choosing a different style changes how commit messages are displayed:")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)

                exampleCard(title: "Emoji Style", examples: [
                    "✨ Feature: Add periodic remote status check",
                    "🐛 Fix: Plugin still shows when disabled",
                    "♻️ Refactor: Move logic to PluginProvider",
                ])

                exampleCard(title: "Plain Text Style", examples: [
                    "Feature: Add periodic remote status check",
                    "Fix: Plugin still shows when disabled",
                    "Refactor: Move logic to PluginProvider",
                ])

                exampleCard(title: "Plain Text Lowercase", examples: [
                    "feature: Add periodic remote status check",
                    "fix: Plugin still shows when disabled",
                    "refactor: Move logic to PluginProvider",
                ])
            }
        }
    }

    private func exampleCard(title: String, examples: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(examples, id: \.self) { example in
                    Text(example)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}
