import AppKit
import GitCoreKit
import SwiftUI

struct SSHAuthenticationHelpView: View {
    @Environment(\.dismiss) private var dismiss

    let remoteURL: String?
    let errorMessage: String?
    let onRetry: () -> Void

    private var host: String? {
        remoteURL.flatMap(CloneRepositoryValidation.sshHost(from:))
    }

    private var sshAddCommand: String {
        "ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
    }

    private var knownHostsCommand: String? {
        guard let host else { return nil }
        return "ssh-keyscan -H \(host) >> ~/.ssh/known_hosts"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label("需要 SSH 凭据", systemImage: "key.radiowaves.forward.fill")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("GitOK 无法在当前 Git 操作中直接读取 SSH passphrase。请把密钥加入 ssh-agent 或 macOS Keychain，再重试本次操作。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                if let remoteURL {
                    infoRow(title: "远程地址", value: remoteURL)
                }

                if let host {
                    infoRow(title: "SSH 主机", value: host)
                }

                commandRow(title: "添加密钥", command: sshAddCommand)

                if let knownHostsCommand {
                    commandRow(title: "更新 known_hosts", command: knownHostsCommand)
                    Text("执行 known_hosts 命令前，请先确认远程服务商公布的主机指纹可信。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let errorMessage, errorMessage.isEmpty == false {
                    Text(errorMessage)
                        .font(.caption.monospaced())
                        .foregroundColor(.red)
                        .textSelection(.enabled)
                        .lineLimit(6)
                }
            }

            HStack {
                Button("打开 .ssh 目录") {
                    openSSHDirectory()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("取消") {
                    dismiss()
                }

                Button("重试") {
                    dismiss()
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }

    private func commandRow(title: String, command: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text(command)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("复制") {
                    copy(command)
                }
                .controlSize(.small)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(6)
        }
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func openSSHDirectory() {
        let sshURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh", isDirectory: true)
        NSWorkspace.shared.open(sshURL)
    }
}
