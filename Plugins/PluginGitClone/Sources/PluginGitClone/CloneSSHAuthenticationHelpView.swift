import AppKit
import GitOKCoreKit
import SwiftUI

struct CloneSSHAuthenticationHelpView: View {
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
                Label(PluginGitCloneLocalization.string("SSH Credentials Required"), systemImage: "key.radiowaves.forward.fill")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(PluginGitCloneLocalization.string("GitOK cannot directly read the SSH passphrase for the current Git operation. Add the key to ssh-agent or macOS Keychain, then retry."))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                if let remoteURL {
                    infoRow(title: PluginGitCloneLocalization.string("Remote URL"), value: remoteURL)
                }

                if let host {
                    infoRow(title: PluginGitCloneLocalization.string("SSH Host"), value: host)
                }

                commandRow(title: PluginGitCloneLocalization.string("Add Key"), command: sshAddCommand)

                if let knownHostsCommand {
                    commandRow(title: PluginGitCloneLocalization.string("Update known_hosts"), command: knownHostsCommand)
                    Text(PluginGitCloneLocalization.string("Before running the known_hosts command, verify the host fingerprint published by the remote provider."))
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
                Button(PluginGitCloneLocalization.string("Open .ssh Folder")) {
                    openSSHDirectory()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(PluginGitCloneLocalization.string("Cancel")) {
                    dismiss()
                }

                Button(PluginGitCloneLocalization.string("Retry")) {
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

                Button(PluginGitCloneLocalization.string("Copy")) {
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
