import SwiftUI

struct ResponseRawView: View {
    let content: String

    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
