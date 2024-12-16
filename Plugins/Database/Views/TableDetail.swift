import SwiftUI
import UniformTypeIdentifiers

struct TableDetail: View {
    @EnvironmentObject var dbProvider: DatabaseProvider
    let tableName: String
    @State private var rowLimit: Int = 100
    @State private var showingExportDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 表格标题和工具栏
            TableToolbar(
                title: tableName,
                rowLimit: $rowLimit,
                totalCount: dbProvider.records.count,
                onRefresh: refreshData,
                onExport: { showingExportDialog = true }
            )
            .background(Color(.windowBackgroundColor))

            // 表格内容
            if dbProvider.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dbProvider.columns.isEmpty {
                EmptyTableView()
            } else {
                TableData(records: dbProvider.records, columns: dbProvider.columns)
                    .frame(maxWidth: .infinity)
            }
        }
        .fileExporter(
            isPresented: $showingExportDialog,
            document: CSVDocument(records: dbProvider.records, columns: dbProvider.columns),
            contentType: .commaSeparatedText,
            defaultFilename: "\(tableName).csv"
        ) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print("Error saving file: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshData() {
        if let tableName = dbProvider.selectedTable {
            dbProvider.queryTable(tableName)
        }
    }
}

struct EmptyTableView: View {
    var body: some View {
        Text("No data")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// CSV文档类型
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    let records: [[String: Any]]
    let columns: [String]
    
    init(records: [[String: Any]], columns: [String]) {
        self.records = records
        self.columns = columns
    }
    
    init(configuration: ReadConfiguration) throws {
        records = []
        columns = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard !columns.isEmpty else { return FileWrapper(regularFileWithContents: Data()) }
        
        // 构建CSV内容
        var csvContent = columns.joined(separator: ",") + "\n"
        
        for record in records {
            let row = columns.map { column -> String in
                formatCSVValue(record[column])
            }
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        let data = csvContent.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
    
    private func formatCSVValue(_ value: Any?) -> String {
        guard let value = value else { return "" }
        if value is NSNull { return "" }
        
        let stringValue = String(describing: value)
        // 如果值包含逗号、引号或换行符，需要用引号包裹并转义内部的引号
        if stringValue.contains(",") || stringValue.contains("\"") || stringValue.contains("\n") {
            return "\"\(stringValue.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return stringValue
    }
}

#Preview {
    AppPreview()
}
