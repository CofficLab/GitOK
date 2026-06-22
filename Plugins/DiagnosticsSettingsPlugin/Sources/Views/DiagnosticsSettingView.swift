import GitOKAppCore
import GitOKUI
import SwiftUI

public struct DiagnosticsSettingView: View {
    @StateObject private var diagnostics = DiagnosticsStore.shared

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summarySection
                actionsSection
                recentFailuresSection
            }
            .padding()
        }
        .navigationTitle(DiagnosticsSettingsPluginLocalization.string("Diagnostics"))
    }

    private var summarySection: some View {
        GitOKUI.AppSettingsSection(title: DiagnosticsSettingsPluginLocalization.string("Status")) {
            settingsRow(
                title: DiagnosticsSettingsPluginLocalization.string("Last exit"),
                description: diagnostics.previousLaunchDidNotExitCleanly ? DiagnosticsSettingsPluginLocalization.string("May not have exited cleanly last time") : DiagnosticsSettingsPluginLocalization.string("Normal"),
                icon: diagnostics.previousLaunchDidNotExitCleanly ? "exclamationmark.triangle" : "checkmark.circle"
            ) {
                EmptyView()
            }
            settingsRow(
                title: DiagnosticsSettingsPluginLocalization.string("Recent errors"),
                description: "\(diagnostics.recentEntries.count) " + DiagnosticsSettingsPluginLocalization.string("Count unit"),
                icon: "list.bullet.rectangle"
            ) {
                EmptyView()
            }
        }
    }

    private var actionsSection: some View {
        GitOKUI.AppSettingsSection(title: DiagnosticsSettingsPluginLocalization.string("Diagnostic information")) {
            actionRow(
                title: DiagnosticsSettingsPluginLocalization.string("Copy diagnostic information"),
                description: DiagnosticsSettingsPluginLocalization.string("Contains App, system, Git version and recent errors"),
                icon: "doc.on.doc",
                buttonTitle: DiagnosticsSettingsPluginLocalization.string("Copy")
            ) {
                diagnostics.copyDiagnosticReport()
            }
            actionRow(
                title: DiagnosticsSettingsPluginLocalization.string("Copy log command"),
                description: DiagnosticsSettingsPluginLocalization.string("Used to export recent 1 hour GitOK logs in terminal"),
                icon: "terminal",
                buttonTitle: DiagnosticsSettingsPluginLocalization.string("Copy")
            ) {
                diagnostics.copyLogCommand()
            }
            actionRow(
                title: DiagnosticsSettingsPluginLocalization.string("Open Console"),
                description: DiagnosticsSettingsPluginLocalization.string("View GitOK records in system unified logging"),
                icon: "text.magnifyingglass",
                buttonTitle: DiagnosticsSettingsPluginLocalization.string("Open")
            ) {
                diagnostics.openConsole()
            }
            actionRow(
                title: DiagnosticsSettingsPluginLocalization.string("Open application support directory"),
                description: GitOKAppPaths.getCurrentAppSupportDir().path,
                icon: "folder",
                buttonTitle: DiagnosticsSettingsPluginLocalization.string("Open")
            ) {
                diagnostics.openApplicationSupport()
            }
        }
    }

    private var recentFailuresSection: some View {
        GitOKUI.AppSettingsSection(title: DiagnosticsSettingsPluginLocalization.string("Recent failures")) {
            if diagnostics.recentEntries.isEmpty {
                Text(DiagnosticsSettingsPluginLocalization.string("No errors were recorded in the current session"))
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
            AppButton(
                buttonTitle,
                style: .secondary,
                size: .small,
                action: action
            )
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
