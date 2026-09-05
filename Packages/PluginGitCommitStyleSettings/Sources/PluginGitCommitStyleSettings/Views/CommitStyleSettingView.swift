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
                AppSettingSection(title: LumiPluginLocalization.string("Global Default Style", bundle: .module), titleAlignment: .leading) {
                    AppSettingRow(
                        title: LumiPluginLocalization.string("Global Default Style", bundle: .module),
                        description: LumiPluginLocalization.string("Default commit message display style for new projects", bundle: .module),
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
        .navigationTitle(Text(LumiPluginLocalization.string("Commit Style", bundle: .module)))
    }

    private var styleExamplesSection: some View {
        AppSettingSection(title: LumiPluginLocalization.string("Style Examples", bundle: .module), titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 12) {
                Text(LumiPluginLocalization.string("Choosing a different style changes how commit messages are displayed:", bundle: .module))
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)

                exampleCard(title: LumiPluginLocalization.string("Emoji Style", bundle: .module), examples: [
                    "✨ Feature: Add periodic remote status check",
                    "🐛 Fix: Plugin still shows when disabled",
                    "♻️ Refactor: Move logic to PluginProvider",
                ])

                exampleCard(title: LumiPluginLocalization.string("Plain Text Style", bundle: .module), examples: [
                    "Feature: Add periodic remote status check",
                    "Fix: Plugin still shows when disabled",
                    "Refactor: Move logic to PluginProvider",
                ])

                exampleCard(title: LumiPluginLocalization.string("Plain Text Lowercase", bundle: .module), examples: [
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
