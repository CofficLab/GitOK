import SwiftUI

struct TableToolbar: View {
    let title: String
    @Binding var rowLimit: Int
    let totalCount: Int
    let onRefresh: () -> Void
    let onExport: () -> Void
    
    private let rowLimits = [100, 500, 1000, -1]
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Text("(\(totalCount) rows)")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
                
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Export as CSV")
                
                Menu {
                    ForEach(rowLimits, id: \.self) { limit in
                        Button(limit == -1 ? "All rows" : "\(limit) rows") {
                            rowLimit = limit
                        }
                    }
                } label: {
                    Label("Limit: \(rowLimit == -1 ? "All" : "\(rowLimit)")", systemImage: "line.3.horizontal.decrease")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    TableToolbar(
        title: "Test Table",
        rowLimit: .constant(100),
        totalCount: 1000,
        onRefresh: {},
        onExport: {}
    )
}
