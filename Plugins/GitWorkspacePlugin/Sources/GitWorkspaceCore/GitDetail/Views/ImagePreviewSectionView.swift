import AppKit
import SwiftUI

public struct ImagePreviewSectionView: View {
    private let title: String
    private let image: NSImage?

    public init(title: String, image: NSImage?) {
        self.title = title
        self.image = image
    }

    public var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))

            ImagePreviewView(image: image)
        }
    }
}
