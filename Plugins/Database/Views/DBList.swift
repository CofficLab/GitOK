import SwiftUI

struct DBList: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var dbProvider: DatabaseProvider
    @State private var showingAddConfig = false
    @State private var showingDeleteAlert = false
    @State private var configToDelete: DatabaseConfig?

    var body: some View {
        Group {
            if g.project != nil {
                content
            } else {
                Text(LocalizedStringKey("select_project"))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if let project = g.project {
                dbProvider.loadConfigs(from: project)
            }
        }
    }

    var content: some View {
        VStack {
            List(dbProvider.configs) { config in
                DBConfigRow(config: config)
                    .contextMenu {
                        Button(role: .destructive) {
                            configToDelete = config
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            
            // 表格列表
            VStack {
                if dbProvider.isTablesLoading {
                    ProgressView()
                } else if let error = dbProvider.error {
                    DBErrorView(message: error)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    TableList()
                }
            }

            HStack {
                Button(action: { showingAddConfig = true }) {
                    Label("Add Database", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
        }
        .sheet(isPresented: $showingAddConfig) {
            DBAddView()
        }
        .alert("Delete Configuration",
               isPresented: $showingDeleteAlert,
               presenting: configToDelete) { config in
            Button("Delete", role: .destructive) {
                dbProvider.removeConfig(id: config.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { config in
            Text("Are you sure you want to delete '\(config.name)'? This action cannot be undone.")
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
