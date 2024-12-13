import SwiftUI

struct ParametersView: View {
    @Binding var request: APIRequest
    @State private var newParamKey = ""
    @State private var newParamValue = ""
    @State private var editingParams: [String: String]
    @State private var isEditing = false
    
    init(request: Binding<APIRequest>) {
        self._request = request
        _editingParams = State(initialValue: request.wrappedValue.queryParameters)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Query Parameters")
                    .font(.headline)
                Spacer()
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "Done" : "Edit")
                }
            }
            
            if isEditing {
                // 编辑模式
                VStack(spacing: 8) {
                    ForEach(Array(editingParams.keys.sorted()), id: \.self) { key in
                        HStack {
                            TextField("Key", text: .constant(key))
                                .textFieldStyle(.roundedBorder)
                                .disabled(true)
                            TextField("Value", text: Binding(
                                get: { editingParams[key] ?? "" },
                                set: { editingParams[key] = $0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                            Button(action: { editingParams.removeValue(forKey: key) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 添加新参数
                    HStack {
                        TextField("New Parameter Key", text: $newParamKey)
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $newParamValue)
                            .textFieldStyle(.roundedBorder)
                        Button(action: addParameter) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(newParamKey.isEmpty)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Save Changes") {
                            saveChanges()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                // 查看模式
                if editingParams.isEmpty {
                    Text("No parameters")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(editingParams.keys.sorted()), id: \.self) { key in
                            HStack(alignment: .top) {
                                Text(key)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text("=")
                                    .foregroundColor(.secondary)
                                Text(editingParams[key] ?? "")
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            
            if !editingParams.isEmpty {
                Divider()
                Text("Full URL Preview:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(buildFullURL())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(3)
            }
        }
        .padding()
    }
    
    private func addParameter() {
        guard !newParamKey.isEmpty else { return }
        editingParams[newParamKey] = newParamValue
        newParamKey = ""
        newParamValue = ""
    }
    
    private func saveChanges() {
        request.queryParameters = editingParams
        isEditing = false
    }
    
    private func buildFullURL() -> String {
        guard var components = URLComponents(string: request.url) else {
            return request.url
        }
        
        if !editingParams.isEmpty {
            components.queryItems = editingParams.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        return components.string ?? request.url
    }
}

#Preview {
    AppPreview()
        .frame(width: 1200)
        .frame(height: 800)
}
