import SwiftUI
import MagicCore

struct AddRemoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var remoteName: String = ""
    @State private var remoteURL: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onAdd: (String, String) -> Void
    
    private var isFormValid: Bool {
        !remoteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !remoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("添加远程仓库")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("添加一个新的Git远程仓库")
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
                
                Button("添加") {
                    addRemote()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid || isLoading)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .disabled(isLoading)
    }
    
    private func addRemote() {
        let name = remoteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty && !url.isEmpty else {
            errorMessage = "请填写完整信息"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        onAdd(name, url)
        dismiss()
    }
}


#Preview("Add Remote Sheet") {
    AddRemoteSheet { name, url in
        print("Adding remote: \(name) -> \(url)")
    }
}
