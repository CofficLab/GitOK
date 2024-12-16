import SwiftUI

struct TableRow: View {
    let record: [String: Any]
    let columns: [String]
    let isEven: Bool
    let isHovered: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns, id: \.self) { column in
                TableCell(value: record[column])
                    .frame(width: 150)
            }
        }
        .frame(height: 28)
        .frame(alignment: .leading)
        .background(
            isHovered ? Color.blue.opacity(0.1) :
                isEven ? Color(.textBackgroundColor) : Color(.controlBackgroundColor)
        )
    }
}
