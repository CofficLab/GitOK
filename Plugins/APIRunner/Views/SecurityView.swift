import SwiftUI

// Security 视图
struct SecurityView: View {
    let tlsInfo: APIResponse.TLSInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let tlsInfo = tlsInfo {
                GroupBox("TLS/SSL Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Protocol", value: tlsInfo.tlsProtocol)
                        InfoRow(label: "Cipher Suite", value: tlsInfo.cipherSuite)
                        InfoRow(label: "Certificate Expiration", value: tlsInfo.certificateExpirationDate.formatted())
                    }
                    .padding()
                }

                GroupBox("Certificate Chain") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tlsInfo.certificateChain, id: \.self) { cert in
                                Text(cert)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding()
                }
            } else {
                Text("No TLS/SSL information available")
                    .foregroundColor(.secondary)
            }
        }
    }
}
