import AppKit
import KitGit
import LumiUI
import SwiftUI

/// 网络设置视图：代理 + SSL 证书（读写全局 git config，对齐旧版 GitNetworkSettingView）。
public struct GitNetworkSettingView: View {
    @StateObject private var settings = GitNetworkSettingsStore()
    @LumiTheme private var theme

    public init() {}

    public var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 16) {
                proxySection
                certificateSection
                if let message = settings.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(theme.success)
                }
                if let errorMessage = settings.errorMessage {
                    AppErrorBanner(message: LocalizedStringKey(errorMessage))
                }
            }
        }
        .navigationTitle(Text("Network"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(
                    "Save",
                    systemImage: "square.and.arrow.down",
                    style: .secondary,
                    size: .small
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
        AppSettingSection(title: "Proxy", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 14) {
                labeledInput(
                    title: "HTTP proxy",
                    placeholder: "http://127.0.0.1:1087",
                    text: $settings.httpProxy
                )
                labeledInput(
                    title: "HTTPS proxy",
                    placeholder: "http://127.0.0.1:1087",
                    text: $settings.httpsProxy
                )
                Text("Writes to Git global config `http.proxy` and `https.proxy`. If the proxy requires authentication, use the format `http://user:password@host:port`.")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var certificateSection: some View {
        AppSettingSection(title: "Certificate", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 14) {
                AppSettingRow(
                    title: "Enable Git SSL certificate verification",
                    description: "Verifies the certificate of remote hosts over HTTPS",
                    icon: "lock.shield"
                ) {
                    Toggle("", isOn: $settings.sslVerify)
                        .labelsHidden()
                        .disabled(settings.isLoading || settings.isSaving)
                }

                HStack(spacing: 8) {
                    AppInputField("CA file path", text: $settings.sslCAInfo)
                        .disabled(settings.isLoading || settings.isSaving)
                    AppButton("Choose", systemImage: "folder", style: .secondary, size: .small) {
                        chooseCertificateFile()
                    }
                    .disabled(settings.isLoading || settings.isSaving)
                    AppButton("Clear", systemImage: "xmark", style: .tonal, size: .small) {
                        settings.sslCAInfo = ""
                    }
                    .disabled(settings.isLoading || settings.isSaving || settings.sslCAInfo.isEmpty)
                }

                Text("The CA file is written to `http.sslCAInfo`. Disabling SSL verification is only suitable for temporary troubleshooting; enterprise networks should prioritize importing trusted CA certificates.")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                AppButton("Open Keychain Access", systemImage: "key", style: .secondary, size: .small) {
                    openKeychainAccess()
                }
            }
        }
    }

    private func labeledInput(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
            AppInputField(LocalizedStringKey(placeholder), text: text)
                .disabled(settings.isLoading || settings.isSaving)
        }
    }

    private func chooseCertificateFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["pem", "crt", "cer", "der"]
        if panel.runModal() == .OK, let url = panel.url {
            settings.sslCAInfo = url.path
        }
    }

    private func openKeychainAccess() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.KeychainAccess") {
            NSWorkspace.shared.open(url)
        }
    }
}

/// 网络设置存储：加载 / 保存全局 git 网络配置。
@MainActor
final class GitNetworkSettingsStore: ObservableObject {
    @Published var httpProxy = ""
    @Published var httpsProxy = ""
    @Published var sslVerify = true
    @Published var sslCAInfo = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var message: String?
    @Published var errorMessage: String?

    func load() {
        isLoading = true
        errorMessage = nil
        message = nil

        Task.detached(priority: .userInitiated) {
            let configuration = GitNetworkConfig.loadGlobal()
            await MainActor.run {
                self.httpProxy = configuration.httpProxy
                self.httpsProxy = configuration.httpsProxy
                self.sslVerify = configuration.sslVerify
                self.sslCAInfo = configuration.sslCAInfo
                self.isLoading = false
            }
        }
    }

    func save() {
        isSaving = true
        errorMessage = nil
        message = nil
        let configuration = GitNetworkConfig.Configuration(
            httpProxy: httpProxy,
            httpsProxy: httpsProxy,
            sslVerify: sslVerify,
            sslCAInfo: sslCAInfo
        )

        Task.detached(priority: .userInitiated) {
            do {
                try GitNetworkConfig.saveGlobal(configuration)
                await MainActor.run {
                    self.isSaving = false
                    self.message = "Git network configuration saved"
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
