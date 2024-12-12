import SwiftUI

struct RequestEditor: View {
    @Binding var request: APIRequest
    let onSave: (APIRequest) -> Void
    
    @State private var name: String
    @State private var url: String
    @State private var method: APIRequest.HTTPMethod
    @State private var requestBody: String
    @State private var contentType: APIRequest.ContentType
    @State private var headers: [String: String]
    @State private var newHeaderKey = ""
    @State private var newHeaderValue = ""
    
    init(request: Binding<APIRequest>, onSave: @escaping (APIRequest) -> Void) {
        self._request = request
        self.onSave = onSave
        
        _name = State(initialValue: request.wrappedValue.name)
        _url = State(initialValue: request.wrappedValue.url)
        _method = State(initialValue: request.wrappedValue.method)
        _requestBody = State(initialValue: request.wrappedValue.body ?? "")
        _contentType = State(initialValue: request.wrappedValue.contentType)
        _headers = State(initialValue: request.wrappedValue.headers)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 基本���息
            HStack {
                TextField("Request Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Method", selection: $method) {
                    ForEach(APIRequest.HTTPMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .frame(width: 100)
            }
            
            TextField("URL", text: $url)
                .textFieldStyle(.roundedBorder)
            
            // Headers
            GroupBox("Headers") {
                VStack(spacing: 8) {
                    ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                        HStack {
                            TextField("Key", text: .constant(key))
                                .textFieldStyle(.roundedBorder)
                            TextField("Value", text: Binding(
                                get: { headers[key] ?? "" },
                                set: { headers[key] = $0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                            Button(action: { headers.removeValue(forKey: key) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("New Header Key", text: $newHeaderKey)
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $newHeaderValue)
                            .textFieldStyle(.roundedBorder)
                        Button(action: addHeader) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(newHeaderKey.isEmpty)
                    }
                }
            }
            
            // Request Body
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Content Type", selection: $contentType) {
                        ForEach(APIRequest.ContentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextEditor(text: $requestBody)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            
            // Save Button
            Button(action: saveRequest) {
                Text("Save Request")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty || url.isEmpty)
            
            Spacer()
        }
        .padding()
    }
    
    private func addHeader() {
        if !newHeaderKey.isEmpty {
            headers[newHeaderKey] = newHeaderValue
            newHeaderKey = ""
            newHeaderValue = ""
        }
    }
    
    private func saveRequest() {
        var updatedRequest = request
        updatedRequest.name = name
        updatedRequest.url = url
        updatedRequest.method = method
        updatedRequest.headers = headers
        updatedRequest.body = requestBody.isEmpty ? nil : requestBody
        updatedRequest.contentType = contentType
        
        onSave(updatedRequest)
    }
} 