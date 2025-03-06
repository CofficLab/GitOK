import SwiftUI

struct ResponsePretty: View {
    let content: String

    var formattedBody: String {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return content
        }
        return prettyString
    }

    var body: some View {
        ScrollView {
            Text(formattedBody)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
