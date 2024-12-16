import SwiftUI

struct TableList: View {
    @EnvironmentObject var provider: DatabaseProvider

    var body: some View {
        List(provider.tables, id: \.self) { table in
            Text(table)
                .onTapGesture {
                    provider.queryTable(table)
                }
        }
    }
}

#Preview {
    TableList()
        .environmentObject(DatabaseProvider())
}
