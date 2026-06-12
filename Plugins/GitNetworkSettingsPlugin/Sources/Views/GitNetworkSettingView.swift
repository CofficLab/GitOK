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
        .navigationTitle("网络")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AppButton(
                    "保存",
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
        GitOKUI.AppSettingsSection(title: "代理") {
            VStack(alignment: .leading, spacing: 14) {
                labeledInput(
                    title: "HTTP proxy",
                    placeholder: "http://127.0.0.1:7890",
                    text: $settings.httpProxy
                )

                labeledInput(
                    title: "HTTPS proxy",
                    placeholder: "http://127.0.0.1:7890",
                    text: $settings.httpsProxy
                )

                Text("会写入 Git 全局配置 `http.proxy` 和 `https.proxy`。如果代理需要认证，可使用 `http://user:password@host:port` 格式。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
    }

    private var certificateSection: some View {
        GitOKUI.AppSettingsSection(title: "证书") {
            VStack(alignment: .leading, spacing: 14) {
                AppToggleRow(
                    title: "启用 Git SSL 证书验证",
                    systemImage: "lock.shield",
                    isOn: $settings.sslVerify
                )
                    .disabled(settings.isLoading || settings.isSaving)

                HStack(spacing: 8) {
                    AppInputField("/path/to/company-ca.pem", text: $settings.sslCAInfo)
                        .disabled(settings.isLoading || settings.isSaving)

                    AppButton("选择", systemImage: "folder", style: .secondary, size: .small) {
                        chooseCertificateFile()
                    }
                    .disabled(settings.isLoading || settings.isSaving)

                    AppButton("清除", systemImage: "xmark", style: .tonal, size: .small) {
                        settings.sslCAInfo = ""
                    }
                    .disabled(settings.isLoading || settings.isSaving || settings.sslCAInfo.isEmpty)
                }

                Text("CA 文件会写入 `http.sslCAInfo`。关闭 SSL 验证只适合临时排障；企业网络应优先导入可信 CA 证书。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                AppButton("打开钥匙串访问", systemImage: "key", style: .secondary, size: .small) {
                    openKeychainAccess()
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if settings.isLoading {
            AppLoadingOverlay(message: "正在读取 Git 网络配置…", size: .small)
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
