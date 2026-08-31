import AppKit
import Foundation
import GitOKUI
import SwiftUI

public struct CloneSSHAuthenticationHelpView: View {
    @Environment(\.dismiss) private var dismiss

    let remoteURL: String?
    let errorMessage: String?
    let onRetry: () -> Void

    public init(
        remoteURL: String?,
        errorMessage: String?,
        onRetry: @escaping () -> Void
    ) {
        self.remoteURL = remoteURL
        self.errorMessage = errorMessage
        self.onRetry = onRetry
    }

    private var host: String? {
        remoteURL.flatMap(Self.sshHost(from:))
    }

    private var sshAddCommand: String {
        "ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
    }

    private var knownHostsCommand: String? {
        guard let host else { return nil }
        return "ssh-keyscan -H \(host) >> ~/.ssh/known_hosts"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label(GitAuthenticationLocalization.string("SSH Credentials Required"), systemImage: "key.radiowaves.forward.fill")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(GitAuthenticationLocalization.string("GitOK cannot directly read the SSH passphrase for the current Git operation. Add the key to ssh-agent or macOS Keychain, then retry."))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                if let remoteURL {
                    infoRow(title: GitAuthenticationLocalization.string("Remote URL"), value: remoteURL)
                }

                if let host {
                    infoRow(title: GitAuthenticationLocalization.string("SSH Host"), value: host)
                }

                commandRow(title: GitAuthenticationLocalization.string("Add Key"), command: sshAddCommand)

                if let knownHostsCommand {
                    commandRow(title: GitAuthenticationLocalization.string("Update known_hosts"), command: knownHostsCommand)
                    Text(GitAuthenticationLocalization.string("Before running the known_hosts command, verify the host fingerprint published by the remote provider."))
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

            HStack(spacing: 8) {
                AppButton(
                    GitAuthenticationLocalization.string("Open .ssh Folder"),
                    systemImage: "folder",
                    style: .secondary,
                    size: .small
                ) {
                    openSSHDirectory()
                }

                Spacer()

                AppButton(
                    GitAuthenticationLocalization.string("Cancel"),
                    style: .secondary,
                    size: .small
                ) {
                    dismiss()
                }

                AppButton(
                    GitAuthenticationLocalization.string("Retry"),
                    systemImage: "arrow.clockwise",
                    style: .primary,
                    size: .small
                ) {
                    dismiss()
                    onRetry()
                }
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

                AppButton(
                    GitAuthenticationLocalization.string("Copy"),
                    systemImage: "doc.on.doc",
                    style: .secondary,
                    size: .small
                ) {
                    copy(command)
                }
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

    private static func sshHost(from remote: String) -> String? {
        let trimmed = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        if let components = URLComponents(string: trimmed),
           components.scheme?.lowercased() == "ssh",
           let host = components.host,
           host.isEmpty == false {
            return host
        }

        let pattern = #"^[^@/\s]+@([^:\s]+):.+$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let range = Range(match.range(at: 1), in: trimmed) else {
            return nil
        }

        return String(trimmed[range])
    }
}
