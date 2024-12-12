import SwiftUI

struct ResponseView: View {
    let response: APIResponse?
    @State private var isExpanded = false
    
    var body: some View {
        if let response = response {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Response")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Status: \(response.statusCode)")
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text("Duration: \(String(format: "%.2f", response.duration))s")
                        .foregroundColor(.secondary)
                }
                
                if !response.headers.isEmpty {
                    DisclosureGroup("Headers (\(response.headers.count))", isExpanded: $isExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(response.headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
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
                
                GroupBox {
                    ScrollView {
                        Text(response.body)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(maxHeight: 300)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var statusColor: Color {
        switch response?.statusCode ?? 0 {
        case 200...299: return .green
        case 300...399: return .blue
        case 400...499: return .orange
        case 500...599: return .red
        default: return .primary
        }
    }
} 