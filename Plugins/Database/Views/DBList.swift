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
                Text("select_project")
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
        VStack(spacing: 0) {
            // 配置列表
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

            // 数据库和表格列表
            if dbProvider.selectedConfigId != nil {
                VStack(spacing: 8) {
                    if let error = dbProvider.error {
                        DBErrorView(message: error)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        // 数据库选择器
                        HStack {
                            Text("Database:")
                                .foregroundColor(.secondary)
                            if dbProvider.isDatabasesLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Picker("", selection: Binding(
                                    get: { dbProvider.selectedDatabase },
                                    set: { newValue in
                                        if let database = newValue {
                                            dbProvider.selectDatabase(database)
                                        }
                                    }
                                )) {
                                    Text("Select Database").tag(nil as String?)
                                    ForEach(dbProvider.databases, id: \.self) { database in
                                        Text(database).tag(database as String?)
                                    }
                                }
                                .labelsHidden()
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // 表格列表
                    if dbProvider.selectedDatabase != nil {
                        TableList()
                    } else {
                        Text("Select a database")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            HStack() {
                DBBtnAdd(showingAddConfig: $showingAddConfig)
            }
            .frame(height: 25)
            .labelStyle(.iconOnly)
        }
        .sheet(isPresented: $showingAddConfig) {
            DBAddView().frame(maxWidth: .infinity)
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
