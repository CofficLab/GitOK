import AppKit
import MagicKit
import SwiftUI

struct GitNetworkSettingView: View {
    @StateObject private var settings = GitNetworkSettingsStore()

    var body: some View {
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
                Button {
                    settings.save()
                } label: {
                    if settings.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("保存")
                    }
                }
                .disabled(settings.isSaving || settings.isLoading)
            }
        }
        .onAppear {
            settings.load()
        }
    }

    private var proxySection: some View {
        MagicSettingSection(title: "代理", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 14) {
                TextField("http://127.0.0.1:7890", text: $settings.httpProxy)
                    .textFieldStyle(.roundedBorder)
                    .disabled(settings.isLoading || settings.isSaving)
                    .overlay(alignment: .topLeading) {
                        Text("HTTP proxy")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .offset(y: -18)
                    }
                    .padding(.top, 18)

                TextField("http://127.0.0.1:7890", text: $settings.httpsProxy)
                    .textFieldStyle(.roundedBorder)
                    .disabled(settings.isLoading || settings.isSaving)
                    .overlay(alignment: .topLeading) {
                        Text("HTTPS proxy")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .offset(y: -18)
                    }
                    .padding(.top, 18)

                Text("会写入 Git 全局配置 `http.proxy` 和 `https.proxy`。如果代理需要认证，可使用 `http://user:password@host:port` 格式。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
    }

    private var certificateSection: some View {
        MagicSettingSection(title: "证书", titleAlignment: .leading) {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("启用 Git SSL 证书验证", isOn: $settings.sslVerify)
                    .disabled(settings.isLoading || settings.isSaving)

                HStack(spacing: 8) {
                    TextField("/path/to/company-ca.pem", text: $settings.sslCAInfo)
                        .textFieldStyle(.roundedBorder)
                        .disabled(settings.isLoading || settings.isSaving)

                    Button("选择") {
                        chooseCertificateFile()
                    }
                    .disabled(settings.isLoading || settings.isSaving)

                    Button("清除") {
                        settings.sslCAInfo = ""
                    }
                    .disabled(settings.isLoading || settings.isSaving || settings.sslCAInfo.isEmpty)
                }

                Text("CA 文件会写入 `http.sslCAInfo`。关闭 SSL 验证只适合临时排障；企业网络应优先导入可信 CA 证书。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("打开钥匙串访问") {
                    openKeychainAccess()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if settings.isLoading {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("正在读取 Git 网络配置…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else if let errorMessage = settings.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .textSelection(.enabled)
        } else if let message = settings.message {
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
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

#Preview("Network") {
    SettingView(defaultTab: .network)
        .inRootView()
        .frame(width: 800, height: 600)
}
