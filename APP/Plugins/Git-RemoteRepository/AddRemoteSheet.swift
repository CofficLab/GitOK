import SwiftUI


struct AddRemoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var remoteName: String = ""
    @State private var remoteURL: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let onAdd: (String, String) -> Void
    
    private var isFormValid: Bool {
        RemoteRepositoryFormRules.isFormValid(name: remoteName, url: remoteURL)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Add Remote Repository"))
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(String(localized: "Add a new Git remote repository"))
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
                
                Button(String(localized: "Add")) {
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
        let input = RemoteRepositoryFormRules.normalizedInput(name: remoteName, url: remoteURL)
        let name = input.name
        let url = input.url
        
        guard !name.isEmpty && !url.isEmpty else {
            errorMessage = String(localized: "Please fill in all fields")
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
