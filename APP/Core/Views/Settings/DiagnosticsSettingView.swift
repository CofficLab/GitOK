import MagicKit
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
        MagicSettingSection(title: "状态", titleAlignment: .leading) {
            VStack(spacing: 0) {
                MagicSettingRow(
                    title: "上次退出",
                    description: diagnostics.previousLaunchDidNotExitCleanly ? "上次可能未正常退出" : "正常",
                    icon: diagnostics.previousLaunchDidNotExitCleanly ? "exclamationmark.triangle" : "checkmark.circle"
                ) {
                    EmptyView()
                }

                Divider()

                MagicSettingRow(
                    title: "最近错误",
                    description: "\(diagnostics.recentEntries.count) 条",
                    icon: "list.bullet.rectangle"
                ) {
                    EmptyView()
                }
            }
        }
    }

    private var actionsSection: some View {
        MagicSettingSection(title: "诊断信息", titleAlignment: .leading) {
            VStack(spacing: 0) {
                actionRow(
                    title: "复制诊断信息",
                    description: "包含 App、系统、Git 版本和最近错误",
                    icon: "doc.on.doc",
                    buttonTitle: "复制"
                ) {
                    diagnostics.copyDiagnosticReport()
                }

                Divider()

                actionRow(
                    title: "复制日志命令",
                    description: "用于在终端导出最近 1 小时 GitOK 日志",
                    icon: "terminal",
                    buttonTitle: "复制"
                ) {
                    diagnostics.copyLogCommand()
                }

                Divider()

                actionRow(
                    title: "打开 Console",
                    description: "查看系统统一日志中的 GitOK 记录",
                    icon: "text.magnifyingglass",
                    buttonTitle: "打开"
                ) {
                    diagnostics.openConsole()
                }

                Divider()

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
    }

    private var recentFailuresSection: some View {
        MagicSettingSection(title: "最近错误", titleAlignment: .leading) {
            if diagnostics.recentEntries.isEmpty {
                Text("当前会话没有记录到错误。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(diagnostics.recentEntries) { entry in
                        failureRow(entry)
                        if entry.id != diagnostics.recentEntries.last?.id {
                            Divider()
                        }
                    }
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
        MagicSettingRow(title: title, description: description, icon: icon) {
            Button(buttonTitle, action: action)
                .controlSize(.small)
        }
    }

    private func failureRow(_ entry: DiagnosticEntry) -> some View {
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
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview("Diagnostics") {
    SettingView(defaultTab: .diagnostics)
        .inRootView()
        .frame(width: 800, height: 600)
}
