import SwiftUI

struct TableDetail: View {
    @EnvironmentObject var dbProvider: DatabaseProvider
    let tableName: String

    var body: some View {
        VStack(spacing: 0) {
            // 表格标题和工具栏
            TableToolbar(title: tableName)
                .background(Color(.windowBackgroundColor))

            // 表格内容
            if dbProvider.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dbProvider.records.isEmpty {
                Text("No data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TableData(records: dbProvider.records)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    AppPreview()
}
