import AppKit
import SwiftUI

public struct ImagePreviewView: View {
    private let image: NSImage?

    public init(image: NSImage?) {
        self.image = image
    }

    public var body: some View {
        if let image {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            maxWidth: max(image.size.width, geometry.size.width),
                            maxHeight: .infinity
                        )
                        .padding(8)
                }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text(String(localized: "Unable to load image"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
