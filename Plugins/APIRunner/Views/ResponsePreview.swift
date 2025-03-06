import SwiftUI

struct ResponsePreview: View {
    let content: String

    var body: some View {
        ScrollView {
            if content.lowercased().contains("<!doctype html") || content.lowercased().contains("<html") {
                ResponseWebView(htmlString: content)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            } else if let imageData = Data(base64Encoded: content) {
                #if os(iOS)
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                #else
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                    }
                #endif
            } else {
                Text("Cannot preview content: \(content.prefix(100))")
            }
        }
    }
}
