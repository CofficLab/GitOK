import SwiftUI

public struct FileListSectionHeaderView: View {
    private let title: String
    private let count: Int

    public init(title: String, count: Int) {
        self.title = title
        self.count = count
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
            Spacer()
            Text("\(count)")
                .font(.caption2.monospacedDigit())
                .foregroundColor(.secondary)
        }
        .textCase(nil)
        .padding(.vertical, 2)
    }
}
