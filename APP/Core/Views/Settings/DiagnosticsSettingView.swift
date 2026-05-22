import GitOKUI
import SwiftUI

struct DiagnosticsSettingView: View {
    @StateObject private var diagnostics = DiagnosticsStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summarySection
                actionsSection
                recentFailuresSection
            }
            .padding()
        }
        .navigationTitle("诊断")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    NotificationCenter.default.post(name: .didSaveGitUserConfig, object: nil)
                }
            }
        }
    }

    private var summarySection: some View {
        GitOKUI.AppSettingsSection(title: "状态") {
            settingsRow(
                title: "上次退出",
                description: diagnostics.previousLaunchDidNotExitCleanly ? "上次可能未正常退出" : "正常",
                icon: diagnostics.previousLaunchDidNotExitCleanly ? "exclamationmark.triangle" : "checkmark.circle"
            ) {
                EmptyView()
            }
            settingsRow(
                title: "最近错误",
                description: "\(diagnostics.recentEntries.count) 条",
                icon: "list.bullet.rectangle"
            ) {
                EmptyView()
            }
        }
    }

    private var actionsSection: some View {
        GitOKUI.AppSettingsSection(title: "诊断信息") {
            actionRow(
                title: "复制诊断信息",
                description: "包含 App、系统、Git 版本和最近错误",
                icon: "doc.on.doc",
                buttonTitle: "复制"
            ) {
                diagnostics.copyDiagnosticReport()
            }
            actionRow(
                title: "复制日志命令",
                description: "用于在终端导出最近 1 小时 GitOK 日志",
                icon: "terminal",
                buttonTitle: "复制"
            ) {
                diagnostics.copyLogCommand()
            }
            actionRow(
                title: "打开 Console",
                description: "查看系统统一日志中的 GitOK 记录",
                icon: "text.magnifyingglass",
                buttonTitle: "打开"
            ) {
                diagnostics.openConsole()
            }
            actionRow(
                title: "打开应用支持目录",
                description: AppConfig.getCurrentAppSupportDir().path,
                icon: "folder",
                buttonTitle: "打开"
            ) {
                diagnostics.openApplicationSupport()
            }
        }
    }

    private var recentFailuresSection: some View {
        GitOKUI.AppSettingsSection(title: "最近错误") {
            if diagnostics.recentEntries.isEmpty {
                Text("当前会话没有记录到错误。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(diagnostics.recentEntries) { entry in
                    failureRow(entry)
                }
            }
        }
    }

    private func actionRow(
        title: String,
        description: String,
        icon: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        settingsRow(title: title, description: description, icon: icon) {
            Button(buttonTitle, action: action)
                .controlSize(.small)
        }
    }

    private func failureRow(_ entry: DiagnosticEntry) -> some View {
        GitOKUI.AppSettingsRow(verticalPadding: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("\(entry.source) / \(entry.operation)")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let projectPath = entry.projectPath {
                    Text(projectPath)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Text(entry.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func settingsRow<Accessory: View>(
        title: String,
        description: String,
        icon: String,
        @ViewBuilder accessory: () -> Accessory
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
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                Spacer()

                accessory()
            }
        }
    }
}

#Preview("Diagnostics") {
    SettingView(defaultTab: .diagnostics)
        .inRootView()
        .frame(width: 800, height: 600)
}
