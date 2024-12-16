import SwiftUI

struct DBContent: View {
    @EnvironmentObject var dbProvider: DatabaseProvider

    var body: some View {
        VStack {
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
