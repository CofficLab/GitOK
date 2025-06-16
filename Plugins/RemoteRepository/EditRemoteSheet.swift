import SwiftUI
import MagicCore

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
        !remoteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !remoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasChanges: Bool {
        remoteName.trimmingCharacters(in: .whitespacesAndNewlines) != remote.name ||
        remoteURL.trimmingCharacters(in: .whitespacesAndNewlines) != remote.url
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("编辑远程仓库")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("修改远程仓库的名称和URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("远程名称")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("例如: origin", text: $remoteName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("远程URL")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("例如: https://github.com/user/repo.git", text: $remoteURL)
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
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("保存") {
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
        let name = remoteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty && !url.isEmpty else {
            errorMessage = "请填写完整信息"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        onSave(name, url)
        dismiss()
    }
}
