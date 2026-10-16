import AppKit
import LumiUI
import SwiftUI

/// 诊断设置视图：状态 + 诊断信息操作（对齐旧版 DiagnosticsSettingView）。
public struct DiagnosticsSettingView: View {
    @State private var copiedReport = false

    public init() {}

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 16) {
                statusSection
                actionsSection
            }
        }
        .navigationTitle(Text(pluginLocalization.string("Diagnostics")))
    }

    private var statusSection: some View {
        AppSettingSection(title: pluginLocalization.string("Status"), titleAlignment: .leading) {
            AppSettingRow(
                title: pluginLocalization.string("Last launch"),
                description: pluginLocalization.string("Normal"),
                icon: "checkmark.circle"
            ) {
                EmptyView()
            }
        }
    }

    private var actionsSection: some View {
        AppSettingSection(title: pluginLocalization.string("Diagnostic information"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: pluginLocalization.string("Copy diagnostic information"),
                    description: copiedReport ? pluginLocalization.string("Copied to clipboard") : pluginLocalization.string("Copy app, git and system info to the clipboard"),
                    icon: "doc.on.doc"
                ) {
                    EmptyView()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    copyDiagnosticReport()
                }
                Divider()
                AppSettingRow(
                    title: pluginLocalization.string("Open Application Support"),
                    description: pluginLocalization.string("Reveal the GitOK data directory in Finder"),
                    icon: "folder"
                ) {
                    EmptyView()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    openApplicationSupport()
                }
            }
        }
    }

    private func copyDiagnosticReport() {
        let report = """
        GitOK Diagnostics
        App Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")
        Build: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-")
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        copiedReport = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedReport = false
        }
    }

    private func openApplicationSupport() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let url = base?.appendingPathComponent("GitOK", isDirectory: true) ?? base
        if let url {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
}
