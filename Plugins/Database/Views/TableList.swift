import SwiftUI

struct TableList: View {
    @EnvironmentObject var dbProvider: DatabaseProvider

    @State private var selectedTable: String?
    
    var body: some View {
        List(dbProvider.tables, id: \.self, selection: $selectedTable) { table in
            Text(table)
                .tag(table)
        }
        .onChange(of: selectedTable) { newValue in
            if let tableName = newValue, tableName != dbProvider.selectedTable {
                dbProvider.queryTable(tableName)
            }
        }
    }
}

#Preview {
    TableList()
        .environmentObject(DatabaseProvider())
}
