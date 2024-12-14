import MagicKit
import os
import SwiftUI

struct RequestParameters: View, SuperLog {
    let emoji = "🦜"

    @Binding var request: APIRequest
    @State private var newParamKey = ""
    @State private var newParamValue = ""
    @State private var editingParams: [String: String]

    init(request: Binding<APIRequest>) {
        self._request = request
        _editingParams = State(initialValue: request.wrappedValue.queryParameters)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        }
    }

    private func addParameter() {
        guard !newParamKey.isEmpty else { return }
        editingParams[newParamKey] = newParamValue
        newParamKey = ""
        newParamValue = ""
    }

    private func saveChanges() {
        request.queryParameters = editingParams
    }
}

#Preview {
    AppPreview()
        .frame(width: 1200)
        .frame(height: 800)
}
