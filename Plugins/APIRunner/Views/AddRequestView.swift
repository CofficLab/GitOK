import SwiftUI

struct AddRequestView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (APIRequest) -> Void

    @State private var name = ""
    @State private var url = ""
    @State private var method = APIRequest.HTTPMethod.get
    @State private var requestBody = ""
    @State private var contentType = APIRequest.ContentType.json
    @State private var headers: [String: String] = [:]

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
                    // Headers 编辑界面
                }

                Section("Body") {
                    TextEditor(text: $requestBody)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Request")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let request = APIRequest(
                            name: name,
                            url: url,
                            method: method,
                            headers: headers,
                            body: requestBody.isEmpty ? nil : requestBody,
                            contentType: contentType
                        )
                        onAdd(request)
                        dismiss()
                    }
                    .disabled(name.isEmpty || url.isEmpty)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }
}
