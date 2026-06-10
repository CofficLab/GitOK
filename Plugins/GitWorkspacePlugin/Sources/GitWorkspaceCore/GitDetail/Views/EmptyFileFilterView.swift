import SwiftUI

public struct EmptyFileFilterView: View {
    private let isFiltering: Bool

    public init(isFiltering: Bool) {
        self.isFiltering = isFiltering
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 28))
                .foregroundColor(.secondary)

            Text(isFiltering ? GitDetailLocalization.string("No matching files") : GitDetailLocalization.string("No files changed"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
