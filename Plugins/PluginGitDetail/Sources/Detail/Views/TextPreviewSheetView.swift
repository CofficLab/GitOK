import SwiftUI

public struct TextPreviewSheetView: View {
    private let title: String
    private let content: String

    public init(title: String, content: String) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))

            ScrollView([.horizontal, .vertical]) {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(.background)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
