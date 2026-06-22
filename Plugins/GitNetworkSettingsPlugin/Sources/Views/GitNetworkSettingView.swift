import GitOKAppCore
import AppKit
import GitOKUI
import SwiftUI

public struct GitNetworkSettingView: View {
    @StateObject private var settings = GitNetworkSettingsStore()

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                proxySection
                certificateSection
                statusSection
            }
            .padding()
        }
        .navigationTitle(GitNetworkSettingsPluginLocalization.string("Network"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(
                    GitNetworkSettingsPluginLocalization.string("Save"),
                    systemImage: "square.and.arrow.down",
                    style: .secondary,
                    size: .small,
                    isLoading: settings.isSaving
                ) {
                    settings.save()
                }
                .disabled(settings.isSaving || settings.isLoading)
            }
        }
        .onAppear {
            settings.load()
        }
    }

    private var proxySection: some View {
        GitOKUI.AppSettingsSection(title: GitNetworkSettingsPluginLocalization.string("Proxy")) {
            VStack(alignment: .leading, spacing: 14) {
                labeledInput(
                    title: GitNetworkSettingsPluginLocalization.string("HTTP proxy"),
                    placeholder: GitNetworkSettingsPluginLocalization.string("HTTP proxy placeholder"),
                    text: $settings.httpProxy
                )

                labeledInput(
                    title: GitNetworkSettingsPluginLocalization.string("HTTPS proxy"),
                    placeholder: GitNetworkSettingsPluginLocalization.string("HTTPS proxy placeholder"),
                    text: $settings.httpsProxy
                )

                Text(GitNetworkSettingsPluginLocalization.string("Proxy configuration description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
    }

    private var certificateSection: some View {
        GitOKUI.AppSettingsSection(title: GitNetworkSettingsPluginLocalization.string("Certificate")) {
            VStack(alignment: .leading, spacing: 14) {
                AppToggleRow(
                    title: GitNetworkSettingsPluginLocalization.string("Enable Git SSL certificate verification"),
                    systemImage: "lock.shield",
                    isOn: $settings.sslVerify
                )
                    .disabled(settings.isLoading || settings.isSaving)

                HStack(spacing: 8) {
                    AppInputField(GitNetworkSettingsPluginLocalization.string("CA file placeholder"), text: $settings.sslCAInfo)
                        .disabled(settings.isLoading || settings.isSaving)

                    AppButton(GitNetworkSettingsPluginLocalization.string("Choose"), systemImage: "folder", style: .secondary, size: .small) {
                        chooseCertificateFile()
                    }
                    .disabled(settings.isLoading || settings.isSaving)

                    AppButton(GitNetworkSettingsPluginLocalization.string("Clear"), systemImage: "xmark", style: .tonal, size: .small) {
                        settings.sslCAInfo = ""
                    }
                    .disabled(settings.isLoading || settings.isSaving || settings.sslCAInfo.isEmpty)
                }

                Text(GitNetworkSettingsPluginLocalization.string("Certificate configuration description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                AppButton(GitNetworkSettingsPluginLocalization.string("Open Keychain Access"), systemImage: "key", style: .secondary, size: .small) {
                    openKeychainAccess()
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if settings.isLoading {
            AppLoadingOverlay(message: GitNetworkSettingsPluginLocalization.string("Reading Git network config…"), size: .small)
                .frame(maxWidth: .infinity, minHeight: 48)
        } else if let errorMessage = settings.errorMessage {
            AppErrorBanner(message: errorMessage)
                .textSelection(.enabled)
        } else if let message = settings.message {
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func labeledInput(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            AppInputField(placeholder, text: text)
                .disabled(settings.isLoading || settings.isSaving)
        }
    }

    private func chooseCertificateFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            settings.sslCAInfo = url.path
        }
    }

    private func openKeychainAccess() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Keychain Access.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
