import SwiftUI

struct RequestDetailView: View {
    @Binding var request: APIRequest
    @EnvironmentObject var apiProvider: APIProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var m: MessageProvider
    @State private var showErrorDetails = true
    @State private var editingName: String
    @State private var editingUrl: String
    @State private var editingMethod: APIRequest.HTTPMethod
    @State private var editingBody: String
    @State private var editingContentType: APIRequest.ContentType
    @State private var editingHeaders: [String: String]
    @State private var isEditing = false
    
    init(request: Binding<APIRequest>) {
        self._request = request
        _editingName = State(initialValue: request.wrappedValue.name)
        _editingUrl = State(initialValue: request.wrappedValue.url)
        _editingMethod = State(initialValue: request.wrappedValue.method)
        _editingBody = State(initialValue: request.wrappedValue.body ?? "")
        _editingContentType = State(initialValue: request.wrappedValue.contentType)
        _editingHeaders = State(initialValue: request.wrappedValue.headers)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.name)
                    .font(.headline)
                Spacer()
                
                Button("Edit") {
                    isEditing = true
                }
            }
            
            if isEditing {
                VStack(spacing: 12) {
                    TextField("Name", text: $editingName)
                    TextField("URL", text: $editingUrl)
                    
                    Picker("Method", selection: $editingMethod) {
                        ForEach(APIRequest.HTTPMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    Picker("Content Type", selection: $editingContentType) {
                        ForEach(APIRequest.ContentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    GroupBox("Headers") {
                        ForEach(Array(editingHeaders.keys.sorted()), id: \.self) { key in
                            HStack {
                                TextField("Key", text: .constant(key))
                                TextField("Value", text: Binding(
                                    get: { editingHeaders[key] ?? "" },
                                    set: { editingHeaders[key] = $0 }
                                ))
                            }
                        }
                        Button("Add Header") {
                            editingHeaders["New Header"] = ""
                        }
                    }
                    
                    GroupBox("Body") {
                        TextEditor(text: $editingBody)
                            .frame(height: 100)
                    }
                    
                    HStack {
                        Button("Cancel") {
                            isEditing = false
                        }
                        Button("Save") {
                            var updatedRequest = request
                            updatedRequest.name = editingName
                            updatedRequest.url = editingUrl
                            updatedRequest.method = editingMethod
                            updatedRequest.headers = editingHeaders
                            updatedRequest.body = editingBody.isEmpty ? nil : editingBody
                            updatedRequest.contentType = editingContentType
                            
                            request = updatedRequest
                            isEditing = false
                        }
                        .disabled(editingName.isEmpty || editingUrl.isEmpty)
                    }
                }
                .padding()
            } else {
                HStack {
                    Text(request.method.rawValue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(request.url)
                        .textSelection(.enabled)
                }
                
                if !request.headers.isEmpty {
                    GroupBox("Headers") {
                        ForEach(request.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key)
                                    .bold()
                                Text(": ")
                                Text(value)
                            }
                        }
                    }
                }
                
                if let body = request.body {
                    GroupBox("Body") {
                        Text(body)
                            .textSelection(.enabled)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                if let error = apiProvider.lastError {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Request Failed")
                                    .foregroundColor(.red)
                                    .font(.headline)
                                Spacer()
                                Button(action: { showErrorDetails.toggle() }) {
                                    Image(systemName: showErrorDetails ? "chevron.up" : "chevron.down")
                                }
                            }
                            
                            if showErrorDetails {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Error Type:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(describing: type(of: error)))
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                    
                                    Text("Description:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                    Text(error.localizedDescription)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                    
                                    if let nsError = error as? NSError {
                                        Text("Error Code: \(nsError.code)")
                                            .font(.system(.body, design: .monospaced))
                                            .textSelection(.enabled)
                                            .padding(.top, 4)
                                        
                                        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                                            Text("Underlying Error:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                            Text(underlyingError.localizedDescription)
                                                .font(.system(.body, design: .monospaced))
                                                .textSelection(.enabled)
                                        }
                                        
                                        if !nsError.userInfo.isEmpty {
                                            Text("User Info:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                            ForEach(Array(nsError.userInfo.keys), id: \.self) { key in
                                                if let value = nsError.userInfo[key] {
                                                    HStack(alignment: .top) {
                                                        Text(key)
                                                            .font(.system(.caption, design: .monospaced))
                                                            .foregroundColor(.secondary)
                                                        Text(": ")
                                                        Text(String(describing: value))
                                                            .font(.system(.caption, design: .monospaced))
                                                    }
                                                    .textSelection(.enabled)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(8)
                    }
                }
                
                HStack {
                    Button(action: sendRequest) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Request")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiProvider.isLoading)
                    
                    if apiProvider.isLoading {
                        ProgressView()
                            .padding(.leading)
                    }
                }
            }
        }
    }
    
    private func sendRequest() {
        Task {
            do {
                _ = try await apiProvider.sendRequest(request)
            } catch {
                print("Request failed: \(error)")
                // 错误已经在 APIProvider 中设置，会自动显示在界面上
            }
        }
    }
} 
