import SwiftUI

// Network 视图
struct NetworkView: View {
    let connectionInfo: APIResponse.ConnectionInfo?
    let redirectChain: [APIResponse.RedirectInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let info = connectionInfo {
                GroupBox("Connection Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Local IP", value: info.localIP)
                        InfoRow(label: "Remote IP", value: info.remoteIP)
                        InfoRow(label: "Remote Port", value: String(info.remotePort))
                    }
                    .padding()
                }
            }

            if !redirectChain.isEmpty {
                GroupBox("Redirect Chain") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(redirectChain, id: \.timestamp) { redirect in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(redirect.statusCode)")
                                    .font(.headline)
                                Text(redirect.sourceURL.absoluteString)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                Text(redirect.destinationURL.absoluteString)
                                    .foregroundColor(.blue)
                                Text(redirect.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if redirect.timestamp != redirectChain.last?.timestamp {
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
