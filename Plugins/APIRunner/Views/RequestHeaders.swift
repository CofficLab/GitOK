import SwiftUI

struct RequestHeaders: View {
    @Binding var request: APIRequest

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(request.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    VStack(alignment: .leading) {
                        Text(key)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
