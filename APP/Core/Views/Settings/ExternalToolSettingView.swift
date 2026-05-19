import MagicKit
import SwiftUI

struct ExternalToolSettingView: View {
    @StateObject private var settings = ExternalToolSettingsStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                editorSection
                terminalSection
            }
            .padding()
        }
        .navigationTitle("外部工具")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
    }

    private var editorSection: some View {
        MagicSettingSection(title: "默认编辑器", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(ExternalEditor.allCases) { editor in
                    editorRow(editor)
                    if editor != ExternalEditor.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    private var terminalSection: some View {
        MagicSettingSection(title: "默认终端", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(ExternalTerminal.allCases) { terminal in
                    terminalRow(terminal)
                    if terminal != ExternalTerminal.allCases.last {
                        Divider()
                    }
                }
            }
        }
    }

    private func editorRow(_ editor: ExternalEditor) -> some View {
        toolRow(
            title: editor.displayName,
            description: editor.description,
            iconName: editor.iconName,
            isSelected: settings.defaultEditor == editor,
            isInstalled: settings.isInstalled(editor)
        ) {
            settings.defaultEditor = editor
        }
    }

    private func terminalRow(_ terminal: ExternalTerminal) -> some View {
        toolRow(
            title: terminal.displayName,
            description: terminal.description,
            iconName: terminal.iconName,
            isSelected: settings.defaultTerminal == terminal,
            isInstalled: settings.isInstalled(terminal)
        ) {
            settings.defaultTerminal = terminal
        }
    }

    private func toolRow(
        title: String,
        description: String,
        iconName: String,
        isSelected: Bool,
        isInstalled: Bool,
        select: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(isInstalled ? .accentColor : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    if !isInstalled {
                        Text("未安装")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview("External Tools") {
    SettingView(defaultTab: .externalTools)
        .inRootView()
        .frame(width: 800, height: 600)
}
