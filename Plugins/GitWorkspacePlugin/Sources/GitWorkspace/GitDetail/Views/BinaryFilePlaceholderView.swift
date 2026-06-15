import SwiftUI

public struct BinaryFilePlaceholderView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(GitDetailLocalization.string("Binary File"))
                .font(.headline)
                .foregroundColor(.primary)

            Text(GitDetailLocalization.string("Differences cannot be shown as text for this file"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
