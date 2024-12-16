import SwiftUI

struct TableDetail: View {
    @EnvironmentObject var dbProvider: DatabaseProvider
    let tableName: String
    
    var body: some View {
        VStack(spacing: 0) {
            // 表格标题和工具栏
            TableToolbar(title: tableName)
            
            // 表格内容
            if dbProvider.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dbProvider.records.isEmpty {
                Text("No data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                DataTable(records: dbProvider.records)
            }
        }
        .background(Color(.controlBackgroundColor))
    }
}

// 表格工具栏
struct TableToolbar: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.down")
                }
                
                Menu {
                    Button("100 rows", action: {})
                    Button("500 rows", action: {})
                    Button("1000 rows", action: {})
                    Button("All rows", action: {})
                } label: {
                    Label("Limit", systemImage: "line.3.horizontal.decrease")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
}

// 数据表格
struct DataTable: View {
    let records: [[String: Any]]
    @State private var columnWidths: [String: CGFloat] = [:]
    @State private var hoveredRow: Int? = nil
    
    private var columns: [String] {
        Array(Set(records.flatMap { $0.keys })).sorted()
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                // 表头
                HStack(spacing: 0) {
                    ForEach(columns, id: \.self) { column in
                        TableColumnHeader(title: column)
                            .frame(width: columnWidths[column] ?? 150)
                    }
                }
                .background(Color(.controlBackgroundColor))
                
                // 数据行
                ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                    TableRow(record: record, columns: columns, isEven: index % 2 == 0, isHovered: hoveredRow == index)
                        .onHover { isHovered in
                            hoveredRow = isHovered ? index : nil
                        }
                }
            }
        }
    }
}

// 表格列头
struct TableColumnHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
            
            Image(systemName: "arrow.up.arrow.down.square.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1, height: nil)
                .foregroundColor(Color(.separatorColor)),
            alignment: .trailing
        )
        .overlay(
            Rectangle()
                .frame(width: nil, height: 1)
                .foregroundColor(Color(.separatorColor)),
            alignment: .bottom
        )
    }
}

// 数据行
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
        .background(
            isHovered ? Color.blue.opacity(0.1) :
                isEven ? Color(.controlBackgroundColor) : Color(.textBackgroundColor)
        )
    }
}

// 单元格
struct TableCell: View {
    let value: Any?
    
    var body: some View {
        Text(formatValue(value))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(getCellColor(value))
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil)
                    .foregroundColor(Color(.separatorColor)),
                alignment: .trailing
            )
            .contentShape(Rectangle())
            .contextMenu {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(formatValue(value), forType: .string)
                }
            }
    }
    
    private func formatValue(_ value: Any?) -> String {
        if let value = value {
            if value is NSNull {
                return "NULL"
            } else {
                return String(describing: value)
            }
        }
        return ""
    }
    
    private func getCellColor(_ value: Any?) -> Color {
        if value is NSNull {
            return .secondary
        } else if value is Int || value is Double {
            return .blue
        } else if let str = value as? String, str.lowercased() == "true" || str.lowercased() == "false" {
            return .green
        }
        return .primary
    }
}

#Preview {
    TableDetail(tableName: "Test Table")
        .environmentObject(DatabaseProvider())
} 