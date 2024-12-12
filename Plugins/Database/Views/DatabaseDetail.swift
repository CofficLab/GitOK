import SwiftUI

struct DatabaseDetail: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @StateObject private var dbProvider = DatabaseProvider()
    
    var body: some View {
        Group {
            if let project = g.project {
                content
            } else {
                Text(LocalizedStringKey("select_project"))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var content: some View {
        HSplitView {
            // 左侧表格列表
            tableList
                .frame(minWidth: 200, maxWidth: 300)
            
            // 右侧数据显示
            if let selectedTable = dbProvider.selectedTable {
                TableDetail(tableName: selectedTable)
            } else {
                noTableSelectedView
            }
        }
    }
    
    var tableList: some View {
        List(dbProvider.tables, id: \.self) { table in
            Text(table)
                .onTapGesture {
                    dbProvider.queryTable(table)
                }
        }
    }
    
    var noTableSelectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "table")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(LocalizedStringKey("select_table"))
                .font(.headline)
                .padding()
            
            Text(LocalizedStringKey("select_table_description"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 
