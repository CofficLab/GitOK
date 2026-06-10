import SwiftUI

public struct FileDetailHeaderView: View {
    private let path: String
    private let systemImage: String

    public init(path: String, systemImage: String) {
        self.path = path
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            Text(path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.background)
    }
}
