import GitOKCoreKit
import SwiftUI

struct AddRemoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var remoteName = ""
    @State private var remoteURL = ""
    @State private var errorMessage: String?

    let onAdd: (String, String) -> Void

    private var isFormValid: Bool {
        RemoteRepositoryFormRules.isFormValid(name: remoteName, url: remoteURL)
    }

    var body: some View {
        RemoteForm(
            title: PluginRemoteRepositoryLocalization.string("Add Remote Repository"),
            subtitle: PluginRemoteRepositoryLocalization.string("Add a new Git remote repository"),
            remoteName: $remoteName,
            remoteURL: $remoteURL,
            errorMessage: errorMessage,
            primaryTitle: PluginRemoteRepositoryLocalization.string("Add"),
            isPrimaryDisabled: !isFormValid,
            onCancel: { dismiss() },
            onSubmit: addRemote
        )
    }

    private func addRemote() {
        let input = RemoteRepositoryFormRules.normalizedInput(name: remoteName, url: remoteURL)
        guard input.name.isEmpty == false, input.url.isEmpty == false else {
            errorMessage = PluginRemoteRepositoryLocalization.string("Please fill in all fields")
            return
        }

        onAdd(input.name, input.url)
        dismiss()
    }
}

struct EditRemoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var remoteName: String
    @State private var remoteURL: String
    @State private var errorMessage: String?

    let remote: GitRemoteSummary
    let onSave: (String, String) -> Void

    init(remote: GitRemoteSummary, onSave: @escaping (String, String) -> Void) {
        self.remote = remote
        self.onSave = onSave
        _remoteName = State(initialValue: remote.name)
        _remoteURL = State(initialValue: remote.url)
    }

    private var isFormValid: Bool {
        RemoteRepositoryFormRules.isFormValid(name: remoteName, url: remoteURL)
    }

    private var hasChanges: Bool {
        RemoteRepositoryFormRules.hasChanges(
            originalName: remote.name,
            originalURL: remote.url,
            editedName: remoteName,
            editedURL: remoteURL
        )
    }

    var body: some View {
        RemoteForm(
            title: PluginRemoteRepositoryLocalization.string("Edit Remote Repository"),
            subtitle: PluginRemoteRepositoryLocalization.string("Modify the remote repository's name and URL"),
            remoteName: $remoteName,
            remoteURL: $remoteURL,
            errorMessage: errorMessage,
            primaryTitle: PluginRemoteRepositoryLocalization.string("Save"),
            isPrimaryDisabled: !isFormValid || !hasChanges,
            onCancel: { dismiss() },
            onSubmit: saveRemote
        )
    }

    private func saveRemote() {
        let input = RemoteRepositoryFormRules.normalizedInput(name: remoteName, url: remoteURL)
        guard input.name.isEmpty == false, input.url.isEmpty == false else {
            errorMessage = PluginRemoteRepositoryLocalization.string("Please fill in all required information")
            return
        }

        onSave(input.name, input.url)
        dismiss()
    }
}

private struct RemoteForm: View {
    let title: String
    let subtitle: String
    @Binding var remoteName: String
    @Binding var remoteURL: String
    let errorMessage: String?
    let primaryTitle: String
    let isPrimaryDisabled: Bool
    let onCancel: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                formField(
                    title: PluginRemoteRepositoryLocalization.string("Remote Name"),
                    placeholder: PluginRemoteRepositoryLocalization.string("e.g. origin"),
                    text: $remoteName
                )

                formField(
                    title: PluginRemoteRepositoryLocalization.string("Remote URL"),
                    placeholder: PluginRemoteRepositoryLocalization.string("e.g. https://github.com/user/repo.git"),
                    text: $remoteURL
                )
            }

            if let errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            HStack {
                Button(PluginRemoteRepositoryLocalization.string("Cancel"), action: onCancel)
                    .buttonStyle(.bordered)

                Spacer()

                Button(primaryTitle, action: onSubmit)
                    .buttonStyle(.borderedProminent)
                    .disabled(isPrimaryDisabled)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private func formField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
