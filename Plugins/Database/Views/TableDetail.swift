import SwiftUI

struct TableDetail: View {
    @EnvironmentObject var dbProvider: DatabaseProvider
    let tableName: String
    
    var body: some View {
        VStack {
            TableHeader(title: tableName)
            TableContent(records: dbProvider.records)
        }
        .padding()
    }
}

// 表格标题组件
struct TableHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding()
    }
}

// 表格内容组件
struct TableContent: View {
    let records: [[String: Any]]
    
    var body: some View {
        if !records.isEmpty {
            ScrollView(.horizontal) {
                TableGrid(records: records, columns: getColumns())
            }
        } else {
            Text("No data")
                .foregroundColor(.secondary)
        }
    }
    
    private func getColumns() -> [String] {
        Set(records.flatMap { $0.keys }).sorted()
    }
}

// 表格网格组件
struct TableGrid: View {
    let records: [[String: Any]]
    let columns: [String]
    
    var body: some View {
        VStack {
            // Header row
            HStack {
                ForEach(columns, id: \.self) { column in
                    Text(column)
                        .font(.headline)
                        .frame(minWidth: 100)
                        .padding(.horizontal)
                }
            }
            
            // Data rows
            ForEach(records.indices, id: \.self) { index in
                HStack {
                    ForEach(columns, id: \.self) { column in
                        Text(formatValue(records[index][column]))
                            .frame(minWidth: 100)
                            .padding(.horizontal)
                    }
                }
                Divider()
            }
        }
    }
    
    private func formatValue(_ value: Any?) -> String {
        guard let value = value else { return "" }
        return String(describing: value)
    }
}

#Preview {
    TableDetail(tableName: "Test Table")
        .environmentObject(DatabaseProvider())
} 