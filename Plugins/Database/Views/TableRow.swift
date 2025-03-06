import SwiftUI

struct TableRow: View {
    let record: [String: Any]
    let columns: [String]
    let columnWidths: [String: CGFloat]
    let isEven: Bool
    let isHovered: Bool
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(columns, id: \.self) { column in
                    TableCell(value: record[column])
                        .frame(width: columnWidths[column] ?? 150)
                }
                // 占位列
                TableCell(value: nil)
                    .frame(width: max(0, geometry.size.width - columns.reduce(0) { $0 + (columnWidths[$1] ?? 150) }))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHovered ? Color.blue.opacity(0.1) :
                    isEven ? Color(.textBackgroundColor) : Color(.controlBackgroundColor)
            )
        }
        .frame(height: 28)
    }
}
