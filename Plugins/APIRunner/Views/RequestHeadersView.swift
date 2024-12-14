import SwiftUI

struct RequestHeadersView: View {
    @Binding var request: APIRequest
    
    @State var isHeadersExpanded = false 
    
    var body: some View {
        GroupBox {
            DisclosureGroup("Headers (\(request.headers.count))", isExpanded: $isHeadersExpanded) {
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
}
