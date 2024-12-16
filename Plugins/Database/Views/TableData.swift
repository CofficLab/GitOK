import SwiftUI

struct TableData: View {
    let records: [[String: Any]]
    @State private var columnWidths: [String: CGFloat] = [:]
    @State private var hoveredRow: Int? = nil

    private var columns: [String] {
        Array(Set(records.flatMap { $0.keys })).sorted()
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                        TableRow(record: record, columns: columns, isEven: index % 2 == 0, isHovered: hoveredRow == index)
                            .onHover { isHovered in
                                hoveredRow = isHovered ? index : nil
                            }
                    }
                } header: {
                    HStack(spacing: 0) {
                        ForEach(columns, id: \.self) { column in
                            TableColumnHeader(title: column)
                                .frame(width: columnWidths[column] ?? 150)
                        }
                    }
                    .background(Color(.windowBackgroundColor))
                }
            }
        }
        .background(.cyan.opacity(0.2))
    }
}
