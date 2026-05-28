import SwiftUI
import MagicKit
import LibGit2Swift


struct EditRemoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var remoteName: String
    @State private var remoteURL: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let remote: GitRemote
    let onSave: (String, String) -> Void
    
    init(remote: GitRemote, onSave: @escaping (String, String) -> Void) {
        self.remote = remote
        self.onSave = onSave
        self._remoteName = State(initialValue: remote.name)
        self._remoteURL = State(initialValue: remote.url)
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
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Edit Remote Repository"))
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(String(localized: "Modify the remote repository's name and URL"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Remote Name"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField(String(localized: "e.g. origin"), text: $remoteName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Remote URL"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField(String(localized: "e.g. https://github.com/user/repo.git"), text: $remoteURL)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            if let errorMessage = errorMessage {
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
                Button(String(localized: "Cancel")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(String(localized: "Save")) {
                    saveRemote()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid || !hasChanges || isLoading)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .disabled(isLoading)
    }
    
    private func saveRemote() {
        let input = RemoteRepositoryFormRules.normalizedInput(name: remoteName, url: remoteURL)
        let name = input.name
        let url = input.url
        
        guard !name.isEmpty && !url.isEmpty else {
            errorMessage = String(localized: "Please fill in all required information")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        onSave(name, url)
        dismiss()
    }
}
