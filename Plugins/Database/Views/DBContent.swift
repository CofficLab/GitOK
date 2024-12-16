import SwiftUI

struct DBContent: View {
    @EnvironmentObject var dbProvider: DatabaseProvider

    var body: some View {
        VStack {
            // 表格列表
            VStack {
                if dbProvider.isLoading {
                    ProgressView()
                } else if let error = dbProvider.error {
                    DBErrorView(message: error)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    TableList()
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(minHeight: 200)

            // 表格内容
            if let selectedTable = dbProvider.selectedTable {
                TableDetail(tableName: selectedTable)
            } else {
                Text("Select a table")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
