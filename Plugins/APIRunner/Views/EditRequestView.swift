import SwiftUI

struct EditRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var request: APIRequest
    
    @State private var name: String
    @State private var url: String
    @State private var method: APIRequest.HTTPMethod
    @State private var requestBody: String
    @State private var contentType: APIRequest.ContentType
    @State private var headers: [String: String]
    
    init(request: Binding<APIRequest>) {
        self._request = request
        _name = State(initialValue: request.wrappedValue.name)
        _url = State(initialValue: request.wrappedValue.url)
        _method = State(initialValue: request.wrappedValue.method)
        _requestBody = State(initialValue: request.wrappedValue.body ?? "")
        _contentType = State(initialValue: request.wrappedValue.contentType)
        _headers = State(initialValue: request.wrappedValue.headers)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("URL", text: $url)
                
                Picker("Method", selection: $method) {
                    ForEach(APIRequest.HTTPMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                
                Picker("Content Type", selection: $contentType) {
                    ForEach(APIRequest.ContentType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                Section("Headers") {
                    ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                        HStack {
                            TextField("Key", text: .constant(key))
                            TextField("Value", text: Binding(
                                get: { headers[key] ?? "" },
                                set: { headers[key] = $0 }
                            ))
                        }
                    }
                    
                    Button("Add Header") {
                        headers["New Header"] = ""
                    }
                }
                
                Section("Body") {
                    TextEditor(text: $requestBody)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Request")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        request.name = name
                        request.url = url
                        request.method = method
                        request.headers = headers
                        request.body = requestBody.isEmpty ? nil : requestBody
                        request.contentType = contentType
                        dismiss()
                    }
                    .disabled(name.isEmpty || url.isEmpty)
                }
            }
        }
    }
} 